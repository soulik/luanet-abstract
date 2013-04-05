--local msg = (require 'net/messages')()

return function()
	local o = {}
	local block_size = 512
	local max_size = 1024*1024*128 -- 128 MB

	--[[
		request:
			{
				path = '/path/file.ext',
			}
		response:
			{
				path = '/path/file.ext',
				size = 123456789,
				part = 1,
				content = '',
			},
			{
				path = '/path/file.ext',
				msg = 'Permission denied',
			}
	]]--

	local function save_file(peer, slot)
		return function()
			local data = slot.pop()
			-- initial file part
			if type(data)=="table" and type(data.path)=="string" and type(data.content)=="string" and type(data.part)=="number" and type(data.size)=="number" and data.part==1 then
				dbg.print("save_file() - begin")
				local size = tonumber(data.size)
				if size <= max_size then
					local f, msg = io.open(data.path,"wb")
					if f then
						local path = data.path
						local part = data.part
						local size = data.size
						local written = 0

						repeat
							if not f:write(data.content) then
								peer:msg('message', 'send', 'Can\'t write to the file')
								break
							end
							written = written + #data.content

							while (slot.empty()) do
								coroutine.yield()
							end
							
							data = slot.pop()
							
							coroutine.yield()
						until (written >= size)

						f:close()
						dbg.print("save_file() - end")
						return true
					else
						peer:msg('message', 'send', msg)
					end
				else
					peer:msg('message', 'send', string.format("File size is greater than: %db",max_size))
				end
			end
			return false
		end
	end

	local function read_file(peer, data)
		return function()
			if type(data)=="table" and type(data.path)=="string" then
				dbg.print("read_file() - begin")
				local f, msg = io.open(data.path,"rb")
				if f then
					local path = data.path
					local part = 1
										
					local size = f:seek('end')
					f:seek('set', 0)
					
					local content = f:read(block_size)
					while(content) do
						if part == 1 then
							peer:msg('file','push', path, part, content, size)
						else
							peer:msg('file','push', nil, part, content)
						end
						content = f:read(block_size)
						part = part + 1
						coroutine.yield()
					end
					dbg.print("read_file() - end")
					return true
				else
					peer:msg('message', 'send', msg)
				end
			end
			return false
		end
	end

	o.save_file = save_file
	o.read_file = read_file

end