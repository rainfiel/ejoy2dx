
local ej = require "ejoy2d"
local fw = require "ejoy2d.framework"
local blend = require "ejoy2dx.blend"
local image_c = require "ejoy2dx.image.c"
local texture = require "ejoy2dx.texture"
local tween = require "ejoy2dx.tween"

local floor = math.floor

local RenderManager = {}
RenderManager.renders = {}


local mt = {}
mt.__index = mt

function mt:init()
	self.sprites = {}
	self.sorted_sprites = {}
	self.dirty = false
	self.show_order = 0
	self.fadeout_tween = nil

	self.draw_call = self._draw
end

function mt:set_offscreen(tex_id, w, h, name, drawonce)
	self.offscreen_id = tex_id
	self.drawonce = drawonce
	self.w, self.h, self.name = w, h, name

	self.need_clear = true
	self.draw_call = self._offscreen_draw
end

local function sort_order(left, right)
	local left_render = left.usr_data.render
	local right_render = right.usr_data.render
	if left_render.zorder == right_render.zorder then
		return left_render.show_order < right_render.show_order
	else
		return left_render.zorder < right_render.zorder
	end
end

function mt:resort()
	if self.dirty then
		self.dirty = false

		local old_cnt = #self.sorted_sprites
		local cnt = 0
		for k, v in pairs(self.sprites) do
			cnt = cnt+1
			self.sorted_sprites[cnt] = k
		end
		for i=cnt+1, old_cnt do
			self.sorted_sprites[i] = nil
		end
		table.sort(self.sorted_sprites, sort_order)
	end
end

function mt:set_order(spr, zorder)
	if not self.sprites[spr] then return end
	spr.usr_data.render.zorder = zorder
	self.dirty = true
end

function mt:test_spr(spr, x, y)
	local render = spr.usr_data.render
	if not render then return end
	return spr:test(x, y, render.anchor)
end

function mt:test(x, y)
	self.last_test_x, self.last_test_y = nil, nil
	local sprites = self.sorted_sprites
	local cnt = #sprites
	for i=cnt, 1, -1 do
		local spr = sprites[i]
		if spr.test then
			local usr_data = spr.usr_data
			local touch_callback = usr_data.touch_callback
			local gesture_callback = usr_data.gesture_callback
			if touch_callback and gesture_callback then
				error("only support handle touch or gesture only")
			end
			if touch_callback or gesture_callback then
				local anchor = usr_data.render.anchor
				local touched, lx, ly = spr:test(x, y, anchor)
				self.last_test_x, self.last_test_y = lx, ly
				if touched then
					local callback = touch_callback or gesture_callback
					local wx, wy = RenderManager:screen_to_world(anchor, x, y)
					return callback, touched, anchor.id, wx, wy, gesture_callback~=nil
				end
			end
		end
	end
end

local hide_list = {}
local hide_list_cnt = 0
function mt:_draw()
	self:resort()

	hide_list_cnt = 0
	local render
	local hided = false
	local alpha
	for k, v in ipairs(self.sorted_sprites) do
		hided = false
		alpha = 0xFF
		render = v.usr_data.render
		local fade = render.fade
		if fade then
			local rate, alive = fade:step()
			if alive then
				alpha = floor(alpha * rate)
				v.color = alpha << 24 | 0xFFFFFF
			else
				render.fade = nil
			end
		end
		local fadeout_index = render.fadeout_index
		if fadeout_index and self.fadeout_tween then
			local rate = self.fadeout_tween:get_value(fadeout_index)
			if rate then
				render.fadeout_index = fadeout_index + 1
				alpha = floor(alpha * rate)
				v.color = alpha << 24 | 0xFFFFFF
			else
				v.color = 0xFFFFFFFF
				render.fadeout_index = nil
				hided = true
			end
		end

		if hided then
			table.insert(hide_list, v)
			hide_list_cnt = hide_list_cnt+1
		else	
			if render.blend_mode then
				if blend.begin_blend(render.blend_mode) then
					v:draw(render.anchor)
					blend.end_blend()
				end
			else
				v:draw(render.anchor)
			end
			if render.on_draw then
				hided = render.on_draw()
			end
			if hided then
				table.insert(hide_list, v)
				hide_list_cnt = hide_list_cnt+1
			end
		end
	end
	for i=1, hide_list_cnt do
		self:hide(hide_list[i])
		hide_list[i] = nil
	end
end

function mt:_offscreen_draw()
	local gameinfo = fw.GameInfo
	image_c.active_rt(self.offscreen_id)
	fw.reset_screen(self.w, self.h, 1)
	ej.clear()

	self:_draw()

	image_c.active_rt()
	--	ios_bind_drawable()
	fw.reset_screen(gameinfo.width, gameinfo.height, gameinfo.scale)
	if self.drawonce then
		self.draw_call = nil
		self.sorted_sprites = {}
	end
end

function mt:show(spr, zorder, anchor)
	if self.sprites[spr] then return end

	if self.offscreen_id then anchor = nil end

	if not spr.usr_data then
		spr.usr_data = {}
	end
	spr.usr_data.render = spr.usr_data.render or {}
	local data = spr.usr_data.render
	data.zorder = zorder or 0
	data.show_order = self.show_order
	self.show_order = self.show_order + 1

	if not anchor then
		anchor = RenderManager:anchor(RenderManager.top_left)
	elseif type(anchor) ~= "table" then
		anchor = assert(RenderManager:anchor(anchor))
	end
	data.anchor = anchor

	self.sprites[spr] = true
	self.dirty = true

	if self.drawonce and self.offscreen_id then
		self.draw_call = self._offscreen_draw
	end
end

function mt:hide(spr, fade)
	if self.sprites[spr] then
		local render = spr.usr_data.render
		if fade then
			if not render.fadeout_index then
				render.fadeout_index = 1
			end
			if not self.fadeout_tween then
				self.fadeout_tween = tween.new()
				self.fadeout_tween:make(tween.type.Linear, 15, tween.wrap_mode.Once, 1, 0)
			end
		else
			render.fadeout_index = nil
			self.sprites[spr] = nil
			self.dirty = true
		end
	end
end

function mt:clear()
	self:init()
	RenderManager:remove(self)
end

function mt:count()
	return #self.sorted_sprites
end

-----------------------------------------------------------

local function sort_layer(left, right)
	if left ~= right then
		assert(left.layer~=right.layer, left.layer)
	end
	return left.layer < right.layer
end

--TODO scale
local screen_anchors = {{id=1,x=0, y=0},{id=2,x=0, y=0},{id=3,x=0, y=0},
												{id=4,x=0, y=0},{id=5,x=0, y=0},{id=6,x=0, y=0},
												{id=7,x=0, y=0},{id=8,x=0, y=0},{id=9,x=0, y=0}}
local function set_anchor(idx, x, y, scale)
	screen_anchors[idx].x = x
	screen_anchors[idx].y = y
	screen_anchors[idx].scale = scale or 1
end
function RenderManager:init(screen_width, screen_height)
	self.top_left, self.top_center, self.top_right,
	self.center_left, self.center, self.center_right,
	self.bottom_left, self.bottom_center, self.bottom_right
	= 1,2,3,
		4,5,6,
		7,8,9

	self.screen_width, self.screen_height = screen_width, screen_height
	local half_width = screen_width / 2
	local half_height = screen_height /2

	set_anchor(1, 0, 0)
	set_anchor(2, half_width, 0)
	set_anchor(3, screen_width, 0)

	set_anchor(4, 0, half_height)
	set_anchor(5, half_width, half_height)
	set_anchor(6, screen_width, half_height)

	set_anchor(7, 0, screen_height)
	set_anchor(8, half_width, screen_height)
	set_anchor(9, screen_width, screen_height)
end

function RenderManager:fixed_adapter(design_width, design_height)
	local screen_width, screen_height = self.screen_width, self.screen_height
	self.design_width, self.design_height = design_width, design_height
	local design_aspect_ratio = design_height / design_width
	local screen_aspect_ratio = screen_height / screen_width

	local dx, dy, scale = 0, 0, 1
	if screen_aspect_ratio >= design_aspect_ratio then
		-- top & bottom black
		scale = screen_width / design_width
		dy = (screen_height - scale * design_height) / 2
	else
		-- left & right black
		scale = screen_height / design_height
		dx = (screen_width - scale * design_width) / 2
	end

	set_anchor(1, 	dx, dy, scale)
	set_anchor(2, 	screen_width/2, dy, scale)
	set_anchor(3, 	screen_width-dx, dy, scale)

	set_anchor(4, 	dx, screen_height/2, scale)
	set_anchor(5, 	screen_width/2, screen_height/2, scale)
	set_anchor(6, 	screen_width-dx, screen_height/2, scale)

	set_anchor(7, 	dx, screen_height-dy, scale)
	set_anchor(8, 	screen_width/2, screen_height-dy, scale)
	set_anchor(9, 	screen_width-dx, screen_height-dy, scale)
end

function RenderManager:screen_to_world(anchor, x, y)
	local scale = anchor.scale or 1
	local wx = (x - anchor.x) / scale
	local wy = (y - anchor.y) / scale
	return wx, wy
end

function RenderManager:world_to_screen(anchor, x, y)
	local scale = anchor.scale or 1
	local sx = x * scale + anchor.x
	local sy = y * scale + anchor.y
	return sx, sy
end

function RenderManager:layout(w, h)
	local gameinfo = fw.GameInfo
	if gameinfo.width ~= w or gameinfo.height ~= h then
		self:init(w, h)
		gameinfo.width, gameinfo.height = w, h
		fw.reset_screen(w, h, gameinfo.scale)
		return true
	end
	return false
end

function RenderManager:anchor(anchor_id)
	return screen_anchors[anchor_id]
end

function RenderManager:create_offscreen(layer, w, h, name, drawonce)
	local tex_name = name..w..h
	local tex_id = texture:add_texture(tex_name)
	image_c.create_rt(tex_id, w, h)
	local rd = self:create(layer, name)
	rd:set_offscreen(tex_id, w, h, name, drawonce)
	return rd
end

function RenderManager:create(layer, name)
	local rd = setmetatable({layer=layer, name=name}, mt)
	table.insert(self.renders, rd)
	table.sort(self.renders, sort_layer)
	rd:init()
	return rd
end

function RenderManager:get(layer)
	for k, v in ipairs(self.renders) do
		if v.layer == layer then
			return v
		end
	end
end

function RenderManager:remove(rd)
	local idx=0
	local cnt = #self.renders
	for i=1, cnt do
		if self.renders[i] ~= rd then
			idx = idx + 1
			self.renders[idx] = self.renders[i]
		end
	end
	self.renders[cnt] = nil
end

function RenderManager:clear()
	self.renders = {}
end

function RenderManager:draw()
	for k, v in ipairs(self.renders) do
		if v.draw_call then
			v:draw_call()
		end
	end
end

function RenderManager:test(x, y)
	for n=#self.renders, 1, -1 do
		local v = self.renders[n]
		local sprites = v.sorted_sprites
		local cnt = #sprites
		for i=cnt, 1, -1 do
			local spr = sprites[i]
			if spr.test then
				local anchor = spr.usr_data.render.anchor
				local touched = spr:test(x, y, anchor)
				if touched then
					return touched, spr
				end
			end
		end
	end
end

function RenderManager:fade(spr, tween)
	local rd = spr.usr_data.render
	if not rd then
		rd = {}
		spr.usr_data.render = rd
	end
	rd.fade = tween
end


return RenderManager
