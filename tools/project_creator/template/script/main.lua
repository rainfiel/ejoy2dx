local ej = require "ejoy2d"
local ejoy2dx = require "ejoy2dx"
local fw = require "ejoy2d.framework"
local package = require "ejoy2dx.package"
local image = require "ejoy2dx.image"

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
end

function game.handle_error(...)
end

function game.on_resume()
end

function game.on_pause()
end

function game.gesture()
end

ej.start(game)


