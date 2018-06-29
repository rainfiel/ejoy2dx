

local M = {is_active=true}

function M:reload()
	local texture = require "ejoy2dx.texture"

	local registry = debug.getregistry()

	local texture = texture:serialize_texture()
	registry.seraized_texture = texture

	registry.ejoy_reload = true

	local music = require "ejoy2dx.Liekkas.music"
	music.clear()
	local sound = require "ejoy2dx.Liekkas.sound"
	sound:clear()
	local audio = require "ejoy2dx.Liekkas.audio"
	audio:clear()
	self:pause()

	collectgarbage()
end

function M:pause()
	self.is_active = false
end

function M:resume()
	self.is_active = true
end

return M
