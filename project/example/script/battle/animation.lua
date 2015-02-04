
local utls = require "ejoy2dx.utls"
local image = require "ejoy2dx.image"
local blend = require "ejoy2dx.blend"
local math = require "math"

local mt = {}
mt.__index = mt

function mt:init(path, name, render_cfg)
	self.render_cfg = render_cfg
	local cfg = render_cfg.TextureAnimation
	self.frame_width, self.frame_height = tonumber(cfg.frameWidth), tonumber(cfg.frameHeight)
	self.start_frame, self.end_frame = tonumber(cfg.startFrame), tonumber(cfg.endFrame)
	self.time_ms = cfg.animationTimeMS
	self.time_ms = self.time_ms and tonumber(self.time_ms) / 1000 or utls.frame_rate
	self.loops = tonumber(cfg.numLoops)
	self.random_start = cfg.randomizeStartTime == "true"

	self.frame_cnt = math.abs(self.end_frame - self.start_frame) + 1
	self.frame_delta = self.start_frame >= self.end_frame and -1 or 1
	self.time_per_frame = self.time_ms / self.frame_cnt
	self.timer = self.time_per_frame

	-- print("....:", path, name)

	self.img = image:load_image(path, name, nil, function(cfg, tx, ty, tw, th)
		self.width, self.height = tw, th
		self.row = math.floor(self.height / self.frame_height)
		self.col = math.floor(self.width / self.frame_width)

		-- print(self.frame_cnt, self.row, self.col, self.width, self.height, self.frame_width, self.frame_height, self.start_frame, self.end_frame)
		--HACK
		if self.start_frame > self.end_frame then
			self.start_frame, self.end_frame = self.end_frame, self.start_frame
		end

		components = {}
		for i = 1, self.row do
			for j = 1, self.col do
				--zero base, top-left
				local idx = (i-1) * self.col + j - 1
				if idx >= self.start_frame and idx <= self.end_frame then
					local pid = image.add_picture(cfg, self.frame_width * (j-1), self.frame_height * (i-1),
									self.frame_width, self.frame_height)
					table.insert(components, {id=pid})
					tmp = pid
				end
			end
		end
		image.add_component(cfg, components)

		anis = {action="default"}
		for i=1, self.frame_cnt do
			--zero base
			local ani = {{index=i-1}}
			table.insert(anis, ani)
		end
		image.add_animation(cfg, anis)
	end)
	self.img.action = "default"
	-- self.img.frame = self.start_frame
end

function mt:ps(x, y)
	self.img:ps(x, y)
end

function mt:sr(rot)
	self.img:sr(rot)
end

function mt:test(...)
	return self.img:test(...)
end

function mt:update()
	if self.timer <= 0 then
		return
	end
	self.timer = self.timer - utls.frame_rate
	if self.timer <= 0 then
		local frame = self.img.frame + self.frame_delta
		self.img.frame = frame
		if frame >= self.img.frame_count - 1 and self.loops == 0 then
			self.timer = -1
		else
			self.timer = self.time_per_frame
		end
	end
end
 
function mt:draw(srt)
	if blend.begin_blend(self.render_cfg.blendMode) then
		self.img:draw(srt)
		blend.end_blend()
	end
end

local M = {}

function M.new(path, name, cfg)
	-- path = utls.get_path(path)
	local ani = setmetatable({}, mt)
	ani:init(path, name, cfg)
	return ani
end

return M