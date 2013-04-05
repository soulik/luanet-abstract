local mp = require 'MessagePack'

local Int32 = Int32
local ID = [[LJMP]]

--[[

bytes		size		content
-------------------------------
0-3			4			"LJMP"
4-12		2-9			size
(6-13)-len	len			data

]]--

local MPlen_map = {
    [0xCA] = 5,	--'float'
    [0xCB] = 9,	--'double'
    [0xCC] = 2, --'uint8'
    [0xCD] = 3,	--'uint16'
    [0xCE] = 5,	--'uint32'
    [0xCF] = 9,	--'uint64'
    [0xD0] = 2,	--'int8'
    [0xD1] = 3,	--'int16'
    [0xD2] = 5,	--'int32'
    [0xD3] = 9,	--'int64',
}

return function()
	local o = {}
	
	local encode = function(data)
		return mp.pack(data)
	end

	local decode = function(data)
		if data then
			return mp.unpack(data)
		else
			dbg.print("bad data format!")
			return false
		end
	end

	local function numlen(code)
		local len = MPlen_map[code]
		local b = string.byte(code)
		if len then
			return len
		elseif (b <= 0x7F) or ((b >= 0xe0) and (b <= 0xff)) then
			return 1
		else
			dbg.print("bad packet format!")
			return false
		end
	end

	local function read_by_parts(r_fn, total_len)
		local buffer,buffer_prev = ""
		local pos = 1
		local status = true
		local to_read
		repeat
			buffer_prev = buffer
			to_read = (total_len-pos)
			buffer, status = r_fn(to_read, buffer_prev)
			if buffer then
				pos = string.len(buffer)
				if (pos < total_len) then
					local running = coroutine.yield(true,0)
					if not running then
						break
					end
				end
			elseif (not status) then
				dbg.print("Transfer canceled!")
				return false, total_len, pos
			else
				break
			end
		until (pos >= total_len)
		return (buffer or buffer_prev), total_len
	end

	o.read = function(r_fn, queue)
		return coroutine.wrap(function()
			local running = true
			while (running) do
				local p_id = r_fn(4)
				if p_id then
					if (p_id == ID) then
						-- read the first byte of serialized length
						local p_code = r_fn(1)
						local p_len_len = numlen(p_code)
						-- is this valid number representation of data length?
						if type(p_len_len)=="number" then
							local p_code2, p_len

							if p_len_len>1 then
								p_code2 = r_fn(p_len_len-1)
							    if p_code2 then
									p_len = decode(p_code..p_code2)
								end
							else
								p_len = decode(p_code)
							end							
							
							-- do we have a valid data length?
							if p_len then
								local buffer, len = read_by_parts(r_fn, p_len)
								if #buffer==len then
									local data = decode(buffer)
									--print(string.format('DATA: %q',data))
									queue.push(data)
									running = coroutine.yield(true,1)
								end
							end
						end
					end
				end
				running = coroutine.yield(false)
			end
		end)
	end

	o.write = function(s_fn, queue)
		return coroutine.wrap(function()
			local running = true
			while (running) do
				local data = queue.pop()
				if data then
					local data_to_send = encode(data)
					if data_to_send then
						local len = string.len(data_to_send)
						local pos = 0
						local tmp
	
	                    -- setup packet signature
						local signature = ID..encode(len)
						s_fn(signature,1,string.len(signature))
	
	                    -- try to send whole packet
						repeat
							pos, tmp = s_fn(data_to_send, pos+1, len)
						
							if pos then
								if (pos < len) then
									running = coroutine.yield(true, 0)
									if not running then
										break
									end
								end
							elseif (not tmp) then
								dbg.print("Transfer canceled!")
								running = coroutine.yield(false)
								--[[
								if not running then
									break
								end
								]]--
								break
							end
						until (pos >= len)

						running = coroutine.yield(true, 1)
					end
				end
				running = coroutine.yield(false)
			end
		end)
	end

	return o
end