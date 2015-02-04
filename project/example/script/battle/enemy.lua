
local bt = require "battle.bt"

local mt = {}
mt.__index = function( ... )
	return bt.getter(mt, ...)
end

function mt:do_look_around()
	if self.path:look_around() then
		return "Running"
	else
		return false
	end
end

function mt:sleep()
	if self.path:sleep() then
		return "Running"
	else
		return false
	end
end

function mt:need_patrol()
	return false
end

function mt:do_patrol()
	print(".............")
	return false
end


local function create(human)
	local self = setmetatable({parent=human}, mt)
	return self
end

return create