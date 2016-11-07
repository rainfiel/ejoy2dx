
local os_utls = require "ejoy2dx.os_utls"

------------------------------------------------------------
--keydown and keyup
local char_msg_node = nil
local msg_mt = {}
msg_mt.__index = msg_mt

local function is_bit_set(val, bit_idx)
	return val & (1 << bit_idx) ~= 0
end

local function is_repeat(param)
	return is_bit_set(param, 30)
end

function msg_mt:on_keydown(char, param)
	local handler = self.handlers.down[char]
	if handler then
		handler(char, is_repeat(param))
	end
end

function msg_mt:on_keyup(char, param)
	local handler = self.handlers.up[char]
	if handler then
		handler(char)
	end
end
------------------------------------------------------------

local next_msg_id = 1
local char_msg_id = -1
local messages = {}

local function add_message()
	local id = next_msg_id
	next_msg_id = next_msg_id + 1

	local node = {}
	messages[id] = node
	return id, node
end

local function input(title, ok_text, cancel_text, default_text, style, max_len)
	if not os_utls.input then return end

	local id, node = add_message()
	if os_utls.input(title, id, cancel_text, ok_text, default_text, style, max_len) then
		return node
	end
end

local function char(handlers)
	assert(not messages[char_msg_id], "only one char message pls")

	if char_msg_node then return end
	char_msg_node = {retain=true, handlers=handlers}
	setmetatable(char_msg_node, msg_mt)
	messages[char_msg_id] = char_msg_node
end

local function on_message(id, stat, str_data, num_data)
	local node = messages[id]
	if not node then return end
	if stat == "FINISH" then
		if node.on_finish then
			node.on_finish(str_data, num_data)
		end
	elseif stat == "CANCEL" then
		if node.on_cancel then
			node.on_cancel(str_data, num_data)
		end
	elseif stat == "KEYDOWN" then
		print("..........:", str_data)
		if node.on_keydown then
			node:on_keydown(str_data, num_data)
		end
	elseif stat == "KEYUP" then
		if node.on_keyup then
			node:on_keyup(str_data, num_data)
		end
	end
	if not node.retain then
		messages[id] = nil
	end
end

return {
	on_message=on_message,
	input=input,
	char=char,
}
