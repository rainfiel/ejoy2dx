
local math = math
local global = require "global"
local vector2 = require "ejoy2dx.vector2"
local image = require "ejoy2dx.image"
local os_utls = require "ejoy2dx.os_utls"
local image_c = require "ejoy2dx.image.c"
local utls = require "ejoy2dx.utls"

local M = {}

function M.point_hit(lv, x, y)
	x = math.floor(x+0.5)
	y = math.floor(y+0.5)

	local data = lv.collide_data
	if not data then return false end
	x, y = lv:screen_to_scene(x, y)
	local w, h = lv.width, lv.height
	local point = y * w + x
	local alpha = string.sub(data, point, point)
	if not alpha then return false end
	return string.byte(alpha) > 0

	-- local wallx, wally = lv:screen_to_scene(x, y)
	-- if M.sprite_hit(lv.wall, wallx, wally, 0, 0) then
	-- 	print("hit wall")
	-- 	return true
	-- end

	-- local touched, hit_x, hit_y = lv:find_touched(x, y)
	-- if not touched then return end

	-- if M.sprite_hit(touched, hit_x, hit_y, 0.5, 0.5) then
	-- 	print("hit entity")
	-- 	touched.color=0xFFFF0000
	-- 	return true
	-- end
end

function M.sprite_hit(spr, x, y, key_x, key_y)
	local info, w, h = image:get_collide_info(spr)
	if not info then return end
	x = x + w * key_x
	y = y + h * key_y
	local line = info[y]
	if not line then return false end
	return line[x] and line[x] > 0
end

function M.edge_reachable(lv, from_x, from_y, ref_x, ref_y)
	local dist = global.minimal_collide_pixels
	local dir_x, dir_y = vector2.sub(ref_x, ref_y, from_x, from_y)
	local nx, ny = vector2.normalize(dir_x, dir_y)
	local toward_x, toward_y = vector2.add(from_x, from_y, vector2.mul(dist, nx, ny))
	if not M.point_hit(lv, toward_x, toward_y) then
		-- print("straight:", from_x, from_y, toward_x, toward_y)
		return toward_x, toward_y, true
	end

	nx, ny = vector2.normalize(0, dir_y)
	dist = math.min(global.minimal_collide_pixels, math.abs(dir_y))
	local toward_x, toward_y = vector2.add(from_x, from_y, vector2.mul(dist, nx, ny))
	if not M.point_hit(lv, toward_x, toward_y) then
		-- print("along y:", from_x, from_y, toward_x, toward_y)
		return toward_x, toward_y
	end

	nx, ny = vector2.normalize(dir_x, 0)
	dist = math.min(global.minimal_collide_pixels, math.abs(dir_x))
	local toward_x, toward_y = vector2.add(from_x, from_y, vector2.mul(dist, nx, ny))
	if not M.point_hit(lv, toward_x, toward_y) then
		-- print("along x:", from_x, from_y, toward_x, toward_y)
		return toward_x, toward_y
	end
end

function M.has_collide_file(path)
	return os_utls.exists(path)
end

local function draw_entity_to_map(ent, collide_image, lv)
	local pic, w, h = image:get_collide_info(ent)
	local m0, m1, m2, m3, m4, m5 = matrix(ent.matrix):export()
	local x0, y0, x1, y1 = math.floor(-w/2), math.floor(-h/2),
												 math.ceil(w/2), math.ceil(h/2)

	local lx, ly = 1, 1
	for y=y0, y1 do
		for x=x0, x1 do
			local wx = math.floor((x*m0+y*m2) / 1024 + m4/16+0.5)
			local wy = math.floor((x*m1+y*m3) / 1024 + m5/16+0.5)
			wx, wy = lv:screen_to_scene(wx, wy)
			local src = pic[ly] and pic[ly][lx] or 0
			local tar = collide_image[wy] and collide_image[wy][wx] or nil
			if src and tar and src > tar then
				collide_image[wy][wx] = src
			end
			lx = lx+1
		end
		lx = 1
		ly = ly+1
	end
end


function M.get_collide_data(path, lv)
	path = utls.get_path(path)
	if not M.has_collide_file(path) then
		return
	end
	local tw, th, comp, img_data = image_c.image_rawdata(path)
	return img_data
end

return M
