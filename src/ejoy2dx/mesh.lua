
local pack = require "ejoy2d.spritepack"
local pack_c = require "ejoy2d.spritepack.c"
local sprite = require "ejoy2d.sprite"
local image_c = require "ejoy2dx.image.c"

local ejoy2dx = require "ejoy2dx"
local image = require "ejoy2dx.image"
local texture = require "ejoy2dx.texture"

local mt = {}
mt.__index = mt

function mt:init(tex, points)
	local cnt = #points
	assert(cnt % 2 == 0)

	local src = {}
	local screen = {}
	local tex, tw, th = self:load_tex(tex)

	local pic = {	{
		{
			tex = 1,
			src = src,
			screen = screen
		},
		type = "polygon",
		id = 0
	} }

	local vertex = {}
	local min_x, min_y
	local max_x, max_y
	for k=1, cnt // 2 do
		local x = points[2*k-1]
		if not min_x or x < min_x then min_x = x end
		if not max_x or x > max_x then max_x = x end
		table.insert(screen, x * ejoy2dx.SCREEN_SCALE)

		local y = points[2*k]
		if not min_y or y < min_y then min_y = y end
		if not max_y or y > max_y then max_y = y end
		table.insert(screen, y * ejoy2dx.SCREEN_SCALE)

		vertex[k] = {x, y}
	end

	local dx = max_x - min_x
	local dy = max_y - min_y
	local sx = tw / dx
	local sy = th / dy
	for k=1, cnt // 2 do
		local x = points[2*k-1]
		table.insert(src, x * sx)
		local y = points[2*k]
		table.insert(src, y * sy)
	end

	local meta = assert(pack.pack(pic))
	assert(meta.texture == 1)
	self.cobj = pack_c.import({tex},meta.maxid,meta.size,meta.data, meta.data_sz)
	self.sprite = sprite.direct_new(self.cobj, 0)
	self.vertex = vertex

	self.sprite:polygon_vert(1, 3, 30)
	self.sprite:polygon_vert(1, 9, 130)
end

function mt:load_tex(path)
	local tex_id, tw, th = texture:query_texture(path)
	if not tex_id then
		tex_id = texture:add_texture(path)
		tw, th = image_c.loadimage(tex_id, path)
		texture:add_texture_info(path, tw, th)
	end
	return tex_id, tw, th
end

local M = {}
function M:new(...)
	local m = setmetatable({}, mt)
	m:init(...)
	return m
end
return M