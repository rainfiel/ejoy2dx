
local image_c = require "ejoy2dx.image.c"

local sprite = require "ejoy2d.sprite"
local pack = require "ejoy2d.spritepack"
local pack_c = require "ejoy2d.spritepack.c"

local SCREEN_SCALE = 16
local sprite_template = [[
return
{
	{
		component = 	{
			{id = 1}
		},
		export = "%s",
		type = "animation",
		id = 0,
		{
			{{
					index = 0
			}}
		}
	}
}
]]

local mt = {}

local M = {}
M.texture_id = 0
M.textures = {}


----------------------------image-------------------------------
function M.save_image( ... )
	return image_c.saveimage(...)
end

function M:load_image(path, name, collide, ani_callback)
	self.packages = self.packages or {}
	local cobj = nil
	name = name or ""
	local package_id = path.."."..name
	-- print(package_id, self.packages[package_id])
	if not self.packages[package_id] then
		local tex_id, tw, th
		local hit = self.textures[path]
		if hit then
			tex_id, tw, th = table.unpack(hit)
		end
		if not tex_id then
			tex_id = self:register_texture()

			local collide_info
			if collide then
				local comp, img_data
				tw, th, comp, img_data = image_c.image_rawdata(path)
				collide_info = self.collide_info(tw, th, comp, img_data)
				image_c.rawdata_to_texture(tex_id, tw, th, comp, img_data)
			else
				tw, th = image_c.loadimage(tex_id, path)
			end

			self.textures[path] = {tex_id, tw, th, collide_info}
		end
		-- print(name, tw, th)

		local tx, ty = 0, 0
		local cfg = string.format(sprite_template, name)
		cfg = load(cfg)()

		if ani_callback then
			ani_callback(cfg, tx, ty, tw, th)
		else
			self.add_picture(cfg, tx, ty, tw, th, mirror_x, mirror_y)
		end

		local meta = assert(pack.pack(cfg))
		assert(meta.texture == 1)
		cobj = pack_c.import({tex_id},meta.maxid,meta.size,meta.data, meta.data_sz)

		self.packages[package_id] = cobj
	else
		cobj = self.packages[package_id]
	end
	local spr = sprite.direct_new(cobj, 0)
	spr.usr_data.path = path
	local tex_info = self.textures[path]
	return spr, tex_info[2], tex_info[3]
end

function M.add_picture(...)
	return M.add_picture_with_key(0.5, 0.5, ...)
end

function M.add_picture_with_key(key_x,key_y,cfg,tx,ty,tw,th,mirror_x,mirror_y)
	local pic = 	{
		{
			tex = 1,
			-- src = {0,0,0,150,150,150,150,0},
			-- screen = {-1200,-1200,-1200,1200,1200,1200,1200,-1200}
		},
		type = "picture",
		id = #cfg
	}

	pic[1].src = {tx, ty,  tx, ty+th,
									 tx+tw, ty+th,  tx+tw, ty}

	tw = tw * SCREEN_SCALE
	local sw = tw * key_x
	sw = mirror_x and -sw or sw

	th = th * SCREEN_SCALE
	local sh = th * key_y
	sh = mirror_y and -sh or sh
	pic[1].screen = {-sw, -sh, -sw, th-sh, tw-sw, th-sh, tw-sw, -sh}

	table.insert(cfg, pic)
	return pic.id
end

function M.add_component(cfg, comp)
	if comp.id then
		table.insert(cfg[1].component, comp)
	else
		assert(#comp>1)
		cfg[1].component = comp
	end
end

function M.add_animation(cfg, ani)
	table.insert(cfg[1], ani)
end

function M.set_frame_matrix(cfg, mat)
	cfg[1][1][1][1].mat = mat
end

function M:create_polygon(points, color)
	if not self.share_polygon_texture then
		self.share_polygon_texture = self:create_custom_texture(32, 32, {255, 0, 0, 128})
	end

	-- local cfg = string.format(polygon_template, name)
	-- cfg = load(cfg)()
	local src = {}
	local screen = {}

	local pic = {	{
		{
			tex = 1,
			src = src,
			screen = screen
		},
		type = "polygon",
		id = 0
	} }

	for _, v in ipairs(points) do
		local val = v * SCREEN_SCALE
		table.insert(src, val)
		table.insert(screen, val)
	end

	local meta = assert(pack.pack(pic))
	assert(meta.texture == 1)
	local cobj = pack_c.import({self.share_polygon_texture},meta.maxid,meta.size,meta.data, meta.data_sz)
	return sprite.direct_new(cobj, 0)
end

--------------------------texture------------------------------
function M:register_texture()
	local tex_id = self.texture_id
	self.texture_id = self.texture_id + 1
	return tex_id
end

--alpha
--{r, g, b, a}
--{r, g, b}
function M:create_custom_texture(width, height, color)
	local pix = nil
	local comp = nil
	if type(color) == "number" then
		pix = string.char(color)
		comp = 1
	elseif #color == 4 then
		pix = string.char(color[1])..string.char(color[2])..string.char(color[3])..string.char(color[4])
		comp = 4
	elseif #color == 3 then
		pix = string.char(color[1])..string.char(color[2])..string.char(color[3])
		comp = 3
	end
	assert(pix)
	local pixes = {}
	for i=1, width do
		for j=1, height do
			table.insert(pixes, pix)
		end
	end

	local tid = self:register_texture()
	local pix_str = table.concat(pixes)
	image_c.custom_texture(tid, width, height, comp, pix_str)
	return tid
end

------------------------raw data info--------------------------
function M.collide_info(tw, th, comp, img_data)
	local info = {}
	for i=1, th do
		local line = {}
		for j=1, tw do
			local pos = ((i-1) * tw + j) * comp
			local alpha = string.byte(img_data, pos, pos) or 0

			table.insert(line, alpha)
			-- table.insert(info, alpha)
		end
		table.insert(info, line)
		-- print(i.."--->"..table.concat(line, "|"))
	end
	return info
end

function M:get_collide_info(spr)
	local path = spr.usr_data.path
	if not path then return end
	local tex_info = self.textures[path]
	if not tex_info then return end
	return tex_info[4], tex_info[2], tex_info[3]
end

return M
