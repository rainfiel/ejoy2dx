

local floor = math.floor

local AnimationManager = {}
local AnimationFrameRate = 60



local mt = {}
mt.__index = mt

function mt:update(spr)
	if self.num_loops == 0 then
		return false
	end
	self.frame = self.frame + AnimationManager.animation_frame_per_frame
	local frame = floor(self.frame)
	spr.frame = frame

	if self.num_loops > 0 and (frame // self.frame_count) >= self.num_loops then
		return false
	end
	return true
end

function AnimationManager:init(logic_frame)
	self.animation_frame_rate = AnimationFrameRate
	self.animation_frame_per_frame = self.animation_frame_rate / logic_frame
	self.animations = {}
end

function AnimationManager:play(spr, config)
	assert(not self.animations[spr])

	config = config or {}
	config.start_frame = config.start_frame or 0
	config.num_loops = config.num_loops or -1  --n for n loops, -1 for loop, 0 for gone
	config.frame = config.start_frame
	config.frame_count = spr.frame_count

	spr.frame = config.frame
	local ani = setmetatable(config, mt)
	self.animations[spr] = ani
end

function AnimationManager:stop(spr)
	local ani = self.animations[spr]
	if not ani then return end
	ani.num_loops = 0
end

local removed = {}
local removed_cnt = 0
function AnimationManager:update()
	removed_cnt = 0
	for k, v in pairs(self.animations) do
		if not v:update(k) then
			removed_cnt = removed_cnt + 1
			removed[removed_cnt] = k
		end
	end
	for i=1, removed_cnt do
		self.animations[removed[i]] = nil
		removed[i] = nil
	end
end

return AnimationManager
