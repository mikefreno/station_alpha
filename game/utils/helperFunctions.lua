local function compareTables(a, b)
  if a == b then
    return true
  end
  if type(a) ~= "table" or type(b) ~= "table" then
    return false
  end

  for k, v in pairs(a) do
    if not compareTables(v, b[k]) then
      return false
    end
  end

  for k in pairs(b) do
    if a[k] == nil then
      return false
    end
  end

  return true
end

---@param value any
---@param cases table
---@return unknown
local function switch(value, cases)
  local case = cases[value] or cases.default
  if type(case) == "function" then
    return case()
  end
  return case
end

return {
  compareTables = compareTables,
  switch = switch,
}
