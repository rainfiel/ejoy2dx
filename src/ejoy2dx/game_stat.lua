

local M = {is_active=true}

function M:reload()
	local texture = require "ejoy2dx.texture"

	local registry = debug.getregistry()

	local texture = texture:serialize_texture()
	registry.seraized_texture = texture

	registry.ejoy_reload = true

	self:pause()
end

function M:pause()
	self.is_active = false
end

function M:resume()
	self.is_active = true
end

return M
