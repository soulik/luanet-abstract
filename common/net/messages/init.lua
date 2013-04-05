local filesystem = (require 'filesystem')()

return function()
	local o = {}
	
	o.init = function()
	end

	local slots = {}
	local slots_times = {}
	local slot_time_limit = 1000

	--setmetatable(slots_times, {__mode='k'})

	local fn = {
		['file'] = {
			['receive'] = function(peer, data)
				if type(data)=="table" then
					local fn = filesystem.save_file(peer, slot)
				
					messages.push('add_job',{
						name = 'file_receive',
						fn = fn,
					})
				end
			end,
			['send'] = function(peer, data)
				if type(data)=="table" then
					local fn = filesystem.read_file(peer, data)
				
					messages.push('add_job',{
						name = 'file_send',
						fn = fn,
					})
				end
			end
		},
		['message'] = {
			['receive'] = function(peer, data)
				if type(data)=="table" then
					local out = string.format('A message from: %s - %q', tostring(peer.name), tostring(data.content))
					print(out)
					dbg.print(out)
				end
			end,
		},		
		['peer'] = {
			['ret'] = function(peer, data)
				local ret = data.ret
				if type(ret)=="string" then
					local ret_fn = slots[ret]
					if type(ret_fn)=="function" or type(ret_fn)=="thread" then
						slots_times[ret] = 1
						ret_fn(data.data)
					end
				end
			end,
			['test'] = function(peer, data)
				local n = tonumber(data.n or 3)
				for i=1,n do
					peer:msg('message','send',string.format("Remote Test Step %d",i))
				end
			end,
		}
	}

	local messages = {
		['file'] = {
		    ['push'] = function(path, part, content, size)
		    	return {
		    		cat = 'file',
		    		cmd = 'receive',
		    		data = {
		    			path = path,
		    			part = part,
		    			content = content,
		    			size = size,
		    		},
		    	}
		    end,
		    ['pull'] = function(path, part, content)
		    	return {
		    		cat = 'file',
		    		cmd = 'send',
		    		data = {
		    			path = path,
		    		},
		    	}
		    end,
		},
		['message'] = {
			['send'] = function(content)
		    	return {
		    		cat = 'message',
		    		cmd = 'receive',
		    		data = {
		    			content = content,
		    		},
		    	}
			end,
			['test'] = function(n)
				print('Sending test')
		    	return {
		    		cat = 'peer',
		    		cmd = 'test',
		    		data = {
		    			n = n,
		    		},
		    	}
			end,
		},
	}

	local function create_slot(peer, ret_fn)
		local co = coroutine.create(ret_fn)
		local id = tostring(co)
		local fn = function(...)
			local status = coroutine.status(co)
			if status~="dead" then
				local status, ret_msg = coroutine.resume(co, ...)
				if status then
					if type(ret_msg)=="table" then
						peer:msg(unpack(ret_msg))
						return true
					else
						slots[id] = nil
						slots_times[id] = nil
						return false
					end
				else
					dbg.print("retval failed: %s",ret_msg)
					return false
				end
			end
			return false
		end
		slots[id] = fn
		slots_times[id] = 1
		return id
	end

	o.new = function(peer, category, command, ret, ...)
		print(peer, category, command, ret)
		if type(category)=="string" and type(command)=="string" then
			local c = fn[category]
			if type(c)=="table" then
				local f = c[command]
				if type(f)=="function" then
					local t
					if type(ret)=="function" then
						t = pcall(f, ...)
						t.ret = create_slot(peer, ret)
					else
						t = pcall(f, ret, ...)
					end
					return t
				end
			end
		end		
	end

	o.process = function(peer, data)
		if type(data)=="table" then
			local category = data.cat
			local command = data.cmd
			print('CMD',category,command)
			if type(category)=="string" and type(command)=="string" then
				local c = fn[category]
				if type(c)=="table" then
					local f = c[command]
					if type(f)=="function" then
						return pcall(f, peer, data.data)
					end
				end
			end
		end
		return false
	end

	o.step = function()
		for id, time in pairs(slots_times) do
			if time > slot_time_limit then
				dbg.print("Slot %q timeout!",id)
				slots[id] = nil
				slots_times[id] = nil
			else
				slots_times[id] = time + 1
			end
		end
	end

	return o
end