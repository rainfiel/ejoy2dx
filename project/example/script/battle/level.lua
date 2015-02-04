
local utls = require "ejoy2dx.utls"
local image = require "ejoy2dx.image"
local blend = require "ejoy2dx.blend"

local ani_mgr = require "battle.ani_mgr"
local human = require "battle.human"
local collide = require "battle.collide"
local global = require "global"

local entity_def = nil
local texture_path = global.texture_path

local mt = {}
mt.__index = mt

local function entity_pos(origin)
	local nums = {}
	for match in string.gmatch(origin, "([^ ]+)") do
		table.insert(nums, tonumber(match))
	end
	return nums[1], nums[2]
end

function mt.collidable(def)
	return def.type ~= "DeployZone" and def.type ~= "RescueZone"
end

function mt:init(cfg)
	self.pix_per_meter = tonumber(cfg.Size.pixelsPerMeter)

	local bg_res = cfg.Background.RenderObject2D.texture
	bg_res = texture_path(bg_res)

	collide_res = string.gsub(bg_res, "(.png)", "_collide.png")
	local has_collide = collide.has_collide_file(collide_res)

	self.wall, self.width, self.height = image:load_image(bg_res, "wall", not has_collide)
	floor_res = string.gsub(bg_res, "(.png)", "_floor.png")
	self.floor = image:load_image(floor_res, "floor")

	self.srt = {x=cfg.Size.width_pixels / 2, y=cfg.Size.height_pixels / 2}

	local entities = cfg.Entities.Entity
	self.entities = {}
	for k, v in ipairs(entities) do
		local x, y = entity_pos(v.origin)
		local def = rawget(entity_def, v.name)
		if def then
			local tex = def.RenderObject2D.texture
			tex = texture_path(tex)
			local collidable = self.collidable(def)
			local ent = image:load_image(tex, v.name, collidable and not has_collide)
			ent:ps(x, cfg.Size.height_pixels-y)
			ent:sr(-v.rotation)
			-- print(x, cfg.Size.height_pixels-y, "   ", matrix(ent.matrix):export())
			ent.message = true
			ent.usr_data.name = v.name
			ent.usr_data.collidable = collidable
			ent.usr_data.blend_mode = def.RenderObject2D.blendMode
			table.insert(self.entities, ent)
		else
			local fx = ani_mgr:play_fx(v.name)
			if fx then
				fx:ps(x, cfg.Size.height_pixels - y)
				fx:sr(-v.rotation)
			else
				local man = human:new(v.name)
				if man then
					man:ps(x, cfg.Size.height_pixels - y)
					man:sr(-v.rotation)
				else
					-- print("no defined entity:", v.name)
				end
			end
		end
	end
	
	self.collide_data = collide.get_collide_data( collide_res, self )
end

function mt:draw()
	self.floor:draw(self.srt)
	for k, v in ipairs(self.entities) do
		if blend.begin_blend(v.usr_data.blend_mode) then
			v:draw()
			blend.end_blend()
		end
	end
	self.wall:draw(self.srt)
end

function mt:screen_to_scene(x, y)
	return x + (self.width / 2 - self.srt.x), y + (self.height / 2 - self.srt.y)
end

function mt:find_touched(x, y)
	local touched, hit_x, hit_y
	for k, v in ipairs(self.entities) do
		if v.usr_data.collidable then
			touched, hit_x, hit_y = v:test(x, y)
			if touched then
				return touched, hit_x, hit_y
			end
		end
	end
end

function mt:touch(what, x, y)
	local touched, hit_x, hit_y = self:find_touched(x, y)
	if touched then
		-- print(touched, touched.usr_data.name, x, y, hit_x, hit_y)
	end
end

local M = {}

function M.init()
	entity_def = utls.load_json("entities_various.json")
	entity_def = entity_def.Entities.Entity
end

function M.new(cfg_path)
	local cfg = utls.load_json(cfg_path)
	local lv = setmetatable({}, mt)
	global.current_level = lv

	lv:init(cfg.Level)
	return lv
end

return M