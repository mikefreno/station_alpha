local enums = require("game.utils.enums")
local Logger = require("logger")

local ComponentType = enums.ComponentType
local TaskType = enums.TaskType

--- @class TaskAdapter
--- High-performance adapter for converting between legacy Task objects and ECS task components
--- Enables seamless migration during the transition period while preserving data integrity
local TaskAdapter = {}

-- Task type mapping from legacy TaskType to ECS ComponentType
local TASK_TYPE_MAPPING = {
  [TaskType.MOVETO] = ComponentType.MOVEMENT_TASK,
  [TaskType.MINE] = ComponentType.MINING_TASK,
  [TaskType.CONSTRUCT] = ComponentType.CONSTRUCTION_TASK,
  [TaskType.CLEAN] = ComponentType.CLEANING_TASK,
}

-- Reverse mapping for ECS ComponentType to legacy TaskType
local COMPONENT_TYPE_MAPPING = {}
for taskType, componentType in pairs(TASK_TYPE_MAPPING) do
  COMPONENT_TYPE_MAPPING[componentType] = taskType
end

--- Check if a legacy task can be converted to an ECS component
--- @param legacyTask Task The legacy task to validate
--- @return boolean canConvert Whether the task can be converted
--- @return string? error Error message if conversion is not possible
function TaskAdapter:canConvert(legacyTask)
  if not legacyTask then
    return false, "Legacy task is nil"
  end

  if not legacyTask.type then
    return false, "Legacy task missing type field"
  end

  if not TASK_TYPE_MAPPING[legacyTask.type] then
    return false, "Unsupported task type: " .. tostring(legacyTask.type)
  end

  if not legacyTask.target then
    return false, "Legacy task missing target field"
  end

  -- Additional validation for specific task types
  if legacyTask.type == TaskType.MOVETO then
    if type(legacyTask.target) ~= "table" or not legacyTask.target.x or not legacyTask.target.y then
      return false, "MOVETO task requires valid Vec2 target"
    end
  end

  return true, nil
end

--- Convert a legacy Task object to an ECS task component
--- @param legacyTask Task The legacy task to convert
--- @param entityId integer The entity that will own this task
--- @return table? component The ECS task component, or nil if conversion failed
--- @return integer? componentType The ComponentType of the created component
--- @return string? error Error message if conversion failed
function TaskAdapter:convertToECS(legacyTask, entityId)
  local canConvert, error = self:canConvert(legacyTask)
  if not canConvert then
    Logger:error("TaskAdapter: Cannot convert legacy task - " .. (error or "unknown error"))
    return nil, nil, error
  end

  local componentType = TASK_TYPE_MAPPING[legacyTask.type]
  if not componentType then
    local errorMsg = "No ECS component mapping for task type: " .. tostring(legacyTask.type)
    Logger:error("TaskAdapter: " .. errorMsg)
    return nil, nil, errorMsg
  end

  -- Get component from pool
  local TaskComponentPool = require("game.systems.TaskComponentPool")
  local component = TaskComponentPool:acquire(componentType)
  if not component then
    local errorMsg = "Failed to acquire component from pool for type: " .. tostring(componentType)
    Logger:error("TaskAdapter: " .. errorMsg)
    return nil, nil, errorMsg
  end

  -- Initialize component with legacy task data
  local success = self:copyDataToComponent(legacyTask, component, entityId)
  if not success then
    -- Release component back to pool on failure
    TaskComponentPool:release(component, componentType)
    local errorMsg = "Failed to copy legacy task data to component"
    Logger:error("TaskAdapter: " .. errorMsg)
    return nil, nil, errorMsg
  end

  Logger:debug("TaskAdapter: Successfully converted legacy task type " .. tostring(legacyTask.type) .. " to ECS component")
  return component, componentType, nil
end

--- Convert an ECS task component back to a legacy Task object
--- @param component table The ECS task component to convert
--- @param componentType integer The ComponentType of the component
--- @param entityId integer The entity that owns this component
--- @return Task? legacyTask The legacy Task object, or nil if conversion failed
--- @return string? error Error message if conversion failed
function TaskAdapter:convertToLegacy(component, componentType, entityId)
  if not component then
    return nil, "Component is nil"
  end

  local taskType = COMPONENT_TYPE_MAPPING[componentType]
  if not taskType then
    local errorMsg = "No legacy task type mapping for component type: " .. tostring(componentType)
    Logger:error("TaskAdapter: " .. errorMsg)
    return nil, errorMsg
  end

  if not component.getTarget then
    return nil, "Component missing getTarget method"
  end

  local target = component:getTarget()
  if not target then
    return nil, "Component has no target"
  end

  -- Create legacy task
  local Task = require("game.components.Task")
  local legacyTask = Task.new(taskType, target)

  -- Copy component data to legacy task
  local success = self:copyDataToLegacyTask(component, legacyTask, entityId)
  if not success then
    local errorMsg = "Failed to copy component data to legacy task"
    Logger:error("TaskAdapter: " .. errorMsg)
    return nil, errorMsg
  end

  Logger:debug("TaskAdapter: Successfully converted ECS component to legacy task type " .. tostring(taskType))
  return legacyTask, nil
end

--- Copy data from legacy task to ECS component
--- @param legacyTask Task The source legacy task
--- @param component table The target ECS component
--- @param entityId integer The entity ID
--- @return boolean success Whether the copy operation succeeded
function TaskAdapter:copyDataToComponent(legacyTask, component, entityId)
  local success, error = pcall(function()
    -- Set basic component data
    if component.setTarget then
      component:setTarget(legacyTask.target)
    end

    if component.setEntityId then
      component:setEntityId(entityId)
    end

    -- Set timer if available
    if component.setTimer and legacyTask.timer then
      component:setTimer(legacyTask.timer)
    end

    -- Set completion state
    if legacyTask.isComplete and component.markComplete then
      component:markComplete()
    end

    -- Set performer if available (some components might not have this)
    if component.setPerformer and legacyTask.performer then
      component:setPerformer(legacyTask.performer)
    end

    -- Task-specific data copying
    self:copyTaskSpecificData(legacyTask, component)
  end)

  if not success then
    Logger:error("TaskAdapter: Error copying data to component - " .. tostring(error))
    return false
  end

  return true
end

--- Copy data from ECS component to legacy task
--- @param component table The source ECS component
--- @param legacyTask Task The target legacy task
--- @param entityId integer The entity ID
--- @return boolean success Whether the copy operation succeeded
function TaskAdapter:copyDataToLegacyTask(component, legacyTask, entityId)
  local success, error = pcall(function()
    -- Copy basic fields
    legacyTask.performer = entityId

    -- Copy timer if available
    if component.getTimer then
      legacyTask.timer = component:getTimer() or 0
    else
      legacyTask.timer = 0
    end

    -- Copy completion state
    if component.isComplete then
      legacyTask.isComplete = component:isComplete()
    else
      legacyTask.isComplete = false
    end

    -- Task-specific data copying
    self:copyTaskSpecificDataToLegacy(component, legacyTask)
  end)

  if not success then
    Logger:error("TaskAdapter: Error copying data to legacy task - " .. tostring(error))
    return false
  end

  return true
end

--- Copy task-specific data from legacy to component (can be extended per task type)
--- @param legacyTask Task The source legacy task
--- @param component table The target ECS component
function TaskAdapter:copyTaskSpecificData(legacyTask, component)
  -- Default implementation - can be extended for specific task types
  -- For example, mining tasks might have additional properties to copy
  
  -- This is a hook for future expansion when specific task types
  -- have unique properties that need to be preserved during conversion
end

--- Copy task-specific data from component to legacy (can be extended per task type)
--- @param component table The source ECS component
--- @param legacyTask Task The target legacy task
function TaskAdapter:copyTaskSpecificDataToLegacy(component, legacyTask)
  -- Default implementation - can be extended for specific task types
  -- This is a hook for future expansion when specific task types
  -- have unique properties that need to be preserved during conversion
end

--- Get the legacy TaskType from an ECS ComponentType
--- @param componentType integer The ComponentType to convert
--- @return integer? taskType The corresponding TaskType, or nil if not found
function TaskAdapter:getTaskTypeFromComponent(componentType)
  return COMPONENT_TYPE_MAPPING[componentType]
end

--- Get the ECS ComponentType from a legacy TaskType
--- @param taskType integer The TaskType to convert
--- @return integer? componentType The corresponding ComponentType, or nil if not found
function TaskAdapter:getComponentTypeFromTask(taskType)
  return TASK_TYPE_MAPPING[taskType]
end

--- Get statistics about supported conversions
--- @return table stats Statistics about task type mappings
function TaskAdapter:getConversionStats()
  local supportedTaskTypes = 0
  local supportedComponentTypes = 0

  for _, _ in pairs(TASK_TYPE_MAPPING) do
    supportedTaskTypes = supportedTaskTypes + 1
  end

  for _, _ in pairs(COMPONENT_TYPE_MAPPING) do
    supportedComponentTypes = supportedComponentTypes + 1
  end

  return {
    supportedTaskTypes = supportedTaskTypes,
    supportedComponentTypes = supportedComponentTypes,
    taskTypeMapping = TASK_TYPE_MAPPING,
    componentTypeMapping = COMPONENT_TYPE_MAPPING,
  }
end

--- Check if a specific task type is supported for conversion
--- @param taskType integer The TaskType to check
--- @return boolean supported Whether the task type is supported
function TaskAdapter:isTaskTypeSupported(taskType)
  return TASK_TYPE_MAPPING[taskType] ~= nil
end

--- Check if a specific component type is supported for conversion
--- @param componentType integer The ComponentType to check
--- @return boolean supported Whether the component type is supported
function TaskAdapter:isComponentTypeSupported(componentType)
  return COMPONENT_TYPE_MAPPING[componentType] ~= nil
end

--- Check if an object is already a task component (has ECS component structure)
--- @param obj any The object to check
--- @return boolean isTaskComponent Whether the object is already a task component
function TaskAdapter:isTaskComponent(obj)
  if not obj or type(obj) ~= "table" then
    return false
  end
  
  -- Check for common task component methods/fields
  local hasComponentMethods = (type(obj.setTarget) == "function" or type(obj.getTarget) == "function") and
                             (type(obj.setEntityId) == "function" or type(obj.getEntityId) == "function")
  
  -- Check if it doesn't have legacy task structure
  local isNotLegacyTask = not (obj.type and obj.target and obj.timer ~= nil)
  
  return hasComponentMethods and isNotLegacyTask
end

--- Get the ComponentType for a task component
--- @param taskComponent table The task component to analyze
--- @return integer|nil componentType The ComponentType, or nil if not determined
function TaskAdapter:getTaskComponentType(taskComponent)
  if not taskComponent or type(taskComponent) ~= "table" then
    return nil
  end
  
  -- If it's already a legacy task, get type from task type mapping
  if taskComponent.type then
    return TASK_TYPE_MAPPING[taskComponent.type]
  end
  
  -- For ECS components, check what type of component it is by testing methods
  if type(taskComponent.getTarget) == "function" then
    local target = taskComponent:getTarget()
    if target then
      -- Check based on component behavior/methods
      if type(taskComponent.getRequiredDistance) == "function" then
        return ComponentType.MOVEMENT_TASK
      elseif type(taskComponent.getMaterial) == "function" then
        return ComponentType.MINING_TASK
      elseif type(taskComponent.getBuildingType) == "function" then
        return ComponentType.CONSTRUCTION_TASK
      elseif type(taskComponent.getCleaningType) == "function" then
        return ComponentType.CLEANING_TASK
      end
    end
  end
  
  return nil
end

return TaskAdapter