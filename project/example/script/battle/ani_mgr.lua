
local utls = require "ejoy2dx.utls"
local animation = require "battle.animation"
local global = require "global"

local texture_path = global.texture_path

local M = {}

function M:init(ani_cfg, fx_cfg)
	self.ani_def = utls.load_json(ani_cfg)
	self.ani_def = self.ani_def.Animations.RenderObject2D
	self.anis = {}

	self.fx_def = utls.load_json(fx_cfg)
	self.fx_def = self.fx_def.Entities.Entity
	self.fxs = {}
end

local function query_tex(ani_name, callback)
	local tex_type
	if string.match(ani_name, "(_TORSO_)") ~= nil then
		tex_type = "weapon_skin"
	elseif string.match(ani_name, "(_LEGS_)") ~= nil then
		tex_type = "leg_skin"
	elseif string.match(ani_name, "(_DIE%d*)") then
		tex_type = "death_skin"
	end
	return callback(tex_type)
end

function M:play(ani_name, tex_name, tex_callback)
	local cfg = rawget(self.ani_def, ani_name)
	assert(cfg)
	tex_name = tex_name or cfg.texture
	if not tex_name then
		tex_name = query_tex(ani_name, tex_callback)
	end
	tex_name = texture_path(tex_name)
	local ani = animation.new(tex_name, ani_name, cfg)
	table.insert(self.anis, 1, ani)
	return ani
end

function M:play_fx(fx_name)
	print(fx_name)
	local cfg = rawget(self.fx_def, fx_name)
	if not cfg then return end
	local render = cfg.RenderObject2D
	local tex_name = texture_path(render.texture)
	local ani = animation.new(tex_name, fx_name, render)
	table.insert(self.fxs, 1, ani)
	return ani
end

function M:stop(ani)
	local cnt = #self.anis
	local idx = 0
	for i=1, cnt do
		if self.anis[i] ~= ani then
			idx = idx + 1
			self.anis[idx] = self.anis[i]
		end
	end
	self.anis[cnt] = nil
end

function M:update()
	for _, v in ipairs(self.anis) do
		v:update()
	end
	for _, v in ipairs(self.fxs) do
		v:update()
	end
end

function M:draw()
	for _, v in ipairs(self.anis) do
		v:draw()
	end
	for _, v in ipairs(self.fxs) do
		v:draw()
	end
end

return M