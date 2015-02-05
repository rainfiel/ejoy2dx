
local utls = require "ejoy2dx.utls"
local ani_mgr = require "battle.ani_mgr"
local image = require "ejoy2dx.image"

local shadow_path = "data/textures/fx/human_shadow.tga"

local mt = {}
mt.__index = mt

function mt:init(cfg, weapon)
	self.cfg = cfg
	self:set_weapon(weapon)
	self.leg_skin = self.cfg.Skin.legs
	self.death_skin = self.cfg.Skin.death
	self.x, self.y, self.rot = 0, 0, 0
	self.shadow = image:load_image(shadow_path, "shadow")
	self:set_animation("ANIM_TORSO_IDLE")
end

--pistol, rifle, shotgun, weaponless
function mt:set_weapon(weapon)
	self.weapon_skin = rawget(self.cfg.Skin, weapon)
end

local function get_leg_ani(weapon_ani)
	if weapon_ani == "ANIM_LEGS_WALK_BACKWARDS" then
		return "ANIM_LEGS_WALK_BACKWARDS"
	elseif string.match(weapon_ani, "ANIM_TORSO_WALK") ~= nil then
		return "ANIM_LEGS_WALK"
	else
		return "ANIM_LEGS_IDLE"
	end
end

function mt:set_animation(ani_id)
	if self.current_ani_id == ani_id then
		return
	end
	--swap ani
	if self.ani then
		ani_mgr:stop(self.ani)
		self.ani = nil
		if self.leg_ani then
			ani_mgr:stop(self.leg_ani)
			self.leg_ani = nil
		end
	end

	self.current_ani_id = ani_id
	local last_tex_type
	self.ani = ani_mgr:play(ani_id, nil, function(tex_type)
		last_tex_type = tex_type
		return rawget(self, tex_type)
	end)
	if last_tex_type == "weapon_skin" then
		local leg = get_leg_ani(ani_id)
		self.leg_ani = ani_mgr:play(leg, self.leg_skin)
	end
	self:ps(self.x, self.y)
	self:sr(self.rot)
end

function mt:ps(x, y)
	self.x, self.y = x, y
	self.ani:ps(x, y)
	if self.leg_ani then
		self.leg_ani:ps(x, y)
	end
	self.shadow:ps(x, y)
end

function mt:sr(rot)
	self.rot = rot
	self.ani:sr(rot)
	if self.leg_ani then
		self.leg_ani:sr(rot)
	end
end

function mt:bind_path(path)
	self.path = path
end

function mt:check_touch(x, y)
	if self.ani:test(x, y) then
		return true
	end
	if self.leg_ani and self.leg_ani:test(x, y) then
		return true
	end
	return false
end

function mt:add_path_point( ... )
	self.path:add_new_point(...)
end

function mt:stop_path_point(...)
	self.path:stop_add_point(...)
end

function mt:draw(srt)
	self.shadow:draw(srt)
	self.path.view:draw(srt)
end

local M = {}

function M:init()
	self.avatars = {}
	self.selected = nil
end

function M:new(cfg, weapon)
	local man = setmetatable({}, mt)
	man:init(cfg, weapon)
	self.avatars = self.avatars or {}
	table.insert(self.avatars, man)
	return man
end

function M:draw(srt)
	if not self.avatars then return end

	for _, v in ipairs(self.avatars) do
		v:draw(srt)
	end
end

function M:touch(what, x, y)
	if what == "BEGIN" then
		self.selected = nil
		for _, v in ipairs(self.avatars) do
			if v:check_touch(x, y) then
				self.selected = v
				break
			end
		end
	elseif what == "END" then
		if self.selected then
			self.selected:stop_path_point(x, y)
		end
		self.selected = nil
	end
	if self.selected then
		self.selected:add_path_point(x, y)
	end
	-- print(self.selected, what, x, y)
end

return M
