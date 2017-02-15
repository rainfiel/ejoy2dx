
local keymap = require "ejoy2dx.keymap"
local os_utls = require "ejoy2dx.os_utls"

local msg_mt = {}
msg_mt.__index = msg_mt

local function is_bit_set(val, bit_idx)
	return val & (1 << bit_idx) ~= 0
end

local function is_repeat(param)
	return is_bit_set(param, 30)
end

local function char_to_vk(char)
	local vk = string.unpack("B", char)
	return keymap[vk]
end

function msg_mt:on_keydown(char, param)
	local vk = char_to_vk(char)
	if not vk then return end

	local handler = self.handlers.down[vk]
	if handler then
		handler(vk, is_repeat(param))
	end
end

function msg_mt:on_keyup(char, param)
	local vk = char_to_vk(char)
	if not vk then return end

	local handler = self.handlers.up[vk]
	if handler then
		handler(vk)
	end
end
--------------------------------------------------

local handlers = {down={}, up={}}

-- handlers.down[keymap.VK_SPACE] = function(char, is_repeat)
-- 	-- if is_repeat then return end
-- end

-- handlers.up[keymap.VK_SPACE] = function(char)
-- end

handlers.down[keymap.VK_DELETE] = function(char, is_repeat)
	if is_repeat then return end
	u_del_current_sprite()
end

local joystick = {[keymap.VK_D]=0, [keymap.VK_S]=90, [keymap.VK_A]=180, [keymap.VK_W]=270,
									[keymap.VK_RIGHT]=0, [keymap.VK_DOWN]=90, [keymap.VK_LEFT]=180, [keymap.VK_UP]=270,}
local pressed = {}

local function move_target(dir)
	if not focus_sprite then return end
	local rad = math.rad(dir)
	local sin = math.sin(rad)
	local cos = math.cos(rad)

	--shift
	local dist = os_utls.is_key_down(0x10) and 10 or 1
	focus_sprite:ps2(cos*dist, sin*dist)
	bdbox.show_bd(focus_sprite_root, focus_sprite)
end

local function do_joystick()
	if #pressed == 0 then
	elseif #pressed == 1 then
		move_target(pressed[1])
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
		else
			move_target(new_dir)
		end
	end
end

local function on_joystick_on(char, is_repeat)
	local dir = joystick[char]
	for k, v in ipairs(pressed) do
		if v == dir then
			do_joystick()
			return
		end
	end
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