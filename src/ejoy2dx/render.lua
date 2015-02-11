

local RenderManager = {}
RenderManager.renders = {}


local mt = {}
mt.__index = mt

function mt:init()
	self.sprites = {}
end

function mt:_draw()
	for k, v in ipairs(self.sprites) do
		v:draw(RenderManager:anchor(v.usr_data.render.anchor))
	end
end

local function sort_order(left, right)
	return left.usr_data.render.zorder < right.usr_data.render.zorder
end

--OPT: batch add
function mt:show(spr)
	spr.usr_data.render = spr.usr_data.render or {}
	local data = spr.usr_data.render
	data.zorder = data.zorder or 0
	data.anchor = data.anchor or RenderManager.top_left  --default top_left
	table.insert(self.sprites, spr)
	table.sort(self.sprites, sort_order)
end

function mt:hide(spr)
	local data = spr.usr_data.render
	if not data or not data.zorder then
		return
	end
	local idx = 0
	local cnt = #self.sprites
	for i=1, cnt do
		if self.sprites[i] ~= spr then
			idx = idx + 1
			self.sprites[idx] = self.sprites[i]
		end
	end
	assert(idx == cnt-1)
	self.sprites[cnt] = nil
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
