

local mt = {}
mt.__index = mt

function mt:update()
	-- body
end

local M = {}

function M:new(parent)
	return setmetatable({parent=parent}, mt)
end

return M