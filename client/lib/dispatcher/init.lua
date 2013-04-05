messages = (require 'messages')()
local jobs = (require 'jobs')()
require 'time'

return function()
	local o = {
		running = true
	}

	local function quit()
		o.running = false
	end

	local controllers = {}

	local fn = {
		status = function(m)
		end,
		message = function(m)
		end,
		register = function(p)
			if p.name and p.controller then
				controllers[p.name] = p.controller
				dbg.print("%q controller registered",p.name)
			end
		end,
		send_to = function(p)
			local net_controller = controllers.net
			if net_controller then
				return net_controller.send_to(p.name, p.data)
			end			
		end,
		send_to_all = function(p)
			local net_controller = controllers.net
			if net_controller.net then
				return net_controller.send_to_all(p.data)
			end			
		end,
		peers_list = function()
			local net_controller = controllers.net
			if net_controller then
				return net_controller.get_peers_list()
			end
		end,
		peer_connected = function(name)
			dbg.print("connected: "..name)						
		end,
		peer_disconnected = function(name)
			dbg.print("disconnected: "..name)			
		end,
		add_job = function(p)
			local job_controller = controllers.job
			if job_controller then
				if p.fn then
					job_controller.add(p.fn, p.name)
				end
			end
		end,
		quit = function()
			quit()
		end,
	}

	local function process_messages()
		local msg
		if (not messages.empty()) then
			while (function()
				msg = messages.pop()
				return msg
			end)() do
				if msg and msg.name then
					local _fn = fn[msg.name]
					if type(_fn)=="function" then
						local ret = msg.ret
						local params = msg.params

						if type(ret)=="function" then
							local _s, _m = pcall(function()
								ret(_fn(params))
							end)
							if not _s then
								dbg.print("Message error: %q\nMessage:\n%s", msg.name, _m)
							end
						else
							local _s, _m = pcall(function()
								_fn(params)
							end)
							if not _s then
								dbg.print("Message error: %q\nMessage:\n%s", msg.name, _m)
							end							
						end
					end
				end
	    	end
		else
			os.sleep(10)
		end
	end

	function o.main()
		while o.running do
			process_messages()
			coroutine.yield()
		end
	end
	return o
end