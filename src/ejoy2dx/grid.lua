
local simple_ui = require "ejoy2dx.simple_ui"

local defalut_cell_width = 100
local defalut_cell_height = 30
local defalut_cell_frame_color = 0xFF669977

local grid_mt = {}
grid_mt.__index = grid_mt

function grid_mt:set_title(titles)
	self.titles = {}

	for k, v in ipairs(titles) do
		local cell = simple_ui.panel(self.root)
		table.insert(self.titles, cell)
		local x = (k-1)*defalut_cell_width
		cell:add_control("frame", x, 0, 
			defalut_cell_width, defalut_cell_height, defalut_cell_frame_color,2)
		cell:add_control("label", v,x+defalut_cell_width/2,0,
			0,24,0xFF00FF00,true)
	end
end

function grid_mt:show()
	self.root:show()
end

function grid_mt:hide()
	self.root:hide()
end

function grid_mt:position( ... )
	self.root:position(...)
end

function grid_mt:scale( ... )
	self.root:scale(...)
end

return function(layer, titles)
	local root = simple_ui.panel(layer)
	local ret = setmetatable({root=root}, grid_mt)
	ret:set_title(titles)
	return ret
end
