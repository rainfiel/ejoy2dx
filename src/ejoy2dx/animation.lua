
local utls = require "ejoy2dx.utls"

local floor = math.floor

local AnimationManager = {}
local AnimationFrameRate = 60

function AnimationManager:init(logic_frame)
	self.animation_frame_rate = AnimationFrameRate
	self.animation_frame_per_frame = self.animation_frame_rate / logic_frame
	self.animations = {}
end

local function set_duration(ani_cfg, t)
	local factor = ani_cfg.duration / t
	ani_cfg.frame_delta = AnimationManager.animation_frame_per_frame * factor
	if ani_cfg.reverse then
		ani_cfg.frame_delta = -ani_cfg.frame_delta
	end
end

function AnimationManager:play(spr, reverse)
	assert(not self.animations[spr])

	spr.usr_data.anim = spr.usr_data.anim or {}
	local config = spr.usr_data.anim
	
	self:reset(spr, config, reverse)

	self.animations[spr] = true
	return config
end

function AnimationManager:replay(spr)
	local config = spr.usr_data.anim
	if config then
		self:reset(spr, config)
	end
	return config
end

function AnimationManager:stop(spr)
	if self.animations[spr] then
		local config = spr.usr_data.anim
		if config then
			config.playing = false
			config.callback = nil
		end
	end
end

function AnimationManager:is_play(spr)
	return self.animations[spr]
end

function AnimationManager:reset(spr, config, reverse)
	config.reverse = reverse
	config.frame = 0
	config.frame_delta = self.animation_frame_per_frame
	config.duration = utls.frame_to_seconds(spr.frame_count / self.animation_frame_per_frame)
	config.set_duration = set_duration

	config.num_loops = -1 --n for n loops, -1 for loop, 0 for gone
	config.playing = true
	config.callback = callback

	if reverse then
		config.frame_delta = -config.frame_delta
		config.frame = spr.frame_count-1
		config.start_frame = spr.frame_count
		spr.frame = config.frame
	else
		spr.frame = 0
		config.start_frame = -1
	end
end

local function update_imp(spr)
	local config = spr.usr_data.anim
	if not config or not config.playing then
		return false
	end

	config.frame = config.frame + config.frame_delta
	local frame = floor(config.frame)
	spr.frame = frame

	if config.num_loops > 0 and
			(math.abs(frame - config.start_frame) // spr.frame_count) >= config.num_loops then
		if config.callback then
			config.callback()
			config.callback = nil
		end
		return false
	end
	return true
end

local removed = {}
local removed_cnt = 0
function AnimationManager:update()
	removed_cnt = 0
	for k, v in pairs(self.animations) do
		if not update_imp(k) then
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
