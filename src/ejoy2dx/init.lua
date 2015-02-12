
local sprite = require "ejoy2d.sprite"
local fw = require "ejoy2d.framework"

local ejoy2dx = {}

ejoy2dx.texture = require("ejoy2dx.texture")
ejoy2dx.texture:init()

ejoy2dx.package = require("ejoy2dx.package")
function ejoy2dx.sprite(package, name)
	ejoy2dx.package:prepare_package(package)
	return sprite.new(package, name)
end

ejoy2dx.render = require("ejoy2dx.render")
ejoy2dx.render:init(fw.GameInfo.width, fw.GameInfo.height)

ejoy2dx.animation = require("ejoy2dx.animation")
ejoy2dx.animation:init(fw.GameInfo.logic_frame)

return ejoy2dx
