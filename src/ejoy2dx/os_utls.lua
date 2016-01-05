
local osutls = require "ejoy2dx.osutil.c"

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

return M
