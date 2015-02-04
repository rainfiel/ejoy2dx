
local utls = require "ejoy2dx.utls"
local avatar = require "battle.avatar"
local path = require "battle.path"
local fov = require "battle.fov"
local bt = require "battle.bt"

local mt = {}
mt.__index = mt

function mt:init(cfg)
	self.cfg = cfg
	self.avatar = avatar:new(self.cfg, "rifle")
	--base move speed defined in gameplay_setting.xml
	self.path = path:new(self.avatar, 1.53)
	self.avatar:bind_path(self.path)
	self.fov = fov:new(self)

	self.btree = nil
	if self.cfg.is_enemy then
		self.btree = bt:new_bt("btree/enemy.json", "enemy", self)
	else
		self.btree = bt:new_bt("btree/swat.json", "swat", self)
	end
end

function mt:ps(x, y)
	self.path:ps(x, y)
end

function mt:sr(rot)
	self.path:sr(rot)
end

function mt:update()
	self.fov:update()
	self.btree:run()
end

local M = {}

function M:init()
	self.friendly = utls.load_json("humans_friendly.json")
	self.friendly = self.friendly.Entities.Entity
	self.enemy = utls.load_json("humans_enemy.json")
	self.enemy = self.enemy.Entities.Entity
	self.humans = {}
end

function M:new(human_id)
	local cfg = rawget(self.friendly, human_id)
	if not cfg then
		cfg = rawget(self.enemy, human_id)
		if cfg then
			cfg.is_enemy = true
		end
	end
	if not cfg then
		return
	end
	if cfg.type == "Sniper" then
		return
	end
	local man = setmetatable({}, mt)
	man:init(cfg)
	table.insert(self.humans, man)
	return man
end

function M:update()
	for _, v in ipairs(self.humans) do
		v:update()
	end
end

return M