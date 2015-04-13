
local utls = require "ejoy2dx.utls"
local image = require "ejoy2dx.image"
local image_c = require "ejoy2dx.image.c"

local spritepack = require "ejoy2d.spritepack"

local default_color = {0,0,0,0}
local SCREEN_SCALE = 16

local mt = {}
mt.__index = mt

function mt:begin_pack()
	assert(not self.texture_id)
	self.texture_id = image:create_custom_texture(self.name, self.width, self.height, default_color)
	self.raw = {}
	self.max_id = 0

	self.file_info = {}

	self.packages = {}
end

function mt:add(path)
	local _, name = string.match(path, "(.-)([^\\/]-)%.?([^%.\\/]*)$")

	if self.file_info[name] then return end
	local tw, th, comp, img_data = image_c.image_rawdata(utls.get_path(path), 4)

	local file = {tw, th, img_data, name}
	self.file_info[name] = file
	table.insert(self.file_info, file)
end

function mt:end_pack()
	local pack_tbl = self:shelf_pack()
	self:new_pack(self.name, pack_tbl)
end

function mt:new_pack(name, tbl)
	table.insert(self.packages, name)
	local p = spritepack.pack(tbl)
	spritepack.init(name, {self.texture_id}, p)
end

function mt:destroy()
	for k, v in ipairs(self.packages) do
		spritepack.remove(v)
	end
	image:remove_custom_texture(self.texture_id)
end

----------------------------shelf pack-----------------------
function mt:cutout_width(idx)
	local last=idx-1
	local width = 0
	local cnt = #self.file_info
	for i=idx, cnt do
		width = width + self.file_info[i][1]
		if width > self.width then
			last = i-1
			break
		end
		if i == cnt then
			last = cnt
		end
	end
	return last >= idx and last or nil
end

local function new_pic(idx, name, tx, ty, tw, th)
	local pic = 	{
		{
			tex = 1,
			-- src = {0,0,0,150,150,150,150,0},
			-- screen = {-1200,-1200,-1200,1200,1200,1200,1200,-1200}
		},
		type = "picture",
		id = idx * 2 - 1
	}

	pic[1].src = {tx, ty,  tx, ty+th,
									 tx+tw, ty+th,  tx+tw, ty}

	tw = tw * SCREEN_SCALE
	local sw = tw * 0.5

	th = th * SCREEN_SCALE
	local sh = th * 0.5
	pic[1].screen = {-sw, -sh, -sw, th-sh, tw-sw, th-sh, tw-sw, -sh}

	local ani = 	{
		component = 	{
			{id = idx * 2 - 1}
		},
		export = name,
		type = "animation",
		id = idx * 2,
		{
			{{
					index = 0
			}}
		}
	}
	return pic, ani
end

--TODO fix space overflow
function mt:shelf_pack()
	local output = {}
	table.sort(self.file_info, function(l, r)
		return l[1] > r[1]
	end)
	local function height_sort(l, r)
		return l[2] > r[2]
	end

	local line_start = 1
	local line_end = self:cutout_width(line_start)
	local width, height = 0, 0
	local idx = 1
	while line_end and line_end <= #self.file_info do
		local line = table.pack(table.unpack(self.file_info, line_start, line_end))
		table.sort(line, height_sort)
		for k, v in ipairs(line) do
			image_c.texture_sub_update(self.texture_id, width, height, v[1], v[2], v[3])
			local pic, ani = new_pic(idx, v[4], width, height, v[1], v[2])
			table.insert(output, pic)
			table.insert(output, ani)
			idx = idx+1
			width = width + v[1]
		end
		width = 0
		height = height + line[1][2]

		line_start = line_end+1
		line_end = self:cutout_width(line_start)
	end
	return output
end

local M = {}

function M:new(name, width, height)
	local ret = setmetatable({name=name, width=width, height=height}, mt)
	return ret
end

return M
