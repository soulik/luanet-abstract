require 'utils/queue'
local packet = (require 'net/packet')()
local msg = (require 'net/messages')()
local msg_new = msg.new
local queue = utils.queue

return function(peer)
	-- outer interface
	local O = {
		r_ready = false,
		w_ready = false,
		name = "unknown",
	}
	
	local r_queue = queue()
	local w_queue = queue()

	local iface = {
		read = function()
			if not r_queue.empty() then
				return r_queue.pop()
			end
		end,

		write = function(data)
			w_queue.push(data)
		end,

		msg = function(self, ... )
			self.write(msg_new( self, ... ))
		end,
	}

	local co = coroutine.create(
		function()
			local o = {
				alive = true,
			}

			O.name = string.format("%s:%d", peer:getpeername())

			local function disconnect()
				o.alive = false
			end

			local function unknown(msg)
				dbg.print('msg: ' .. tostring(msg))
			end

			local function receive(mode, buffer)
				local data, msg
				data, msg, buffer = peer:receive(mode, buffer)
				if msg then
					if msg=="timeout" then
						return false, true
					elseif msg=='closed' then
						disconnect()
					else
						unknown(msg)
					end
					return false, false
				end
				return data
			end

			local function send(buffer,i,j)
				local data, msg, index
				index, msg = peer:send(buffer,i,j)
				if msg then
					if msg=="timeout" then
						return false, true
					elseif msg=='closed' then
						disconnect()
					else
						unknown(msg)
					end
					return false, false
				end
				return index
			end

			peer:settimeout(0)

			-- p_read & p_write are specializaed coroutines to actualy receive/send whole packets from/to peer
			local p_read, p_write = packet.read(receive, r_queue), packet.write(send, w_queue)
			local sp_read, sp_write, r1, w1 = true, true, false, false

			while o.alive do
				if O.r_ready then
					-- read if we can read and there's something to read ;)
					sp_read, r1 = p_read(o.alive)
					if not sp_read and r1 then
						print(r1)
					end
					O.r_ready = false
				end
				if O.w_ready and not w_queue.empty() then
					-- write
					sp_write, w1 = p_write(o.alive)
					-- successful transfer to peer
					if sp_write and w1 == 1 then
						--[[
						if type(peer.transfer)=="function" then
							peer:transfer()
						end
						]]--
					end

					O.w_ready = false
				end
				coroutine.yield(true)
			end
			return false
		end
	)

	local out = {
		co, O
	}
	setmetatable(out, {
		__index = function(t, i)
			if type(i)=="number" then
				return rawget(t, i)
			elseif type(i)=="string" then
				return iface[i]
			else
				return nil
			end
		end,
	})
	return out
end