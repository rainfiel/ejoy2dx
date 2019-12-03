local ej = require "ejoy2d"
local ejoy2dx = require "ejoy2dx"
local fw = require "ejoy2d.framework"
local package = require "ejoy2dx.package"
local image = require "ejoy2dx.image"
local message = require "ejoy2dx.message"

if OS == "WINDOWS" then
	local keymap = require "ejoy2dx.keymap"
	local windows_hotkey = require "ejoy2dx.windows_hotkey"
	windows_hotkey:init()
	windows_hotkey.handlers.up[keymap.VK_A] = function(char, is_repeat)
		print("KEY A up", is_repeat)
	end
end

package:path(fw.WorkDir..[[/asset/?]])

local logo = image:load_image("logo.png")

local game = {}
local screencoord = { x = 496, y = 316, scale = 1 }

function game.update()
end

function game.drawframe()
	logo:draw(screencoord)
end

function game.touch(what, x, y)
end

function game.message(...)
	message.on_message(...)
end

function game.handle_error(type, msg)
	if error_render then return end
	ejoy2dx.game_stat:pause()
	
	local sprite = require("ejoy2d.sprite")
	render:clear()
	error_render = render:create(9999, "error")
	local width = render.design_width-20
	local loading_text = sprite.label({width=width, height=24,size=32,color=0xFFaaaaaa, edge=1, align='l'})
	loading_text:ps(2, 20)
	error_render:show(loading_text)

	loading_text.text = "#[red]游戏出现错误，重启试试#[stop]\n"..(msg or "")
end

function game.on_resume()
end

function game.on_pause()
end

function game.gesture()
end

ej.start(game)


