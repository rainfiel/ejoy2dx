
local ppm = require "ejoy2d.ppm"
local spritepack = require "ejoy2d.spritepack"
local simplepackage = require "ejoy2d.simplepackage"

local image_c = require "ejoy2dx.image.c"
local texture = require "ejoy2dx.texture"
local utls = require "ejoy2dx.utls"

local function extname(str)
	return string.lower(string.match(str, "([^.]+)$"))
end

local function splitpath(str)
	local tbl = {}
	for match in string.gmatch(str, "([^.]+)") do
		table.insert(tbl, match)
	end
	return tbl[1], tbl[2]
end

local function load_raw(packname, filename)
	local data = assert(utls.read_file(filename..".lua"), filename)
	data = load(data, packname, "t", {})()
	local p = {}
	p.meta = assert(spritepack.pack(data))

	p.tex = {}
	for i=1,p.meta.texture do
		local path = utls.get_path(filename.."."..i)
		local tex_id = texture:query_texture(path)
		if not tex_id then
			tex_id = texture:add_texture(path)
			ppm.texture(tex_id, path)
		end
		p.tex[i] = tex_id
	end
	spritepack.init(packname, p.tex, p.meta)
	return p
end

local function load_img(packname, filename, ext)
	local data = assert(utls.read_file(filename..".lua"), filename)
	data = load(data, packname, "t", {})()
	local p = {}
	p.meta = assert(spritepack.pack(data))

	p.tex = {}
	for i=1,p.meta.texture do
		local path = utls.get_path(filename.."."..ext)
		local tex_id = texture:query_texture(path)
		if not tex_id then
			tex_id = texture:add_texture(path)
			image_c.loadimage(tex_id, path)
		end
		p.tex[i] = tex_id
	end
	spritepack.init(packname, p.tex, p.meta)
	return p
end

-------------------------------------------------------------------------------
local pack = {}
pack.loader = {
	lua = load_raw,
	png = load_img,
}

function pack:register_loader(tag, loader)
	rawset(self.loader, tag, loader)
end

function pack:path(pattern)
	self.package_pattern = pattern
end

function pack:load(tbl)
	-- self:path(assert(tbl.pattern))
	for _,v in ipairs(tbl) do
		self:do_load(v)
		-- collectgarbage "collect"
	end
end

function pack:do_load(packname)
	local exist = spritepack.query_package(packname)
	if exist then return exist end

	local name, ext = splitpath(packname)
	local loader = rawget(self.loader,ext)
	return loader(packname, name, ext)
end

function pack:prepare_package(package, add_to_simple)
	local exist = pack:do_load(package)
	if add_to_simple then
		local name, ext = splitpath(package)
		simplepackage.add_package(name, exist)
		spritepack.alias(package, name)
	end
end

return pack
