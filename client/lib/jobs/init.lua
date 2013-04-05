local c_resume = coroutine.resume

return function()
	local o = {
		running = true,
	}

	local jobs = {}

	local function quit()
		o.running = false
	end

	function o.add(fn, name)
		local name = name or "unknown"
		local co = coroutine.create(fn)
		jobs[co] = name, co
	end

	local function process_jobs()
		for co, name in pairs(jobs) do				
			local status = coroutine.status(co)
			if status=="running" or status=="normal" then					
				local c_status, msg, c_status2, msg2 = pcall(c_resume, co)
				if (not c_status or not c_status2) and (msg or msg2) then
					dbg.print("Job: %s failed with message: %s : %s", name, tostring(msg), tostring(msg2))
					jobs[co] = nil
				end
			elseif status=="dead" then
				jobs[co] = nil
			end
			coroutine.yield()
		end
	end

	function o.main()
		messages.register('jobs', o)

		while o.running do
			process_jobs()
			coroutine.yield()
		end
	end

	return o
end