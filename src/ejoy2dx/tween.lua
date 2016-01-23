

local easing = require "ejoy2dx.easing.c"

--just for readability
local tween_types = {
	Linear=0,

	Quadratic_In=1,
	Quadratic_Out=2,
	Quadratic_InOut=3,

	Cubic_In=4,
	Cubic_Out=5,
	Cubic_InOut=6,

	Quartic_In=7,
	Quartic_Out=8,
	Quartic_InOut=9,

	Quintic_In=10,
	Quintic_Out=11,
	Quintic_InOut=12,

	Sine_In=13,
	Sine_Out=14,
	Sine_InOut=15,

	Circular_In=16,
	Circular_Out=17,
	Circular_InOut=18,

	Expo_In=19,
	Expo_Out=20,
	Expo_InOut=21,

	Elastic_In=22,
	Elastic_Out=23,
	Elastic_InOut=24,

	Bounce_In=25,
	Bounce_Out=26,
	Bounce_InOut=27,

	Back_In=28,
	Back_Out=29,
	Back_InOut=30,
}

local wrap_modes = {
	Once = 0,
	Loop = 1,
	PingPong = 2,
}
-----------------------------------------------------------------------------------

local mt = {}
mt.__index = mt
function mt:make(tween_type, times, wrap_mode, start_val, end_val)
	start_val = start_val or 0
	end_val = end_val or 1
	if tween_type==self.tween_type and
			-- times == self.times and
			wrap_mode == self.wrap_mode and
			-- start_val == self.start_val and
			end_val == self.end_val then
		return
	end

	self.container = self.container or {}
	self.tween_type = tween_type
	self.times = times
	self.wrap_mode = wrap_mode or wrap_modes.Once
	self.start_val = start_val
	self.end_val = end_val or 1
	easing.easing(self.container, tween_type, self.start_val, self.end_val, times)

	self:reset()
end

function mt:reset()
	self.step_index = 0
	self.delta = 1
end

function mt:step()
	self.step_index = self.step_index + self.delta
	local val = self.container[self.step_index]

	if not val then
		if self.wrap_mode == wrap_modes.Once then
			return val, false
		elseif self.wrap_mode == wrap_modes.Loop then
			self.step_index = 0
			return self:step()
		elseif self.wrap_mode == wrap_modes.PingPong then
			self.delta = -self.delta
			return self:step()
		end
	end
	return val, true
end

function mt:get_value(index)
	return self.container[index]
end

function mt:test()
	if self.wrap_mode == wrap_modes.Once then
		while true do
			local val, alive = self:step()
			print(val)
			if not alive then
				print("done")
				break
			end
			os.execute("sleep 0.2")
		end
	end
	if self.wrap_mode == wrap_modes.Loop or self.wrap_mode == wrap_modes.PingPong then
		while true do
			local val, rounding = self:step()
			print(val)
			if not rounding then
				print("round end")
			end
			os.execute("sleep 0.2")
		end
	end

	self.step_index = 0
	self.delta = 1
end


-----------------------------------------------------------------------------------
local M = {}
function M.new()
	return setmetatable({}, mt)
end

M.type = tween_types
M.wrap_mode = wrap_modes

return M


