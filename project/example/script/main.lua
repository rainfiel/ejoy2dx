local ej = require "ejoy2d"
local fw = require "ejoy2d.framework"
local pack = require "ejoy2d.simplepackage"
local sprite = require "ejoy2d.sprite"
local image = require "ejoy2dx.image"

local level = require "battle.level"
local ani_mgr = require "battle.ani_mgr"
local avatar = require "battle.avatar"
local human = require "battle.human"
local path = require "battle.path"

pack.load {
	pattern = fw.WorkDir..[[asset/?]],
}

path:init()
human:init()
level.init()
ani_mgr:init("animations.json", "fx.json")
local lv = level.new("levelkillhouse1.json")

local debug_label = sprite.label({width=500, height=300,size=20,color=0xFFFFFFFF, edge=0})
debug_label.text = "#[blue]DON'T PANIC#[stop]"

local polygon = image:create_polygon({17,17, 200, 17, 200, 70, 17, 70})

local game = {}
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

	polygon:draw()
	debug_label:draw({x=40,y=40})
end

function game.touch(what, x, y)
	lv:touch(what, x, y)
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


