
local geo = require "ejoy2d.geometry"
local render_mgr = require "ejoy2dx.render"
local fw = require "ejoy2d.framework"

local screen_width = fw.GameInfo.width
local screen_height = fw.GameInfo.height

local panel_mt = {}
panel_mt.__index = panel_mt

function panel_mt:show()
	self.is_show = true
	if self.is_root then
		self.render:show(self)
	end
end

function panel_mt:hide()
	self.is_show = false
	if self.is_root then
		self.render:hide(self)
	end
end

function panel_mt:position(x, y)
	if not self.matrix then
		self.matrix = {1.0,0,0,0,	0,1.0,0,0,	0,0,1.0,0,	0,0,0,1.0}
	end
	self.matrix[13] = 2 * x / screen_width
	self.matrix[14] = -2 * y / screen_height
	print(table.concat(self.matrix, ";"))
end

function panel_mt:scale(scale1, scale2)
	scale2 = scale2 or scale1
	self.matrix[1] = scale1
	self.matrix[6] = scale2
end

function panel_mt:draw()
	if not self.is_show then return end
	if self.matrix then
		geo.matrix(table.unpack(self.matrix))
	end
	for k, v in ipairs(self.controls) do
		local ctrl = rawget(geo, v[1])
		if ctrl then
			ctrl(table.unpack(v, 2))
		else
			v[1]:draw()
		end
	end
end

-- geo.line(x1,y1,x2,y2,color)
-- geo.box(x,y,w,h,color)
-- geo.polygon(hexagon, color)
-- geo.frame(x,y,w,h,color,border)
function panel_mt:add_control(...)
	table.insert(self.controls, {...})
end

local function new_panel(render)
	if type(render) == "number" then
		render = render_mgr:create(render)
	end
	local raw = {render=render, usr_data={}, controls={}, is_root=true}
	local ret = setmetatable(raw, panel_mt)
	if getmetatable(render) == panel_mt then
		ret.is_show = true
		ret.is_root = false
		render:add_control(ret)
	end
	return ret
end
---------------------------------------------------------------

return {
	panel = new_panel,
}
