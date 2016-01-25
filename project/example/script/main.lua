local ej = require "ejoy2d"
local fw = require "ejoy2d.framework"
local sprite = require "ejoy2d.sprite"

local ejoy2dx = require "ejoy2dx"
local image = require "ejoy2dx.image"

local level = require "battle.level"
local ani_mgr = require "battle.ani_mgr"
local avatar = require "battle.avatar"
local human = require "battle.human"
local path = require "battle.path"

path:init()
human:init()
level.init()
ani_mgr:init("animations.json", "fx.json")

local lv = level.new("levelkillhouse1.json")

local render = ejoy2dx.render
local sample_render = render:create(0)

local debug_label = sprite.label({width=500, height=300,size=20,color=0xFFFFFFFF, edge=0})
debug_label.text = "#[blue]DON'T PANIC#[stop]"
debug_label:ps(40, 40)
sample_render:show(debug_label, 1)

local mine = ejoy2dx.sprite("sample.lua", "mine")
mine:ps(300, 60, 0.7)
sample_render:show(mine)


local grid = require "ejoy2dx.grid"
local g = grid(999, {"", "雄鹿", "野兔"})
g:show()
g:position(340, 20)
g:add_row({"雄鹿",	"3, 3", "0, 2"})
g:add_row({"野兔",	"2, 0", "2, 2"})


local game = {}
function game.update()
	if not ejoy2dx.game_stat.is_active then
		return
	end
	human:update()
	ani_mgr:update()
end

function game.drawframe()
	if not ejoy2dx.game_stat.is_active then
		return
	end

	-- ej.clear(0xFFFFFFFF)
	ej.clear()

	lv:draw()

	avatar:draw()
	ani_mgr:draw()

	render:draw()
end

function game.touch(what, x, y)
	lv:touch(what, x, y)
	avatar:touch(what, x, y)
	return true --disable gesture
end

function game.message(...)
end

function game.handle_error(type, msg)
	print(type, msg)
end

function game.on_resume()
end

function game.on_pause()
end

function game.gesture()
end

ej.start(game)


