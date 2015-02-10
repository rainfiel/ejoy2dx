local ej = require "ejoy2d"
local fw = require "ejoy2d.framework"
local sprite = require "ejoy2d.sprite"

local ejoy2dx = require "ejoy2dx"
local image = require "ejoy2dx.image"
local package = require "ejoy2dx.package"
local game_stat = require "ejoy2dx.game_stat"

local level = require "battle.level"
local ani_mgr = require "battle.ani_mgr"
local avatar = require "battle.avatar"
local human = require "battle.human"
local path = require "battle.path"

package:path(fw.WorkDir..[[/asset/?]])

path:init()
human:init()
level.init()
ani_mgr:init("animations.json", "fx.json")
local lv = level.new("levelkillhouse1.json")

local debug_label = sprite.label({width=500, height=300,size=20,color=0xFFFFFFFF, edge=0})
debug_label.text = "#[blue]DON'T PANIC#[stop]"
local label_srt = {x=40, y=40}

local polygon = image:create_polygon({17,17, 200, 17, 200, 70, 17, 70})

local mine = ejoy2dx.sprite("sample.lua", "mine")
local mine_srt = {x=300, y=60, scale=0.7}

local game = {}
function game.update()
	if not game_stat.is_active then
		return
	end
	human:update()
	ani_mgr:update()
end

function game.drawframe()
	if not game_stat.is_active then
		return
	end

	-- ej.clear(0xFFFFFFFF)
	ej.clear()

	lv:draw()

	avatar:draw()
	ani_mgr:draw()

	polygon:draw()
	debug_label:draw(label_srt)
	mine:draw(mine_srt)
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


