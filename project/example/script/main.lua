local ej = require "ejoy2d"
local fw = require "ejoy2d.framework"
local pack = require "ejoy2d.simplepackage"
local sprite = require "ejoy2d.sprite"

local utls = require "ejoy2dx.utls"
local image = require "ejoy2dx.image"

local global = require "global"
local level = require "battle.level"
local ani_mgr = require "battle.ani_mgr"
local animation = require "battle.animation"
local avatar = require "battle.avatar"
local human = require "battle.human"
local path = require "battle.path"
local collide = require "battle.collide"

path:init()
human:init()
level.init()
ani_mgr:init("animations.json", "fx.json")

pack.load {
	pattern = fw.WorkDir..[[asset/?]],
}

local lv = level.new("levelkillhouse1.json")

local game = {}
local debug_label = sprite.label({width=500, height=300,size=20,color=0xFFFFFFFF, edge=1})

function game.update()
	human:update()
	ani_mgr:update()
end

function game.drawframe()
	-- ej.clear(0xFFFFFFFF)
	ej.clear()

	lv:draw()

	avatar:draw()
	ani_mgr:draw()
	
	debug_label:draw({x=800,y=40})
end

function game.touch(what, x, y)
	if global.current_level then
		global.current_level:touch(what, x, y)
	end
	avatar:touch(what, x, y)
end

function game.message(...)
end

function game.handle_error(...)
end

function game.on_resume()
end

function game.on_pause()
end

ej.start(game)


