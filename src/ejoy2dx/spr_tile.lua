
local spritepack = require "ejoy2d.spritepack"

local mt = {}
mt.__index = mt

function mt:init()
	self.row = self.w // self.tile_w
	self.row_tail = self.w % self.tile_w
	if self.row_tail ~= 0 then
		self.row = self.row + 1
	end

	self.col = self.h // self.tile_h
	self.col_tail = self.h % self.tile_h
	if self.col_tail ~= 0 then
		self.col = self.col + 1
	end

	self.x, self.y = self.w / 2, self.h / 2

	pack = {}
	for i=1, self.col do
		local h = (i==self.col and self.col_tail ~= 0) and self.col_tail or self.tile_h
		for j=1, self.row do
			local w = (j==self.row and self.row_tail ~= 0) and self.row_tail or self.tile_w
			local src = { (j-1)*self.tile_w,(i-1)*self.tile_h,  
									  (j-1)*self.tile_w,(i-1)*self.tile_h+h,
									  (j-1)*self.tile_w+w,(i-1)*self.tile_h+h,
									  (j-1)*self.tile_w+w,(i-1)*self.tile_h}
			local x = 16 * (-self.x + (j-1) * self.tile_w + w / 2)
			local y = -16 * (-self.y + (i-1) * self.tile_h + h / 2) --flip y
			local screen = {-self.tile_w*0.5*16+x, -self.tile_h*0.5*16+y,
											-self.tile_w*0.5*16+x, self.tile_h*0.5*16+y,
											self.tile_w*0.5*16+x, self.tile_h*0.5*16+y,
											self.tile_w*0.5*16+x, -self.tile_h*0.5*16+y}
			--flip y
			screen[2], screen[4] = screen[4], screen[2]
			screen[6], screen[8] = screen[8], screen[6]
			local p = {type="picture", id=#pack, {tex=1, src=src, screen=screen}}
			table.insert(pack, p)
		end
	end

	local comp = {}
	local frame = {{}}
	for i=1, #pack do
		table.insert(comp, {id=i-1})
		table.insert(frame[1], #comp-1)
	end
	local ani = {
		component = comp,
		export = "root",
		type = "animation",
		id = #pack,
		frame
	}
	table.insert(pack, ani)

	local p = spritepack.pack(pack)
	spritepack.init(self.name, {self.tex_id}, p)
end

function mt:get_tile(x, y)
	y = self.h - y
	local r = math.ceil(math.abs(x) / self.tile_w)
	local c = math.ceil(math.abs(y) / self.tile_h)
	return (c-1) * self.row + r - 1, c, r
end

function mt:cull(x, y, spr)
	for i=1, self.col do
		for j=1, self.row do
			local idx = (i-1)*self.row + j - 1
			local tile = spr:fetch_by_index(idx)
			if tile then
				if math.abs(x-i) <=3 and math.abs(y-j)<=5 then
					tile.visible = true
				else
					tile.visible = false
				end
			end
		end
	end
end


return function(name, tex_id, w, h, tile_w, tile_h)
	local data = {name=name, tex_id=tex_id, tile_w=tile_w, tile_h=tile_h, w=w, h=h}
	local t = setmetatable(data, mt)
	t:init()
	return t
end