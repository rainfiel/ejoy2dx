
local matrix = require "ejoy2d.matrix"
local utls = require "ejoy2dx.utls"
local image = require "ejoy2dx.image"
local math = require "math"

local mt = {}
mt.__index = mt

-- local brick_path = utls.get_path("data/textures/fx/player_path_highlighted.tga")
local brick_path = "data/textures/fx/red_dot.tga"

function mt:init()
	self.bricks = {}

	self.brick = image:load_image(brick_path, "brick")
	self.matrix_cache = {}
	self.active_matrix = {}
	self.active_colors = {}
	self.brick_cnt = nil

	self.point_dist = 4
end

function mt:show(points)
	local point_dist = self.point_dist
	self.brick_cnt = math.floor( #points/2/point_dist )
	local mcnt = #self.matrix_cache
	local delta = self.brick_cnt - mcnt
	while delta > 0 do
		table.insert(self.matrix_cache, matrix())
		delta = delta-1
	end

	for i = 1, self.brick_cnt do
		local x, y = points[2*point_dist*(i-1)+1], points[2*point_dist*(i-1)+2]
		local mat = self.matrix_cache[i]
		mat:identity()
		mat:trans(x, y)
		self.active_matrix[i] = mat
		self.active_colors[i] = 0xFFFFFFFF
	end
end

function mt:pop()
	if not self.bricks then return end
	local cnt = #self.bricks
	self.bricks[cnt] = nil
end

function mt:hide()
	self.brick_cnt = nil
end

function mt:draw(srt)
	if self.brick_cnt and self.brick_cnt > 0 then
		self.brick:matrix_multi_draw(nil, self.brick_cnt, self.active_matrix, self.active_colors)
	end
end


local M = {}

function M:init()
	local view = setmetatable({}, mt)
	view:init()
	return view
end

return M
