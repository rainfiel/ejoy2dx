
local matrix = require "ejoy2d.matrix"

local M = {}

function M:init()
	self.matrix_cache = {}
	self.active_matrix = {}
	self.active_colors = {}
end

function M:draw_points(srt, spr, points, pcnt, color, rot, scale)
	if not points then return end
	if pcnt <= 0 then return end
	assert(pcnt*2<=#points)

	color = color or 0xFFFFFFFF

	local mcnt = #self.matrix_cache
	local delta = pcnt - mcnt
	while delta > 0 do
		table.insert(self.matrix_cache, matrix())
		delta = delta-1
	end

	local x, y, mat
	for i=1, pcnt do
		x, y = points[2*i-1], points[2*i]
		mat = self.matrix_cache[i]
		mat:identity()
		mat:scale(scale or 1)
		mat:rot(rot or 0)
		mat:trans(x, y)
		self.active_matrix[i] = mat
		self.active_colors[i] = color
	end

	spr:multi_draw(srt, pcnt, self.active_matrix, self.active_colors)
end

function M:test(touch_x, touch_y, srt, spr, points, pcnt, rot, scale)
	if not points then return end
	if pcnt <= 0 then return end
	assert(pcnt*2<=#points)

	local mcnt = #self.matrix_cache
	local delta = pcnt - mcnt
	while delta > 0 do
		table.insert(self.matrix_cache, matrix())
		delta = delta-1
	end

	local x, y, mat
	for i=1, pcnt do
		x, y = points[2*i-1], points[2*i]
		mat = self.matrix_cache[i]
		mat:identity()
		mat:scale(scale or 1)
		mat:rot(rot or 0)
		mat:trans(x, y)
		self.active_matrix[i] = mat
	end

	return spr:multi_draw_test(srt, pcnt, self.active_matrix, touch_x, touch_y)
end

M:init()
return M
