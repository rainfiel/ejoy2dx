
local bt = require "battle.bt"

local mt = {}
mt.__index = function( ... )
	return bt.getter(mt, ...)
end

function mt:need_move()
	return self.path:is_pathing()
end

function mt:do_move()
	self.path:update()
	self.avatar:set_animation("ANIM_TORSO_WALK")
	return true
end

function mt:can_idle()
	return true
end

function mt:do_idle()
	self.avatar:set_animation("ANIM_TORSO_IDLE")
	return true
end

function mt:need_face_forward()
	return true
end

function mt:face_forward()
	self.path:face_forward()
	return true
end

local function create(human)
	local self = setmetatable({parent=human}, mt)
	return self
end

return create