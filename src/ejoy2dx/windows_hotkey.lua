
local ejoy2dx = require "ejoy2dx"
local message = require "ejoy2dx.message"
local keymap = require "ejoy2dx.keymap"
local os_utls = require "ejoy2dx.os_utls"

local handlers = {down={}, up={}}

handlers.up[keymap.VK_P] = function(char)
	if not os_utls.is_key_down(keymap.VK_CONTROL) then return end

	if ejoy2dx.game_stat.is_active then
		ejoy2dx.game_stat:pause()
	else
		ejoy2dx.game_stat:resume()
	end
end

handlers.up[keymap.VK_R] = function(char)
	if not os_utls.is_key_down(keymap.VK_CONTROL) then return end

	ejoy2dx.game_stat:reload()
end

local function init()
	if OS ~= "WINDOWS" then return end
	message.char(handlers)
end

return {
	handlers = handlers,
	init=init,
}