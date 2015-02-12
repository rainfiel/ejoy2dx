

local RenderManager = {}
RenderManager.renders = {}


local mt = {}
mt.__index = mt

function mt:init()
	self.sprites = {}
	self.sorted_sprites = {}
	self.sprite_count = 0
	self.dirty = false
end

local function sort_order(left, right)
	return left.usr_data.render.zorder < right.usr_data.render.zorder
end

function mt:_draw()
	if self.dirty then
		self.dirty = false

		local old_cnt = #self.sprites
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

	for k, v in ipairs(self.sorted_sprites) do
		v:draw(v.usr_data.render.anchor)
	end
end

function mt:show(spr, zorder, anchor)
	spr.usr_data.render = spr.usr_data.render or {}
	local data = spr.usr_data.render
	data.zorder = zorder or 0
	anchor = anchor or RenderManager.top_left
	data.anchor = assert(RenderManager:anchor(anchor))
	assert(not self.sprites[spr])
	self.sprites[spr] = true
	self.sprite_count = self.sprite_count + 1
	self.dirty = true
end

function mt:hide(spr)
	if self.sprites[spr] then
		self.sprites[spr] = nil
		self.dirty = true
		self.sprite_count = self.sprite_count + 1
	end
end

function mt:dump()
	for k, v in ipairs(self.sprites) do
		print(k..":"..v.usr_data.render.zorder)
	end
end

-----------------------------------------------------------

local function sort_layer(left, right)
	return left.layer < right.layer
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
	self.anchors = {{x=0, y=0},{x=half_width, y=0},{x=screen_width, y=0},
									{x=0, y=half_height},{x=half_width, y=half_height},{x=screen_width, y=half_height},
									{x=0, y=screen_height},{x=half_width, y=screen_height},{x=screen_width, y=screen_height}}
end

function RenderManager:anchor(anchor_id)
	return self.anchors[anchor_id]
end

function RenderManager:create(layer)
	local rd = setmetatable({layer=layer}, mt)
	table.insert(self.renders, rd)
	table.sort(self.renders, sort_layer)
	rd:init()
	return rd
end

function RenderManager:draw()
	for k, v in ipairs(self.renders) do
		v:_draw()
	end
end


return RenderManager
