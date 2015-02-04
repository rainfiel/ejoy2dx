
local utls = require "ejoy2dx.utls"
local vector2 = require "ejoy2dx.vector2"
local bezier = require "ejoy2dx.bezier.bezier"
local bspline = require "ejoy2dx.bezier.bspline"
local catmull = require "ejoy2dx.bezier.catmull"
local angle = require "ejoy2dx.angle"

local global = require "global"
local collide = require "battle.collide"
local path_view = require "battle.path_view"
local math = require "math"

-- local curve = bspline
-- local curve = bezier
local curve = catmull

local curve_points_count = 50
local mt = {}
mt.__index = mt

function mt:init(avatar, meter_per_sec)
	self.avatar = avatar
	self.meter_per_sec = meter_per_sec
	self.x, self.y, self.rot = 0, 0, 0
	self.points = {}
	self.curve = nil
	self.frame_to_launch = nil
	self.vertex_idx = nil

	self.view = path_view:init()
	self:calc_speed(meter_per_sec)
end

function mt:calc_speed(meter_per_sec)
	if not global.current_level then
		self.pix_per_meter = 0
		return
	end
	local pixels_per_meter = global.current_level.pix_per_meter
	local spd_pix_per_sec = pixels_per_meter * meter_per_sec
	self.pix_per_frame = spd_pix_per_sec * utls.frame_rate

	print("velocity:", self.pix_per_frame)
end

function mt:is_pathing()
	return self.polygon ~= nil
end

function mt:add_new_point(x, y)
	local pcnt = #self.points
	
	local lv = global.current_level
	local edge = false
	if self.blocked then
		local fx, fy = self.x, self.y
		if pcnt >= 2 then
			fx, fy = self.points[pcnt-1], self.points[pcnt]
		end
		local rx, ry, clear = collide.edge_reachable(lv, fx, fy, x, y)
		self.blocked = not clear
		if rx and ry then
			x, y = rx, ry
			edge = true
		else
			return
		end
	end
	
	if pcnt > 2 and self.points[pcnt-1] == x and self.points[pcnt] == y then
		return
	end

	if not edge and collide.point_hit(lv, x, y) then
		self.blocked = true
		return
	end
	table.insert(self.points, x)
	table.insert(self.points, y)

	pcnt = #self.points
	if pcnt < 6 then
		return
	end
	-- if not self.polygon or #self.polygon < curve_points_count then
	-- 	local curve = curve.new(self.points)
	-- 	self.polygon = curve:polygon(1)
	-- else
	-- 	local cnt = #self.polygon
	-- 	local start = cnt - curve_points_count + 1
	-- 	local tail = table.pack(table.unpack(self.polygon, start, cnt))
	-- 	table.insert(tail, x)
	-- 	table.insert(tail, y)
	-- 	local curve = curve.new(tail)
	-- 	local new_polygon = curve:polygon(3)
	-- 	for k, v in ipairs(new_polygon) do
	-- 		self.polygon[start+k-1] = v
	-- 	end
	-- end

	-- self.curve = curve.new(self.points)
	-- self.polygon = self.curve:polygon(3)
	-- self.polygon = self.points

	self.polygon = curve(self.points, 2)

	if not self.vertex_idx then
		self.vertex_idx = 1
	end
	self.view:show(self.polygon)
end

function mt:stop_add_point(x, y)
	if not self.blocked then
		self:add_new_point(x, y)
	end
	self.blocked = false
end

function mt:clear_path()
	self.curve = nil
	self.polygon = nil
	self.vertex_idx = nil
	self.move_dir = nil
	self.look_dir = nil
	self.view:hide()
	self.points = {}
end

function mt:update()
	if self:is_pathing() then
		local reach = self:move_along(self.pix_per_frame)
		if reach then
			self:clear_path()
		end
	end
end

function mt:move_along(dist)
	local tar_x, tar_y = self.polygon[2*self.vertex_idx-1], self.polygon[2*self.vertex_idx]
	if not tar_x then
		return true
	end

	local dir_x, dir_y = vector2.sub(tar_x, tar_y, self.x, self.y)
	self.move_dir = math.deg(vector2.angleTo(dir_x, dir_y))
	-- print(tar_x, tar_y, self.x, self.y, self.move_dir)

	--dist2?
	local len = vector2.dist(self.x, self.y, tar_x, tar_y)
	if len > dist then
		local rate = dist / len
		local c_x, c_y = vector2.lerp(self.x, self.y, tar_x, tar_y, rate)
		self:ps(c_x, c_y)
	else
		self.vertex_idx = self.vertex_idx + 1
		self.view:pop()
		self:ps(tar_x, tar_y)
		if len < dist then
			self:move_along(dist-len)
		end
	end
	return false
end

function mt:face_forward()
	if self.move_dir then
		self.rot = angle.decay(self.rot, self.move_dir, 0.1, utls.frame_rate)
		-- print(self.move_dir)
		self:sr(self.rot)
	end
end

function mt:look_around()
	if not self.look_dir then
		local delta = math.random(-90, 90)
		if math.abs(delta) < 10 then return false end
		self.look_dir = angle.add(delta, self.rot)
		self.look_halflife = math.random(3000) / 10000
	end
	self.rot = angle.decay(self.rot, self.look_dir, self.look_halflife, utls.frame_rate)
	self:sr(self.rot)
	local delta = math.abs(angle.sub(self.rot, self.look_dir))
	if delta < 1 then
		self.look_dir = nil
		return false
	else
		return true
	end
end

function mt:sleep()
	if not self.sleep_time then
		self.sleep_time = math.random(3, 10) / utls.frame_rate
	end
	self.sleep_time = self.sleep_time - 1
	if self.sleep_time <= 0 then
		self.sleep_time = nil
		return false
	else
		return true
	end
end

function mt:ps(x, y)
	self.x, self.y = x, y
	self.avatar:ps(x, y)
end

function mt:sr(rot)
	self.rot = rot
	self.avatar:sr(rot)
end

local M = {}

function M:init()
	self.paths = {}
end

function M:new(...)
	local p = setmetatable({}, mt)
	p:init(...)
	table.insert(self.paths, p)
	return p
end

-- function M:update()
-- 	for _, v in ipairs(self.paths) do
-- 		v:update()
-- 	end
-- end

return M