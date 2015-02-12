
local fw = require "ejoy2d.framework"
local serialize = require "ejoy2dx.serialize.c"

-- This limit defined in texture.c
local MAX_TEXTURE = 128

local M = {}

function M:init()
	local serialized = fw.GameInfo.serialized
	if serialized then
		self:deserialize_texture(serialized)
	else
		self.texture_map = {texture_count=0}
	end
end

local function insert(tbl, idx, val)
	tbl[idx] = val
	rawset(tbl, val, {idx})
end

local function remove(tbl, idx, val)
	tbl[idx] = nil
	rawset(tbl, val, nil)
end

function M:query_texture(path)
	assert(type(path) == "string")
	local info = rawget(self.texture_map, path)
	if info then
		return table.unpack(info)
	end
end

--should be the absolute path of the file or a unique string
function M:add_texture(path)
	local id, w, h = self:query_texture(path)
	if id then
		return id, w, h
	end

	for i=1, self.texture_map.texture_count do
		if not self.texture_map[i] then
			id = i
			insert(self.texture_map, id, path)
			break
		end
	end

	if not id then
		self.texture_map.texture_count = self.texture_map.texture_count + 1
		assert(self.texture_map.texture_count <= MAX_TEXTURE)
		id = self.texture_map.texture_count
		insert(self.texture_map, id, path)
	end
	return id
end

function M:add_texture_info(path, w, h)
	local info = rawget(self.texture_map, path)
	if info then
		table.insert(info, w)
		table.insert(info, h)
	end
end

function M:remove_texture(path)
	assert(type(path) == "string")
	local id = rawget(self.texture_map, path)
	if not id then return end
	remove(self.texture_map, id, path)
end

function M:serialize_texture()
	local bin = serialize.pack(self.texture_map)
	local s, length = serialize.serialize(bin)
	return s
end

function M:deserialize_texture(bin)
	self.texture_map = serialize.deserialize(bin)
end

return M
