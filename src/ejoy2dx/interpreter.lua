
local _SYS_ENV = _ENV
local _MY_ENV = {}
local _ENV = setmetatable(_MY_ENV, {__index=_SYS_ENV})

local lsocket = require "ejoy2dx.socket.c"
local json = require "ejoy2dx.json"
local crypt = require "ejoy2dx.crypt.c"

local conn_mt = {}
conn_mt.__index = conn_mt

local help_tbl = {
	print="print(...), eval a print statement just as lua",
	env="env(level), fetch serialized env table and display it in Namespace, table that out of level will not be serialized, the default level=3",
	clear_env="clear_env(), clear env table of this connection",
	disconnect="disconnect(), close the current connection",	
	help="help(), refresh help info",
}
local help_txt = json:encode(help_tbl)

function conn_mt:init()
	local function rmt_print(...)
		local args = {...}
		local str = {}
		for _,v in ipairs(args) do
			table.insert(str, tostring(v))
		end
		str = table.concat(str, "\t")
		table.insert(self.results, str)
	end
	local function dump_env(layer)
		self:dump_env(layer or 3)
	end
	local function clear_env()
		self.env = setmetatable(self.origin_env(), {__index=_SYS_ENV})
		self:dump_env(3)
	end
	local function disconnect()
		self.disconnected = true
		self:send("disconnect")
		self.results = nil
	end
	local function help()
		self:send("help", help_txt)
		self.results = nil
	end
	self.origin_env = function( ... )
		return {print=rmt_print, env=dump_env, clear_env=clear_env, disconnect=disconnect, help=help}
	end
	self.env = setmetatable(self.origin_env(), {__index=_SYS_ENV})
end

function conn_mt:recv()
	if self.disconnected then return false end

	local msg, err = self.conn:recv()
	if msg then
		self:parse(msg)
		print(string.format("INTERPRETER:%s>>>%q", self.id, msg))
	elseif msg == nil then
		if err then
			print("INTERPRETER:conn recv error->", self.id, " ", err)
		else
			print("INTERPRETER:conn closed->", self.id)
		end
		return false
	end
	return true
end

function conn_mt:do_send(txt)
	local n = #txt
	local wt = self.conn:send(txt)
	if not wt or wt < n then
		lsocket.select(nil, {self.conn})
		wt = wt or 0
		n = n - wt
	end
	if wt < n then
		txt = txt:sub(wt+1)
		wt = self.conn:send(txt)
		if not wt or wt < n then
			return txt:sub((wt or 0) + 1)
		end
	end
end

function conn_mt:send(type, msg)
	local txt = json:encode({type=type,msg=msg})
	if self.send_buffer then
		self.send_buffer = self.send_buffer..txt
	else
		self.send_buffer = self:do_send(txt)
	end
end

function conn_mt:update()
	if not self:recv() then 
		return false
	end
	if self.send_buffer then
		self.send_buffer = self:do_send(self.send_buffer)
	end
	return true
end

function conn_mt:result(ok, ...)
	local ret = {...}
	if not ok then
		self:send("error", ret[1] or "run error")
		return
	end
	if not self.results then return end

	if #ret > 0 then
		local str = {}
		for _,v in ipairs(ret) do
			table.insert(str, tostring(v))
		end
		str = table.concat(str, "\t")
		table.insert(self.results, str)
	end
	self:send("result", table.concat(self.results, "\n"))
	self.results = nil
end

function conn_mt:parse(msg)
	self.results = {}
	local is_func = string.match(msg, "^ *(%g+) *[(] *[)] *$")
	if is_func then
		msg = "return "..msg
	end
	local chunk, err = load(msg, self.id, "t", self.env)
	if chunk then
		self:result(pcall(chunk))
	else
		self:send("error", err or "load error")
	end
end

local function iter_tbl(tbl, ref)
	local ret = {}
	for k, v in pairs(tbl) do
		local key = tostring(k)
		if type(v) == "table" then
			if ref[v] then
				ret[key] = "ref_"..tostring(ref[v])
			else
				ref[v] = k
				ret[key] = iter_tbl(v, ref)
			end
		else
			ret[key] = tostring(v)
		end
	end
	return ret
end

local function dump_tbl(tbl, layer)
	local ret = {}
	for k, v in pairs(tbl) do
		local key = tostring(k)
		if layer > 0 and type(v) == "table" then
			ret[key] = dump_tbl(v, layer-1)
		else
			local str = tostring(v)
			local len = utf8.len(str)
			if not len then
				str = crypt.base64encode(str)
				if string.len(str) > 10 * 1024 then
					str = string.sub(str, 1, 10 * 1024)
				end
			end
			ret[key] = str
		end
	end
	return ret
end

function conn_mt:dump_env(layer)
	-- local ref = {}
	-- ref[self.env] = "env"
	-- local tbl = iter_tbl(self.env, ref)
	local tbl = dump_tbl(self.env, layer)
	local txt = json:encode(tbl)
	self:send("env", txt)
	self.results = nil
end

----------------------------------------------------------

local function local_ip()
	local interfaces = lsocket.getinterfaces()
	if not interfaces then return end
	for _, v in ipairs(interfaces) do
		--TODO LAN ip
		if v.family == "inet" and (v.name=="en0" or v.name=="Local Area Connection") then
			return v.addr
		end
	end
end

local M = {}

function M:run(port)
	local ip = local_ip()
	if not ip then 
		print("INTERPRETER: run failed, no ip")
		return
	end
	local socket, err = lsocket.bind("tcp", ip, port)
	if err then
		print("INTERPRETER: run failed->", err)
	else
		print("INTERPRETER: running on "..ip..":"..port)
		self.ip = ip
		self.port = port
		self.socket = socket
		self.connects = {}
	end
end

local closed_conn = {}
local closed_count = 0
function M:update()
	if not self.socket then return end
	for k in next, self.connects do
		if not self.connects[k]:update() then
			self.connects[k] = nil
		end
	end

	local conn, ip, port = self.socket:accept()
	if conn then
		print(string.format("INTERPRETER:new connection from %s:%s", ip, port))
		local id = string.format("%s:%s", ip, port)
		assert(not self.connects[id], id)
		conn = setmetatable({conn=conn, ip=ip, port=port, id=id}, conn_mt)
		conn:init()
		self.connects[id] = conn
	end
	if conn == nil and ip then
		print("INTERPRETER: accept err->"..ip)
	end
end

return M
