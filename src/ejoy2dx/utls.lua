
local fw = require "ejoy2d.framework"
local json = require "ejoy2dx.json"
local os_utls = require "ejoy2dx.os_utls"

 -- modes:
 --   "d" for Documents
 --   "l" for Library
 --   "c" for Caches
 --		nil for bundle
local function get_path(path, mode)
	if not mode then
		return string.format("%s/asset/%s", fw.WorkDir, path)
	else
		return os_utls.get_path(path, mode)
	end
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

function M.create_directory(path, mode, recursion)
	if (recursion) then
		local full_path = get_path(path, mode)
		local curr_path = ""
		for dir in string.gmatch(full_path, "([^/\\]+)[/\\]*") do
			curr_path = curr_path .. dir .. "/"
			os_utls.create_directory(curr_path)
		end
	else
		return os_utls.create_directory(get_path(path, mode))
	end
end

function M.read_file(path,mode,...)
	path = get_path(path,mode)
	return os_utls.read_file(path,...)
end

function M.write_file(path,mode,data,...)
	path = get_path(path,mode)
	if os_utls.exists(path) then
		os_utls.delete_file(path)
	end
	os_utls.write_file(path, data,...)
end

function M.delete_file(path,mode)
	path = get_path(path,mode)
	if os_utls.exists(path) then
		os_utls.delete_file(path)
	end
end

function M.load_json(path,mode)
	local str = M.read_file(path,mode)
	if not str then return end
	return json:decode(str)
end

function M.save_json(path,mode,tbl)
	local data = json:encode(tbl)
	if not data then return end
	M.write_file(path,mode,data)
end

function M.save_json_pretty(path,mode,tbl)
	local data = json:encode_pretty(tbl)
	if not data then return end
	path = get_path(path,mode)
	os_utls.write_file(path, data)
end

M.get_path = get_path


function M.str_starts(the_string, start_str)
   return string.sub(the_string,1,string.len(start_str))==start_str
end

function M.str_ends(the_string, end_str)
   return end_str=='' or string.sub(the_string,-string.len(end_str))==end_str
end


function M.print_tbl(tbl, ref)
    ref = ref or {}
    local dbg = {}
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            if ref[v] then
                table.insert(dbg, tostring(k).."=".."ref_"..tostring(v))
            else
                ref[v] = true
                table.insert(dbg, tostring(k).."="..M.print_tbl(v, ref).."\n")
            end
        else
            table.insert(dbg, tostring(k).."="..tostring(v))
        end
    end
    return "{"..table.concat(dbg, ",").."}"
end
return M
