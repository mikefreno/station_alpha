local function compareTables(a, b)
	if a == b then
		return true
	end -- same reference
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

return {
	compareTables = compareTables,
}
