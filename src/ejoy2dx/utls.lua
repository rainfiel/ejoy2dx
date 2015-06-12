
local fw = require "ejoy2d.framework"
local json = require "ejoy2dx.json"
local os_utls = require "ejoy2dx.os_utls"

local function get_path(path)
	return string.format("%s/asset/%s", fw.WorkDir, path)
end

local M = {}
M.frame_per_second = fw.GameInfo.logic_frame
M.frame_rate = 1 / M.frame_per_second

function M.seconds_to_frame(seconds)
	return seconds * M.frame_per_second
end

function M.frame_to_seconds(frame)
	return frame / M.frame_per_second
end

function M.read_file(path)
	path = get_path(path)
	return os_utls.read_file(path)
end

function M.write_file(path, data)
	path = get_path(path)
	if os_utls.exists(path) then
		os_utls.delete_file(path)
	end
	os_utls.write_file(path, data)
end

function M.delete_file(path)
	path = get_path(path)
	if os_utls.exists(path) then
		os_utls.delete_file(path)
	end
end

function M.load_json(path)
	local str = M.read_file(path)
	if not str then return end
	return json:decode(str)
end

function M.save_json(path, tbl)
	local data = json:encode(tbl)
	if not data then return end
	M.write_file(path, data)
end

function M.save_json_pretty(path, tbl)
	local data = json:encode_pretty(tbl)
	if not data then return end
	path = get_path(path)
	os_utls.write_file(path, data)
end

M.get_path = get_path


function M.str_starts(the_string, start_str)
   return string.sub(the_string,1,string.len(start_str))==start_str
end

function M.str_ends(the_string, end_str)
   return end_str=='' or string.sub(the_string,-string.len(end_str))==end_str
end


return M
