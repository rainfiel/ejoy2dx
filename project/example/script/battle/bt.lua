
local utls = require "ejoy2dx.utls"
local BTLua = require "BTLua.BTLua"

local mt = {}
mt.__index = mt

function mt:init(path, name, my_obj)
	local tbl = utls.load_json(path)
	assert(tbl)
	self.bt = BTLua.BTree:new(name, my_obj, nil, nil, nil)
	self.bt:parseTable(nil, tbl, nil)
end

function mt:run()
	self.bt:run()
end

local M = {}

function M.getter(mt, self, key)
	local ret = rawget(mt, key)
	if ret then return ret end
	ret = rawget(self, key)
	if ret then return ret end
	local parent = rawget(self, "parent")
	if parent then
		ret = rawget(parent, key)
		if ret then return ret end
	end
	assert("__index key err:", key)
end

function M:new_bt(path, name, my_obj)
	local bt = setmetatable({}, mt)
	local creator = require("battle."..name)
	bt:init(path, name, creator(my_obj))
	return bt
end

return M