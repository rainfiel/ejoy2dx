
local utls = require "ejoy2dx.utls"

local M = {}

--refer to wall width
M.minimal_collide_pixels = 4

--collide type
M.collide_wall 			= 255
M.collide_wall_peak	= 254
M.collide_wall_edge = 253

M.collide_static 		= 200

function M.texture_path(path)
	path = utls.get_path(path)
	path = string.gsub(path, "(.dds)", ".png")
	-- path = string.gsub(path, "(.tga)", ".png")
	return path
end

function M.parse_pos(origin)
	local nums = {}
	for match in string.gmatch(origin, "([^ ]+)") do
		table.insert(nums, tonumber(match))
	end
	return nums[1], nums[2]
end


return M