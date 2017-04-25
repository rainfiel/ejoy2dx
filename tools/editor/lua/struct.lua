local assert, pairs, tostring, type = assert, pairs, tostring, type
local ipairs = ipairs
local setmetatable = setmetatable
local print = print
----------------------------------------------------------
local math = require 'math'
local table = require 'table'
local string = require 'string'
local io = require 'io'
----------------------------------------------------------

local m = require("ejoy2dx.lpeg.c")
----------------------------------------------------------
local format = string.format
local P, V, R, S, C = m.P, m.V, m.R, m.S, m.C
----------------------------------------------------------

local inst = {pointer_fmt = "L"} --L for 64bit and I for 32bit

-- local MAXINTSIZE = 16 --maximum size for the binary representation of an integer(see lstrlib.c)
local SS = c99.SS
c99.typedefs.bool = "b"

local pack_conversion = {
	char="b",
	unsigned_char="B",
	signed_char="b",
	int="i",
	unsigned_int="I",
	signed_int="i",
	short="H",
	unsigned_short="H",
	signed_short="h",
	long="L",
	unsigned_long="L",
	signed_long="l",
	float="f",
	double="d",
	bool="b",
}

local function type_to_fmt(type_name)
	-- local name = type_name:match("[struct] ([%a%d_]+)")
	-- if name then
	-- 	return c99.typedefs[name]
	-- end
	
	local t = pack_conversion[type_name]
	if not t then
		t = c99.typedefs[type_name]
		if type(t) == "table" then
			if t.fmt then
				t = t.fmt
			elseif t[1] then
				return type_to_fmt(t[1])
			end
		end
	end
	if not t then
		t = string.gsub(type_name, " ", "_")
		t = pack_conversion[t]
	end
	return t
end

local function declarator_fmt(dec)
	local fmt
	if dec.is_pointer then
		fmt = inst.pointer_fmt
	else
		fmt = type_to_fmt(dec.type)
	end

	-- if fmt and dec.array then
	-- 	fmt = string.rep(fmt, dec.array)
	-- end
	return fmt
end

local function struct_declarations(code, structs)
	-- print("code:", code)
	local rules = ceg.combine({
			[1] = V"followed",
			followed = V"anony_struct_or_union" + V"specifier_qualifier_list" * c99.SS * V"struct_declarator_list" * c99.SS * V";",
			specifier_qualifier_list = C(c99.specifier_qualifier_list),
			struct_declarator_list = C(c99.struct_declarator_list),
			anony_struct_or_union = C(c99.anony_struct_or_union),
			start_anony_struct_or_union = C(c99.start_anony_struct_or_union),
		}, 
		{
			comment = c99.comment,
		},
		c99.all_rules
	)
	
	local members = {}
	local last_type = nil
	-- local is_union = nil
	local last_identifier = nil
	local anony_stack = {}


	local captures = {
		identifier = function(v)
			last_identifier = v
			return v
		end,
		start_anony_struct_or_union = function(v)
			-- is_union = nil
			-- if string.find(v, "union") then
			-- 	is_union = true
			-- end
			table.insert(anony_stack, {})
			return v
		end,
		anony_struct_or_union = function(v)
			local is_union = nil
			if string.find(v, "union") then
				is_union = true
			end

			anony = table.remove(anony_stack)
			parent = anony_stack[#anony_stack] or members

			local data = {type="anony", name=last_identifier, is_union=is_union, body=anony}
			table.insert(parent, data)

			return v
		end,
		specifier_qualifier_list = function(v)
			last_type = v
			return v
		end,
		struct_declarator_list = function(v)
			name = v
			is_pointer = nil
			if string.sub(v, 1, 1) == "*" then
				is_pointer = true
				name = string.gsub(name, "[ ]*[*][ ]*", "")
			end
			local a, array = name:match("([%a%d_]+)[ ]*[[][ ]*(%d+)[ ]*[]]")
			if a and array then
				name = a
				array = tonumber(array)
			end

			current = anony_stack[#anony_stack] or members
			assert(not current[name], name..":"..last_type)
			local data = {name=name, type=last_type, is_pointer=is_pointer, array=array}

			local struct_name = last_type:match("[struct] ([%a%d_]+)")
			if not is_pointer and struct_name then
				data.body = assert(structs[struct_name], struct_name)
				data.type = struct_name
			end

			data.fmt = declarator_fmt(data)

			table.insert(current, data)
			-- print("-->", #anony_stack, last_type, ":", name)
			last_type = nil
			return v
		end,

		followed = function(block)
			return block
		end,
	}

	local patt = ceg.scan(ceg.apply(rules, captures))
	local res = {patt:match(code)}

	return members
end

local function struct_pack(struct)
	local fmt = ""
	for k, v in ipairs(struct) do
		local t
		if v.type == "anony" then
			if v.is_union then
				local fmt
				local max_size
				for m, n in ipairs(v.body) do
					local tmp = struct_pack({n})
					local packsize = string.packsize(tmp)
					if not max_size or packsize > max_size then
						max_size = packsize
						fmt=tmp
					end
				end
				t = fmt
			else
				t = struct_pack(v.body)
			end
		elseif v.is_pointer then
			t = inst.pointer_fmt
		elseif v.body then
			t = struct_pack(v.body)
		else
			t = type_to_fmt(v.type)
		end
		t = t or "?"

		-- if t and v.array then
		-- 	t = string.rep(t, v.array)
		-- end
		fmt = fmt..(t or "?")
	end
	assert(fmt~="")
	return fmt
end

local function struct_block(code, structs)
	local rules = ceg.combine({
			[1] = V"followed",
			followed = V"struct_or_union_definition",
			struct_or_union_definition = C(c99.struct_or_union_definition)
		}, 
		{
			comment = c99.comment,
		},
		c99.all_rules
	)

	structs = structs or {}
	local captures = {
		struct_or_union_definition = function(v)
			return v
		end,

		followed = function(block)
			local name = block:match("[struct] ([%a%d_]+)")
			declarations = struct_declarations(block, structs)
			assert(not structs[name], name)
			structs[name] = declarations
			c99.typedefs[name] = struct_pack(declarations)
			return block
		end,
	}

	local patt = ceg.scan(ceg.apply(rules, captures))
	patt:match(code)

	-- structs.types = c99.typedefs
	return structs
end


local function types_to_fmt(types)
	local key = table.concat(types, "_")
	local fmt = pack_conversion[key]
	if fmt then
		return {types=types, fmt=fmt}
	else
		return types
	end
end

local function typedefs(code, rematch)
	local rules = ceg.combine({
			[1] = V"followed",
			followed = V"typedef_declarator",
			typedef_declarator = C(c99.typedef_declarator)
		}, 
		{
			comment = c99.comment,
		},
		c99.all_rules
	)
	
	last_type = {}
	local captures = {
		type_specifier = function(v)
			-- if rematch then
			-- 	print("....:", v)
			-- end
			table.insert(last_type, v)
			return v
		end,
		typeddef_identitifer = function(v)
			if #last_type == 0 then return end
			-- if rematch and c99.typedefs[v] then 
			-- 	print("...ignore:", v, last_type[1])
			-- 	last_type = {}
			-- 	return 
			-- end
			-- print("name:", v, table.concat(last_type, "+"))
			c99.typedefs[v] = types_to_fmt(last_type)
			last_type = {}
			return v
		end,

		followed = function(block)
			return block
		end,
	}

	c99.unknown_types = {}
	local patt = ceg.scan(ceg.apply(rules, captures))
	local res = {patt:match(code)}

	for k, v in ipairs(c99.unknown_types) do
		if c99.typedefs[v] then
			return typedefs(code, true)
		end
	end

	c99.unknown_types = nil
	return res
end

function inst.parse(code, structs)
	typedefs(code)
	return struct_block(code, structs)
end

local unpack_scheme_alias
local function unpack_union(scheme, unions)
	local tbls = {}
	local fmts = {}
	local max_size
	local max_union

	unions.union_cnt = unions.union_cnt + 1
	local union_idx = unions[unions.union_cnt] or 1
	for k, v in ipairs(scheme) do
		local s_fmt, s_tbl = unpack_scheme_alias({v}, unions)
		local sz = string.packsize("!="..s_fmt)
		if not max_size or sz > max_size then
			max_size = sz
			max_union = k
		end
		table.insert(tbls, s_tbl)
		table.insert(fmts, s_fmt)
	end

	if union_idx == max_union then
		return fmts[max_union], tbls[max_union]
	else
		local fmt = assert(fmts[union_idx], union_idx..":"..#fmts)
		local tbl = tbls[union_idx]

		local sz = max_size - string.packsize("!="..fmt)
		fmt = fmt..string.rep("x", sz)

		return fmt, tbl
	end
end

local function _layout(fmt, tbl, keys, bin)
	local data = string.unpack(fmt, bin)
	local unread = data[#data]
	data[#data] = nil
	assert(#data == #keys)
	for k, v in ipairs(data) do
		tbl[keys[k]] = v
	end
	return unread
end

local function unpack_scheme(scheme, unions)
	local tbl = {}
	local fmt = ""
	unions = unions or {}
	unions.union_cnt = unions.union_cnt or 0

	local align, align_size = nil
	for k, v in ipairs(scheme) do
		if v.body then
			local _fmt, _tbl
			if v.is_union then
				_fmt, _tbl = unpack_union(v.body, unions)
			else
				_fmt, _tbl = unpack_scheme(v.body, unions)
			end
			fmt = fmt..string.rep(_fmt, v.array or 1)
			_tbl.name = v.name
			_tbl.array = v.array
			table.insert(tbl, _tbl)
		else
			if v.array then
				fmt = fmt .. string.rep(v.fmt, v.array)
				table.insert(tbl, {name=v.name, array=v.array})
			else
				fmt = fmt..v.fmt
				table.insert(tbl, v.name)
			end

			local sz = string.packsize(v.fmt)
			if not align_size or sz > align_size then
				align_size = sz
				align = v.fmt
			end
		end
	end

	if align then
		fmt = string.format("X%s%sX%s", align, fmt, align)
	end
	return fmt, tbl
end
unpack_scheme_alias = unpack_scheme

local function layout(data, keys, unread)
	local tbl = {}
	local idx = unread or 1
	for k, v in ipairs(keys) do
		if type(v) == "string" then
			tbl[v] = data[idx]
			idx = idx + 1
		elseif v.array then
			tbl[v.name] = {}
			for i=1, v.array do
				if #v > 0 then
					local s_tbl, s_idx = layout(data, v, idx)
					table.insert(tbl[v.name], s_tbl)
					idx = s_idx
				else
					table.insert(tbl[v.name], data[idx])
					idx = idx + 1
				end
			end
		else
			local s_tbl, s_idx = layout(data, v, idx)
			tbl[v.name] = s_tbl
			idx = s_idx
		end
	end
	return tbl, idx
end

local function unwind(keys, unread)
	local tbl = {}
	local idx = unread or 1
	for k, v in ipairs(keys) do
		if type(v) == "string" then
			tbl[v] = idx
			idx = idx + 1
		elseif v.array then
			for i=1, v.array do
				if #v > 0 then
					local s_tbl, s_idx = unwind(v, idx)
					for m, n in pairs(s_tbl) do
						tbl[v.name.."."..i.."."..m] = n
					end
					idx = s_idx
				else
					tbl[v.name.."."..i] = idx
					idx = idx + 1
				end
			end
		else
			local s_tbl, s_idx = unwind(v, idx)
			for m, n in pairs(s_tbl) do
				tbl[v.name.."."..m] = n
			end
			idx = s_idx
		end
	end
	return tbl, idx
end

function inst.unpack(structs, struct_name, bin, unions)
	local scheme = structs[struct_name]

	local fmt, keys = unpack_scheme(scheme, unions)
	fmt = "!="..fmt
	local list = table.pack(string.unpack(fmt, bin))
	local unread = list[#list]
	local size = string.len(bin)
	list[#list] = nil

	local unwind_keys = unwind(keys)

	local mt = {
		get=function(key)
			local id = rawget(unwind_keys, key)
			return list[id]
		end,
		set=function(key, val)
			if type(val) == "table" then
				for k, v  in ipairs(val) do
					local id = rawget(unwind_keys, key.."."..k)
					assert(id, key)
					list[id] = v
				end
			else
				local id = rawget(unwind_keys, key)
				assert(id, key)
				list[id] = val
			end
		end,
		pack=function()
			return string.pack(fmt, table.unpack(list))
		end,
		unread_data=function()
			if unread > size then return end
			return string.sub(bin, unread, size)
		end,
		dump=function()
			local tbl = layout(list, keys)
			return tbl
		end
	}
	mt.__index = mt

	return setmetatable({}, mt)
end

function inst.pack(structs, struct_name, tbl)
	local layout = c99.typedefs[struct_name]
	assert(layout and type(layout) == "string", struct_name)
	local struct = structs[struct_name]
	local data = {}
	for k, v in ipairs(struct) do
		table.insert(data, tbl[v.name])
	end
	return string.pack(layout, table.unpack(data))
end

return inst
