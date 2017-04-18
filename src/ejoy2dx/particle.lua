
local utls = require "ejoy2dx.utls"
local c = require "ejoy2d.particle.c"

local M = {configs={}}

function M:preload(name, path)
	local cfg = utls.read_file(path)
	self.configs[name] = load(cfg, "particle", "t", {})()
end

local function get_cfg(packname, name)
	local pack = M.configs[packname]
	assert(pack, packname)
	local cfg = pack[name]
	assert(cfg, packname.."."..name)
	return cfg
end

function M:new(packname, name)
	local cfg = get_cfg(packname, name)
	local p = c.new(cfg)
	c.reset(p)

	local usr_data = c.usr_data(p)
	usr_data.packname = packname
	usr_data.name = name
	return p
end

function M:config(p, cfg)
	return c.config(p, cfg)
end

function M:active(p, act)
	if act then
		c.reset(p)
	else
		c.deactive(p)
	end
end

function M:get_para(p)
	local usr_data = c.usr_data(p)
	if not usr_data.cfg then
		local new_cfg = {}
		local cfg = get_cfg(usr_data.packname, usr_data.name)
		for k, v in pairs(cfg) do
			rawset(new_cfg, k, v)
		end
		usr_data.cfg = new_cfg
	end
	return usr_data.cfg
end

function M:update_para(p, att_name, att_val)
	local cfg = self:get_para(p)
	local att_type = type(att_name)
	if att_type == "table" then
		for k, v in pairs(att_name) do
			cfg[k] = v
		end
	elseif att_type == "string" then
		cfg[att_name] = att_val
	else
		error("particle update_para arg error:"..tostring(att_name))
	end

	c.reset(p, cfg)
end

return M