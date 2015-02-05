
-- This limit defined in texture.c
local MAX_TEXTURE = 128

local M = {}

function M:init()
	self.texture_count = 0
	self.texture_map = {}
end

local function insert(tbl, idx, val)
	tbl[idx] = val
	rawset(tbl, val, idx)
end

local function remove(tbl, idx, val)
	tbl[idx] = nil
	rawset(tbl, val, nil)
end

--should be the absolute path of the file or a unique string
function M:add_texture(path)
	assert(type(path) == "string")
	local id = rawget(self.texture_map, path)
	if id then return id end

	for i=1, self.texture_count do
		if not self.texture_map[i] then
			id = i
			insert(self.texture_map, id, path)
			break
		end
	end

	if not id then
		self.texture_count = self.texture_count + 1
		assert(self.texture_count <= MAX_TEXTURE)
		id = self.texture_count
		insert(self.texture_map, id, path)
	end
	return id
end

function M:remove_texture(path)
	assert(type(path) == "string")
	local id = rawget(self.texture_map, path)
	if not id then return end
	remove(self.texture_map, id, path)
end

return M