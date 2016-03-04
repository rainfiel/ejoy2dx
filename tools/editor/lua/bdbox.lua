
local simple_ui = require "ejoy2dx.simple_ui"

local panel = simple_ui.panel(99999)
local frame_color = 0xFF00FF00
local frame_border = 1

local function show_bd(root, spr)
	panel.controls = {}
	if not spr.aabb then return end
	local anchor = root.usr_data.render and root.usr_data.render.anchor
	if anchor then
		local x0, y0, x1, y1 = spr:aabb(anchor, true, true)
		panel:add_control("frame", x0, y0, x1-x0, y1-y0, frame_color, frame_border)
		panel:show()
	end
end

local function clear()
	panel.controls = {}
	panel:hide()
end

bdbox = {
	show_bd=show_bd,
	clear=clear
}
