
local utls = require "ejoy2dx.utls"
local c = require "ejoy2d.particle.c"

local M = {configs={}}

function M:preload(name, path)
	local cfg = utls.read_file(path)
	self.configs[name] = load(cfg, "particle", "t", {})()
end

function M:new(packname, name)
	local pack = self.configs[packname]
	assert(pack, packname)
	local cfg = pack[name]
	assert(cfg, packname.."."..name)
	local p = c.new(cfg)
	c.reset(p)
	return p
end

return M