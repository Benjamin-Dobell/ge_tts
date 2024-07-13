local error = error
local byte, find, format, gsub, match = string.byte, string.find, string.format,  string.gsub, string.match
local concat = table.concat
local tostring = tostring
local rawget, pairs, type, next = rawget, pairs, type, next
local setmetatable = setmetatable
local huge, tiny = 1/0, -1/0

local f_string_esc_pat = '[^ -!#-[%]^-\255]'
local _ENV = nil

---@shape lunajson__EncodeDispatcher
---@field boolean fun(v: boolean): void
---@field number fun(v: number): void
---@field string fun(v: string): void
---@field table fun(v: table): void

---@alias lunajson__GenerateValueEncode fun(nullv: any, dispatcher: lunajson__EncodeDispatcher, push: (fun(component: string): void), replace: (fun(replacer: (fun(builder: string[], next: number): string[], number)): void)): (fun(v: any): void)

local function newencoder()
	---@type any, any
	local v, nullv

	---@type number, string[], table<table, true>
	local i, builder, visited

	---@param v any
	local function f_tostring(v)
		builder[i] = tostring(v)
		i = i+1
	end

	local radixmark = --[[---@type nil | string]] match(tostring(0.5), '[^0-9]')
	local delimmark = --[[---@type string]] match(tostring(12345.12345), '[^0-9' .. radixmark .. ']')
	if radixmark == '.' then
		radixmark = nil
	end

	---@type nil | true
	local radixordelim
	if radixmark or delimmark then
		radixordelim = true
		if radixmark and find(--[[---@not nil]] radixmark, '%W') then
			radixmark = '%' .. radixmark
		end
		if delimmark and find(delimmark, '%W') then
			delimmark = '%' .. delimmark
		end
	end

	---@param n number
	local f_number = function(n)
		if tiny < n and n < huge then
			local s = format("%.17g", n)
			if radixordelim then
				if delimmark then
					s = gsub(s, delimmark, '')
				end
				if radixmark then
					s = gsub(s, --[[---@not nil]] radixmark, '.')
				end
			end
			builder[i] = s
			i = i+1
			return
		end
		error('invalid number')
	end

	---@type fun(v: any): void
	local doencode

	local f_string_subst = {
		['"'] = '\\"',
		['\\'] = '\\\\',
		['\b'] = '\\b',
		['\f'] = '\\f',
		['\n'] = '\\n',
		['\r'] = '\\r',
		['\t'] = '\\t',
		__index = function(_, c)
			return format('\\u00%02X', byte(c))
		end
	}
	setmetatable(f_string_subst, f_string_subst)

	---@param s string
	local function f_string(s)
		builder[i] = '"'
		if find(s, f_string_esc_pat) then
			s = gsub(s, f_string_esc_pat, f_string_subst)
		end
		builder[i+1] = s
		builder[i+2] = '"'
		i = i+3
	end

	---@param o table
	local function f_table(o)
		if visited[o] then
			error("loop detected")
		end
		visited[o] = true

		local tmp = o.n
		if type(tmp) == 'number' then -- arraylen available
			builder[i] = '['
			i = i+1
			for j = 1, tmp do
				doencode(o[j])
				builder[i] = ','
				i = i+1
			end
			if tmp > 0 then
				i = i-1
			end
			builder[i] = ']'

		else
			tmp = rawget(o, 1)
			if tmp ~= nil then -- detected as array
				builder[i] = '['
				i = i+1
				local j = 2
				repeat
					doencode(tmp)
					tmp = o[j]
					if tmp == nil then
						break
					end
					j = j+1
					builder[i] = ','
					i = i+1
				until false
				builder[i] = ']'

			else -- detected as object
				builder[i] = '{'
				i = i+1
				for k, v in pairs(o) do
					if type(k) ~= 'string' then
						error('non-string key: ' .. tostring(k) .. ' (' .. type(k) .. ')')
					end
					f_string(k)
					builder[i] = ':'
					i = i+1
					doencode(v)
					builder[i] = ','
					i = i+1
				end
				if next(o) then
					i = i-1
				end
				builder[i] = '}'
			end
		end

		i = i+1
		visited[o] = nil
	end

	---@type lunajson__EncodeDispatcher
	local dispatcher = {
		boolean = f_tostring,
		number = f_number,
		string = f_string,
		table = f_table,
		__index = function(_, key)
			error("invalid type value: " .. key)
		end
	}

	setmetatable(dispatcher, dispatcher)

	---@param v any
	local function defaultencode(v)
		if v == nullv then
			builder[i] = 'null'
			i = i+1
			return
		end
		return dispatcher[--[[---@not 'nil' | 'function' | 'thread' | 'userdata']] type(v)](v)
	end

	---@param component string
	local function push(component)
		builder[i] = component
		i = i+1
	end

	---@param replacer fun(builder: string[], next: number): string[], number
	local function replace(replacer)
		builder, i = replacer(builder, i)
	end

	---@param v_ any
	---@param nullv_? any
	---@param generate_value_encode? nil | lunajson__GenerateValueEncode
	local function encode(v_, nullv_, generate_value_encode)
		v, nullv = v_, nullv_
		i, builder, visited = 1, {}, {}
		doencode = generate_value_encode and generate_value_encode(nullv, dispatcher, push, replace) or defaultencode

		doencode(v)
		return concat(builder)
	end

	return encode
end

return newencoder
