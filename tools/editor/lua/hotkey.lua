
local msg_mt = {}
msg_mt.__index = msg_mt

local function is_bit_set(val, bit_idx)
	return val & (1 << bit_idx) ~= 0
end

local function is_repeat(param)
	return is_bit_set(param, 30)
end

function msg_mt:on_keydown(char, param)
	print(".........:", char, tonumber(char))
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
--------------------------------------------------

local handlers = {down={}, up={}}

handlers.down[" "] = function(char, is_repeat)
	-- if is_repeat then return end
end

handlers.up[" "] = function(char)
end

local joystick = {D=0, S=90, A=180, W=270}
local pressed = {}
local function do_joystick()
	if #pressed == 0 then
		-- war.ticket_to_joystick_stop()
	elseif #pressed == 1 then
		-- war.ticket_to_joystick(pressed[1])
	else
		local dir1 = pressed[#pressed]
		local dir2 = pressed[#pressed-1]
		local dir = math.abs(dir1 - dir2) / 2
		local new_dir = math.min(dir1, dir2) + dir
		if dir > 90 then
			dir = 45
			new_dir = math.max(dir1, dir2) + dir
		end
		if dir == 90 then
			-- war.ticket_to_joystick_stop()
		else
			-- war.ticket_to_joystick(new_dir)
		end
	end
end
local function on_joystick_on(char, is_repeat)
	if is_repeat then return end

	local dir = joystick[char]
	table.insert(pressed, dir)
	do_joystick()
end

local function on_joystick_off(char)
	local dir = joystick[char]
	local tmp = {}
	for k, v in ipairs(pressed) do
		if v ~= dir then
			table.insert(tmp, v)
		end
	end
	pressed = tmp
	do_joystick()
end

local function init()
	for k, v in pairs(joystick) do
		handlers.down[k] = on_joystick_on
		handlers.up[k] = on_joystick_off
	end
	return setmetatable({retain=true, handlers=handlers}, msg_mt)
end

hotkey=init()