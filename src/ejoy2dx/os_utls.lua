
local osutls = require "ejoy2dx.osutil.c"
local keymap = require "ejoy2dx.keymap"
-- local text_input = require "ejoy2dx.text_input"

local M = {}

-------------filesystem---------
-- M.mkdir = osutls.mkdir
-- M.get_path = osutls.get_path
-- M.join_path = osutls.join_path

M.exists = osutls.exists

M.read_file = osutls.read_file
M.delete_file = osutls.delete_file
M.write_file = osutls.write_file
M.get_path = osutls.get_path
-- M.input = text_input.input
M.create_directory = osutls.create_directory

M.is_key_down = function(name)
	if OS == "WINDOWS" then
		local key = keymap:name_to_key(name)
		print(name, key)
		return osutls.is_key_down(key)
	else
		return false
	end
end

M.open_url = function( ... )
	if OS == "WINDOWS" then
		return false
	else
		return osutls.open_url(...)
	end
end

return M
