--- @enum Log_Level
Log_Level = {
	ERROR = { name = "ERROR", color = { 1, 0, 0, 1 } }, -- Red
	WARN = { name = "WARN", color = { 1, 1, 0, 1 } }, -- Yellow
	INFO = { name = "INFO", color = { 1, 1, 1, 1 } }, -- White
	DEBUG = { name = "DEBUG", color = { 0, 1, 1, 1 } }, -- Cyan
}

--- @class Logger
--- @field logs table
--- @field visible boolean
--- @field max_logs number
--- @field font love.Font
--- @field line_height number
--- @field scroll number
local Logger = {
	logs = {},
	visible = false,
	max_logs = 5000,
	font = nil,
	line_height = 0, -- Will be set based on font in init
	scroll = 0,
}

--- Recursively builds a string representation of a table.
--- @param t table The table to print.
--- @param indent_str string The string used for one level of indentation.
--- @param current_indent string The accumulated indentation for the current level.
--- @param visited table A table to track visited tables to prevent infinite loops.
--- @return string
function Logger:_pretty_print_table_recursive(t, indent_str, current_indent, visited)
	if visited[t] then
		return "<circular reference>"
	end
	visited[t] = true

	local result_parts = { "{\n" }
	local next_indent = current_indent .. indent_str
	local entries = {}
	local keys_sorted = {}
	for k, _ in pairs(t) do
		table.insert(keys_sorted, k)
	end
	table.sort(keys_sorted, function(a, b)
		return tostring(a) < tostring(b)
	end)

	for _, k in ipairs(keys_sorted) do
		local v = t[k]
		local key_str
		if type(k) == "string" then
			key_str = '["' .. tostring(k) .. '"]'
		else
			key_str = "[" .. tostring(k) .. "]"
		end

		local value_str
		if type(v) == "table" and v.x ~= nil and v.y ~= nil and getmetatable(v) and getmetatable(v).__index.add then
			value_str = string.format("Vec2(%.2f, %.2f)", v.x, v.y)
		elseif type(v) == "table" then
			value_str = self:_pretty_print_table_recursive(v, indent_str, next_indent, visited)
		elseif type(v) == "string" then
			value_str = '"' .. string.gsub(tostring(v), '"', '\\"') .. '"'
		elseif type(v) == "function" then
			value_str = "function: " .. tostring(v)
		elseif type(v) == "userdata" then
			local v_type_str = ""
			if v and type(v.typeOf) == "function" then
				local status, type_name = pcall(function()
					return v:typeOf()
				end)
				if status and type_name then
					v_type_str = " (" .. tostring(type_name) .. ")"
				end
			end
			value_str = "userdata" .. v_type_str .. ": " .. tostring(v)
		else
			value_str = tostring(v)
		end
		table.insert(entries, next_indent .. key_str .. " = " .. value_str)
	end

	if #entries > 0 then
		table.insert(result_parts, table.concat(entries, ",\n"))
		table.insert(result_parts, "\n")
	end
	table.insert(result_parts, current_indent .. "}")

	visited[t] = nil
	return table.concat(result_parts)
end

--- Generates a pretty-printed string representation of a table.
--- @param t table The table to pretty print.
--- @return string
function Logger:_pretty_print_table(t)
	if type(t) ~= "table" then
		return tostring(t)
	end
	return self:_pretty_print_table_recursive(t, "  ", "", {})
end

function Logger:init()
	if not self.font then
		self.font = love.graphics.newFont(12) -- Default font
	end
	self.line_height = self.font:getHeight()

	self:info("Logger initialized")
	self:debug("Debug mode active")
	return self
end

--- Logs a message or a table. If a table, it's pretty-printed.
--- @param message string | table The message string or table.
--- @param level Log_Level The logging level.
function Logger:log(message, level)
	local formatted_message
	-- >>> MODIFICATION START <<<
	-- Special case for Vec2 objects passed directly to the logger
	if
		type(message) == "table"
		and message.x ~= nil
		and message.y ~= nil
		and getmetatable(message)
		and getmetatable(message).__index.add
	then
		formatted_message = string.format("Vec2(%.2f, %.2f)", message.x, message.y)
	-- >>> MODIFICATION END <<<
	elseif type(message) == "table" then
		formatted_message = self:_pretty_print_table(message)
	else
		formatted_message = tostring(message)
	end

	table.insert(self.logs, {
		message = formatted_message,
		timestamp = os.date("%H:%M:%S"),
		level = level,
	})

	if #self.logs > self.max_logs then
		table.remove(self.logs, 1)
		local screen_h = love.graphics.getHeight()
		if screen_h then
			local console_view_h = screen_h / 3
			local total_content_h = self:_calculate_total_content_height()
			local max_scroll_value = math.max(0, total_content_h - console_view_h)
			if total_content_h <= console_view_h then
				max_scroll_value = 0
			end
			self.scroll = math.min(self.scroll, max_scroll_value)
		end
	end
end

function Logger:error(message)
	self:log(message, Log_Level.ERROR)
end
function Logger:warn(message)
	self:log(message, Log_Level.WARN)
end
function Logger:info(message)
	self:log(message, Log_Level.INFO)
end
function Logger:debug(message)
	self:log(message, Log_Level.DEBUG)
end

function Logger:printf(level, fmt, ...)
	local args = { ... }
	local processed_args = {}
	for i = 1, #args do
		if
			type(args[i]) == "table"
			and args[i].x ~= nil
			and args[i].y ~= nil
			and getmetatable(args[i])
			and getmetatable(args[i]).__index.add
		then
			processed_args[i] = string.format("(%.2f, %.2f)", args[i].x, args[i].y)
		elseif type(args[i]) == "table" then
			processed_args[i] = self:_pretty_print_table(args[i])
		else
			processed_args[i] = args[i]
		end
	end
	self:log(string.format(fmt, unpack(processed_args)), level)
end

--- Calculates the total pixel height of all log entries.
--- @return number
function Logger:_calculate_total_content_height()
	if not self.font then
		return 0
	end
	local total_h = 0
	local current_line_height = self.font:getHeight()
	if #self.logs == 0 then
		return 0
	end

	for i = 1, #self.logs do
		local log_item = self.logs[i]
		local full_text_message =
			string.format("[%s][%s] %s", log_item.timestamp, log_item.level.name, log_item.message)

		local num_lines_in_block = 1
		for _ in string.gmatch(full_text_message, "\n") do
			num_lines_in_block = num_lines_in_block + 1
		end
		total_h = total_h + (num_lines_in_block * current_line_height)
	end
	return total_h
end

function Logger:draw()
	if not self.visible or not self.font then
		return
	end

	local screen_w, screen_h = love.graphics.getDimensions()
	local console_view_h = screen_h / 3
	local console_view_y_top = screen_h - console_view_h

	love.graphics.setColor(0, 0, 0, 0.8)
	love.graphics.rectangle("fill", 0, console_view_y_top, screen_w, console_view_h)

	love.graphics.setScissor(0, console_view_y_top, screen_w, console_view_h)

	local old_font = love.graphics.getFont()
	love.graphics.setFont(self.font)
	local current_line_height = self.font:getHeight()

	local current_block_bottom_y = console_view_y_top + console_view_h + self.scroll

	for i = #self.logs, 1, -1 do
		local log_item = self.logs[i]
		local full_text_message =
			string.format("[%s][%s] %s", log_item.timestamp, log_item.level.name, log_item.message)

		local num_lines_in_block = 1
		for _ in string.gmatch(full_text_message, "\n") do
			num_lines_in_block = num_lines_in_block + 1
		end
		local block_actual_height = num_lines_in_block * current_line_height

		local y_for_this_block_print = current_block_bottom_y - block_actual_height

		local block_top_y = y_for_this_block_print
		local block_bottom_y_for_cull = y_for_this_block_print + block_actual_height

		if block_top_y < console_view_y_top + console_view_h and block_bottom_y_for_cull > console_view_y_top then
			love.graphics.setColor(unpack(log_item.level.color))
			love.graphics.print(full_text_message, 10, y_for_this_block_print)
		end

		current_block_bottom_y = y_for_this_block_print

		if current_block_bottom_y < console_view_y_top then
			break
		end
	end

	love.graphics.setScissor()
	love.graphics.setFont(old_font)
	love.graphics.setColor(1, 1, 1, 1)
end

function Logger:toggle()
	self.visible = not self.visible
	--self:debug(string.format("Logger visibility: %s", self.visible and "shown" or "hidden"))
end

function Logger:wheelmoved(_, y_delta)
	if not self.visible or not self.font then
		return
	end

	local current_line_height = self.font:getHeight()
	self.scroll = self.scroll - (y_delta * current_line_height * 3)

	local screen_h = love.graphics.getHeight()
	local console_view_h = screen_h / 3
	local total_content_h = self:_calculate_total_content_height()

	self.scroll = math.max(0, self.scroll)

	local max_scroll_value = 0
	if total_content_h > console_view_h then
		max_scroll_value = total_content_h - console_view_h
	end
	self.scroll = math.min(self.scroll, max_scroll_value)
end

function Logger:keypressed(_, scancode)
	if scancode == "`" and (love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")) then
		self:toggle()
	end
end

return Logger
