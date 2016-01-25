
local os_utls = require "ejoy2dx.os_utls"

local next_msg_id = 1
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
	os_utls.input(title, id, cancel_text, ok_text, default_text, style, max_len)
	return node
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
	end
	messages[id] = nil
end

return {
	on_message=on_message,
	input=input,
}
