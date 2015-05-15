
local fw = require "ejoy2d.framework"
local blend = require "ejoy2dx.blend"

local RenderManager = {}
RenderManager.renders = {}


local mt = {}
mt.__index = mt

function mt:init()
	self.sprites = {}
	self.sorted_sprites = {}
	self.dirty = false
end

local function sort_order(left, right)
	return left.usr_data.render.zorder < right.usr_data.render.zorder
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

function mt:test(x, y)
	local sprites = self.sorted_sprites
	local cnt = #sprites
	for i=cnt, 1, -1 do
		local spr = sprites[i]
		if spr.test then
			local usr_data = spr.usr_data
			local callback = usr_data.touch_callback
			if callback then
				local anchor = spr.usr_data.render.anchor
				local touched = spr:test(x, y, anchor)
				if touched then
					if anchor.id then
						return callback, touched, anchor.id, RenderManager:screen_to_world(anchor, x, y)
					else
						return callback, touched
					end
				end
			end
		end
	end
end

function mt:_draw()
	self:resort()

	local render
	for k, v in ipairs(self.sorted_sprites) do
		render = v.usr_data.render
		if render.blend_mode then
			if blend.begin_blend(render.blend_mode) then
				v:draw(render.anchor)
				blend.end_blend()
			end
		else
			v:draw(render.anchor)
		end
		if render.on_draw then
			render.on_draw()
		end
	end
end

function mt:show(spr, zorder, anchor)
	if self.sprites[spr] then return end

	if not spr.usr_data then
		spr.usr_data = {}
	end
	spr.usr_data.render = spr.usr_data.render or {}
	local data = spr.usr_data.render
	data.zorder = zorder or 0

	if not anchor then
		anchor = RenderManager:anchor(RenderManager.top_left)
	elseif type(anchor) ~= "table" then
		anchor = assert(RenderManager:anchor(anchor))
	end
	data.anchor = anchor

	self.sprites[spr] = true
	self.dirty = true
end

function mt:hide(spr)
	if self.sprites[spr] then
		self.sprites[spr] = nil
		self.dirty = true
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
	return left.layer < right.layer
end

--TODO scale
local screen_anchors = {{id=1,x=0, y=0},{id=2,x=0, y=0},{id=3,x=0, y=0},
												{id=4,x=0, y=0},{id=5,x=0, y=0},{id=6,x=0, y=0},
												{id=7,x=0, y=0},{id=8,x=0, y=0},{id=9,x=0, y=0}}
local function set_anchor(idx, x, y)
	screen_anchors[idx].x = x
	screen_anchors[idx].y = y
end
function RenderManager:init(screen_width, screen_height)
	self.top_left, self.top_center, self.top_right,
	self.center_left, self.center, self.center_right,
	self.bottom_left, self.bottom_center, self.bottom_right
	= 1,2,3,
		4,5,6,
		7,8,9
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

function RenderManager:create(layer)
	local rd = setmetatable({layer=layer}, mt)
	table.insert(self.renders, rd)
	table.sort(self.renders, sort_layer)
	rd:init()
	return rd
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
		v:_draw()
	end
end


return RenderManager
