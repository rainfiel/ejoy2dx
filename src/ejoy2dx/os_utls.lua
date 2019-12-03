
local osutls = require "ejoy2dx.osutil.c"
local keymap = require "ejoy2dx.keymap"

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
M.create_directory = osutls.create_directory

local ok, text_input = pcall(require, "ejoy2dx.text_input")
if ok and text_input then
	M.input = text_input.input
end

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
