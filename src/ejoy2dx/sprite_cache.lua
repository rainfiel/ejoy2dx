
local sprite = require "ejoy2d.sprite"

local M = {cache={}}

function M:active()
	sprite.sprite_mt.__gc = function(...)
		self:sprite_gc(...)
	end

	-- self.counts = {}
	self.sprite_new = sprite.new
	sprite.new = function(packname, name)
		local __id = packname..name

		-- self.counts[__id] = self.counts[__id] or {}
		-- self.counts[__id][1] = (self.counts[__id][1] or 0) + 1

		local spr = self:fetch(__id)
		if spr then 
			return spr 
		end

		-- self.counts[__id][2] = (self.counts[__id][2] or 0) + 1

		spr = self.sprite_new(packname, name)
		spr.usr_data.__id = __id
		return spr
	end

	-- self.sprite_direct_new = sprite.direct_new
	-- sprite.direct_new = function(packname, id)
	-- 	local __id = packname..tostring(id)
	-- 	local spr = self:fetch(__id)
	-- 	if spr then return spr end
		
	-- 	spr = self.sprite_direct_new(packname, id)
	-- 	spr.usr_data.__id = __id
	-- 	return spr
	-- end
end

function M:deactive()
	sprite.sprite_mt.__gc = nil
	sprite.new = self.sprite_new
	-- sprite.direct_new = self.sprite_direct_new
end

function M:summary()
	local sum = {}
	for k, v in pairs(self.counts) do
		table.insert(sum, {k, v[2]/v[1], string.format("total:%d miss: %d gc: %d", v[1], v[2], v[3] or 0)})
	end
	table.sort(sum, function(a, b)
		return a[2] > b[2]
	end)
	return sum
end

function M:sprite_gc(spr)
	local id = spr.usr_data.__id
	if not id then return end
	if not self.cache[id] then self.cache[id] = {} end

	-- if self.counts[id] then
	-- 	self.counts[id][3] = (self.counts[id][3] or 0)+1
	-- end

	table.insert(self.cache[id], spr)
end

function M:fetch(id)
	local all = self.cache[id]
	if not all or #all == 0 then return end
	local spr = table.remove(all, #all)

	sprite.reset(spr)

	local usr_data = spr.usr_data
	for k in next, usr_data do rawset(usr_data, k, nil) end
	usr_data.__id = id

	-- print("-----------reuse:",#all, id)

	return spr
end

return M