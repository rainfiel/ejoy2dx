
local ejoy2dx = require "ejoy2dx"
local sprite = require "ejoy2d.sprite"
local spritepack = require "ejoy2d.spritepack"
local particle = require "ejoy2dx.particle"
local render = require "ejoy2dx.render"
local interpreter = require "ejoy2dx.interpreter"
local framework = require "ejoy2d.framework"
local matrix = require "ejoy2d.matrix"

--globals
------------------------------------------------------------------
package_source = {}  		-- all package res
particle_source = particle.configs
package_edit = {} 		  -- user created packages
sprite_sample = {}			-- editor created sprite
focus_sprite = nil				-- current focuse sprite
focus_memory = nil
focus_sprite_s = nil
focus_sprite_root = nil	-- the root of the focus sprite

--controller
------------------------------------------------------------------
local info_render = render:create(99998, "editor")
local info_label = sprite.label({width=400, height=24,size=16,color=0xFFcc3333, edge=1, align='l'})
info_label:ps(5, 8)
info_render:show(info_label)
info_render.is_editor = true
local info_list = {}
local function show_info(txt)
	table.insert(info_list, 1, txt)
	if #info_list > 5 then
		info_list[#info_list] = nil
	end
	info_label.text = table.concat(info_list, "\n")
end

local touch_handler = framework.EJOY2D_TOUCH
local gesture_handler = framework.EJOY2D_GESTURE
local message_handler = framework.EJOY2D_MESSAGE
local drag_target = nil
local drag_src_x = nil
local drag_src_y = nil

local function broadcast_particle(p)
	local cfg = particle:config(p)
	local mm = struct.unpack(c_schemes, "particle_config", cfg)
	if mm.get("emitterMode") == 1 then
		mm = struct.unpack(c_schemes, "particle_config", cfg, {2})
	end
	focus_memory = mm
	interpreter:broadcast({ope="particle_cfg", data=focus_memory.dump(), scheme=c_schemes["particle_config"]})
end

local function broadcast_sprite()
	local unions = {}
	local spr_type = focus_sprite.type
	if spr_type == ejoy2dx.SPRITE_TYPE_LABEL then
		unions[1] = 4
	elseif spr_type == ejoy2dx.SPRITE_TYPE_ANIMATION then
		unions[1] = 1
	elseif spr_type == ejoy2dx.SPRITE_TYPE_PICTURE then
		unions[1] = 2
	end
	focus_memory = struct.unpack(c_schemes, "sprite", focus_sprite.raw_data, unions)
	local data = focus_memory.dump()
	local unread = focus_memory.unread_data()
	if unread then
		local size = string.len(unread)
		local unit = string.packsize("L")
		if size >= unit then
			local child = table.pack(string.unpack(string.rep("L", size // unit), unread))
			child[#child] = nil
			for k, v in ipairs(child) do
				table.insert(data.data.children, v)
			end
		end
	end
	interpreter:broadcast({ope="sprite_raw", root=true, scheme=c_schemes["sprite"], data = data})
end

local function broadcast_label(bin)
	local scheme = {{name="common", body={{type="string",name="text"}}},
									{name="pack_label", body=c_schemes["pack_label"]}}

	local data = {common={text=focus_sprite.text}, pack_label=bin.dump()}
	interpreter:broadcast({ope="pack_label", data=data, scheme=scheme})
end

local function broadcast_sprite_s()
	local name, bin = table.unpack(focus_sprite.sprite_s)
	focus_sprite_s = struct.unpack(c_schemes, name, bin)
	if name == "pack_label" then
		broadcast_label(focus_sprite_s)
	elseif name == "pack_animation" then
		local unread = focus_sprite_s.unread_data()
		if unread then
			local size = string.len(unread)
			local unit = string.packsize("Ii")
			if size >= unit then
				local cnt = (size // unit) + 1
				local scheme = c_schemes[name]
				local old = scheme[#scheme].array
				scheme[#scheme].array = cnt
				focus_sprite_s = struct.unpack(c_schemes, name, bin)
				scheme[#scheme].array = old
			end
		end
		interpreter:broadcast({ope=name, scheme=c_schemes[name], data=focus_sprite_s.dump()})
	else
		interpreter:broadcast({ope=name, scheme=c_schemes[name], data=focus_sprite_s.dump()})
	end
end

local function on_select_sprite(root, spr)
	if focus_sprite_root == root and focus_sprite == spr then
		print("ignore select")
		return
	end
	focus_sprite = spr
	focus_sprite_root = root
	focus_memory = nil

	bdbox.clear()
	if not focus_sprite_root or not focus_sprite then 
		print("cancel select")
		return
	end
	bdbox.show_bd(focus_sprite_root, focus_sprite)

	local p = focus_sprite:get_particle()
	if p then
		broadcast_particle(p)
		return
	end
	
	broadcast_sprite()

	-- local sprite_type = focus_sprite.type
	-- if sprite_type == ejoy2dx.SPRITE_TYPE_LABEL then
	-- 	broadcast_label()
	-- elseif sprite_type == ejoy2dx.SPRITE_TYPE_PICTURE then
	-- 	print(".............picture")
	-- else
	-- 	broadcast_sprite()
	-- end
end

local function on_touch(x,y,what,id)
	if what == 1 then --begin
		local touched, root = render:test(x, y)
		if touched then
			drag_target = touched
			drag_src_x, drag_src_y = x, y

			on_select_sprite(root, touched)			
		end
	elseif what == 3 then --move
		if drag_target then
			drag_target:ps2(x - drag_src_x, y - drag_src_y)
			drag_src_x, drag_src_y = x, y
			bdbox.show_bd(focus_sprite_root, drag_target)
		end
	elseif what == 2 then --end
		drag_target = nil
		drag_src_x, drag_src_y = nil, nil
	end
	return true
end

local function on_gesture(what, x1, y1, x2, y2, state)
	print("gesture")
end

local function on_message(id, stat, str_data, num_data)
	if stat == "FINISH" then
	elseif stat == "CANCEL" then
	elseif stat == "KEYDOWN" then
		hotkey:on_keydown(str_data, num_data)
	elseif stat == "KEYUP" then
		hotkey:on_keyup(str_data, num_data)
	end
end

function edit_mode(on)
	if on == 1 then
		ejoy2dx.game_stat:pause()
		framework.EJOY2D_TOUCH = on_touch
		framework.EJOY2D_GESTURE = on_gesture
		framework.EJOY2D_MESSAGE = on_message
		framework.inject()
		show_info("Enter edit mode")
	else
		ejoy2dx.game_stat:resume()
		framework.EJOY2D_TOUCH = touch_handler
		framework.EJOY2D_GESTURE = gesture_handler
		framework.EJOY2D_MESSAGE = message_handler
		framework.inject()
		show_info("Leave edit mode")
	end
end

--wrapper of the env in interpreter
local src_env = env
function env(...)
	renders = {}
	for k, v in pairs(render.renders) do
		local rd={}
		for i, j in pairs(v) do
			if type(j) ~= "table" then
				rawset(rd, i, j)
			end
		end
		table.insert(renders, rd)
		local sprites = {}
		rd.sorted_sprites = sprites
		for i, j in ipairs(v.sorted_sprites) do
			local data = j.usr_data
			if data then
				table.insert(sprites, data)
			else
				table.insert(sprites, j)
			end
		end
	end
	src_env(...)
end

--scheme
------------------------------------------------------------------
c_schemes = {}
function parse_c_header(code)
	struct.parse(code, c_schemes)
end

--pack
------------------------------------------------------------------
local meta_to_source = {}

local raw_pack = spritepack.pack
local function c_pack(data)
	local meta = raw_pack(data)
	meta_to_source[meta] = data
	return meta
end
spritepack.pack = c_pack

local raw_init = spritepack.init
local function c_init(name, texture, meta)
	local ret = raw_init(name, texture, meta)
	local src = assert(meta_to_source[meta])
	assert(not package_source[name])
	package_source[name] = src
	return ret
end
spritepack.init = c_init

local sprite_id = 0
local raw_sprite = sprite.new
local function c_sprite(packname, name)
	local spr = raw_sprite(packname, name)
	sprite_id = sprite_id + 1
	spr.usr_data.edit = {packname=packname, name=name, id=sprite_id}
	return spr
end
sprite.new = c_sprite

local raw_direct_new = sprite.direct_new
local function c_direct_new(packname, id)
	local spr = raw_direct_new(packname, id)
	sprite_id = sprite_id + 1
	spr.usr_data.edit = {packname=packname, name=id, id=sprite_id}
	return spr
end
sprite.direct_new = c_direct_new

--upward
------------------------------------------------------------------
function u_del_current_sprite()
	if focus_sprite_root == focus_sprite and focus_sprite then
		info_render:hide(focus_sprite)
		info_render:resort()
		bdbox.clear()
		focus_sprite = nil
		focus_sprite_root = nil

		interpreter:broadcast({ope="delete"})
	end
end

--downward
------------------------------------------------------------------
function set_render_visible(layer, visible)
	local r = render:get(layer)
	if r then
		if visible == 0 then
			show_info("Hide render "..(r.name or layer))
			r.draw_call = nil
		else
			show_info("Show render "..(r.name or layer))
			r.draw_call = r._draw
		end
	end
end

local function get_sprite(layer, idx, ...)
	local r = render:get(layer)
	if r then
		local spr = r.sorted_sprites[idx]
		local root = spr
		if spr then
			local args = {...}
			for k, v in ipairs(args) do
				local child = spr:fetch(v)
				if not child then
					child = spr:fetch_by_index(tonumber(v))
				end
				spr = child
			end
		end
		return spr, root
	end
end
function new_sprite(packname, name)
	local spr = sprite.new(packname, name)
	info_render:show(spr, 0, render.center)
	info_render:resort()
	table.insert(sprite_sample, spr)
	sprite_sample[spr] = #sprite_sample

	on_select_sprite(spr, spr)
	env(nil, "renders")
end

function new_particle(packname, name)
	if not focus_sprite then return end
	local p = particle:new(packname, name)
	focus_sprite:set_particle(p)
end

function del_sprite(layer, idx, ...)
	local r = render:get(layer)
	if r then
		local spr = get_sprite(layer, idx, ...)
		if spr then
			r:hide(spr)
			r:resort()
			bdbox.clear()
			env(nil, "renders")

			focus_sprite = nil
			focus_sprite_root = nil
		end
	end
end

function set_sprite_visible(layer, idx, visible)
	local r = render:get(layer)
	if r then
		local spr = r.sorted_sprites[idx]
		if spr then
			local data = spr.usr_data.render
			if visible == 0 then
				show_info("Hide sprite")
				data.old_blend_mode = data.blend_mode
				data.blend_mode = "hide"
			else
				show_info("Show sprite")
				data.blend_mode = data.old_blend_mode
			end
		end
	end
end

function toggle_child_visible(layer, idx, ...)
	local spr = get_sprite(layer, idx, ...)
	spr.visible = not spr.visible
end

function select_sprite(layer, idx, ...)
	local spr, root = get_sprite(layer, idx, ...)
	on_select_sprite(root, spr)
end

function move_to_render(tar_layer, layer, idx, ...)
	local spr = get_sprite(layer, idx, ...)
	if spr then
		local old_r = render:get(layer)
		local r = render:get(tar_layer)
		if r and old_r then
			old_r:hide(spr)
			old_r:resort()
			r:show(spr, 0, render.center)
			r:resort()
			env(nil, "renders")
		end
	end
end

function set_particle_attr(key, val)
	local p = focus_sprite:get_particle()
	if p then
		if type(key) == "table" then
			for k, v in ipairs(key) do
				focus_memory.set(v, val[k])
			end
		else
			focus_memory.set(key, val)
		end

		particle:config(p, focus_memory.pack())

		if key == "emitterMode" then
			broadcast_particle(p)
		end
	end
end

function set_label_attr(key, val)
	if key == "common.text" then
		focus_sprite.text = val
	else
		focus_sprite_s.set(string.sub(key, 12), val)
		focus_sprite.sprite_s = focus_sprite_s.pack()
	end
end

function set_sprite_attr(key, val)
	focus_memory.set(key, val)
	focus_sprite.raw_data = focus_memory.pack()
end

function get_sprite_s()
	broadcast_sprite_s()
end

function set_sprite_s(key, val)
	focus_sprite_s.set(key, val)
	focus_sprite.sprite_s = focus_sprite_s.pack()
end

function sprite_children(arg)
	local spr = focus_sprite:fetch_by_index(arg)
	on_select_sprite(focus_sprite_root, spr)
end

function sprite_parent()
	local spr = focus_sprite.parent
	if spr then
		on_select_sprite(spr, spr)
	end
end