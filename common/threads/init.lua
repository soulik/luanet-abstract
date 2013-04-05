require 'coxpcall'

return function()
	local o = {}
	local threads = {}
	local running = 0
	
	o.init = function()
		threads = {}
		running = 0
	end

	local function errf(p1,p2,p3)
		dbg.print("ERR: %s %s %s",tostring(p1),tostring(p2),tostring(p3))
		return p1,p2,p3
	end

	local function handleDeadThread(i,thread,msg)
		local name = thread[4] or ("#"..tostring(i))
		local message
		local critical = thread[3]

		if critical then
			message = string.format("Critical thread has ended: %s: %q",name,tostring(msg))
		else
			message = string.format("A thread has ended: %s: %q",name,tostring(msg))
		end
			
		print(message)
		dbg.print(message)
		threads[i] = nil
			
		if critical then
			return 0
		else
			return true
		end
	end

	local function step()
		local cleanup = {}
		running = 0
		for i,thread in pairs(threads) do
			local res, msg, p
			local tstatus = coroutine.status(thread[1])

			if tstatus~="dead" then
				res, msg, p = coroutine.resume(thread[1],thread[2])
				if res then
					running = running + 1
				end
				if (res and msg==true) then
					table.insert(cleanup,function() threads[i]=nil; end)
				elseif (not res) and msg then
					local result = handleDeadThread(i,thread,msg)
					if result==0 then
						return 0
					end
				end
			elseif (msg) then
				local result = handleDeadThread(i,thread)
				if result==0 then
					return 0
				end
			end
		end		
		for k,v in pairs(cleanup) do
			if (type(v)=='function') then
				v()
			end
		end
	end

	o.add = function(name,fun,param,critical)
		local fun2 = function() coxpcall(fun,errf) end
		local co = coroutine.create(fun2)
		table.insert(threads,{co,param,critical,name})
		return #threads
	end

	o.run = function()
		xpcall(function()
			repeat
				step()
			until (running<1)
		end,errf)
	end

	return o
end