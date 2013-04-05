require "lunit"

module( "enhanced", package.seeall, lunit.testcase )

local client_handler = require 'net/peer'
local clients = {}
local sock
local r_sockets, w_sockets = {},{}
dbg = {
	print = print,
}

function setup()
	sock = {
		address = "127.0.0.1",
  		rbuffer = "",
  		wbuffer = "",
  		buffer_size = 5,

		receive = function(self, mode, prev_buffer)
			local maxl = self.buffer_size
			local blen = #self.rbuffer
			local prev_buffer = prev_buffer or ""

			if type(self.rbuffer) == "string" and (blen > 0) then
				local buffer
				if type(mode)=="number" then
					
					if mode>maxl then
						mode = maxl
					end

					if mode <= blen then
						buffer = string.sub(self.rbuffer, 1, mode)
					else
						buffer = string.sub(self.rbuffer, 1, blen)
					end
					self.rbuffer = string.sub(self.rbuffer, mode+1, blen)
					--print(string.format("Received(%d|%d): %q", mode, blen, buffer))
				else
					buffer = self.rbuffer
					self.rbuffer = nil
					--print(string.format("Received: %q", buffer))
				end
				return prev_buffer..buffer
			else
				return nil, "timeout"
			end
		end,
	
		send = function(self, buffer, i, j)
			if (j-i+1)> self.buffer_size then
				j = i+self.buffer_size
			end
			local out = string.sub(buffer, i, j)
			print(string.format("Sent: %q",out))
			if self.wbuffer then
				self.wbuffer = self.wbuffer..out
			else
				self.wbuffer = buffer
			end
			return j
		end,
	
		settimeout = function(self, t)
		end,

		select = function(rs, ws, t)
			return rs, ws
		end,

		getsockname = function(self)
			return self.address
		end,

		transfer = function(self)
			self.rbuffer = self.rbuffer..self.wbuffer
			self.wbuffer = nil
		end,
	}
	
	setmetatable(r_sockets,{ __mode="v"})
	setmetatable(w_sockets,{ __mode="v"})

end

function teardown()
	sock = nil
end

function test_net()
	local function dispatch(client)
		local r = client.read()
		if r then
			print(string.format("RECV Data: %q",tostring(r)))
		end
	end

	local function init_client(client)
		clients[client] = client_handler(client)
		assert_thread(clients[client][1])
		assert_table(clients[client][2])

		table.insert(r_sockets, client)
		table.insert(w_sockets, client)
		print("connected:"..client:getsockname())
	end
	
	local function process_clients()
		local rc, wc, msg = sock.select(r_sockets, w_sockets, 0)
		
		assert_table(rc)
		assert_table(wc)

		assert_equal(1, #rc)
		assert_equal(1, #wc)

		for i,s in ipairs(rc) do
			local O = clients[s][2]
			O.r_ready = true
		end
		
		for i,s in ipairs(wc) do
			local O = clients[s][2]
			O.w_ready = true
		end

		if not msg then
			for client, iface in pairs(clients) do
				local status, msg = coroutine.resume(iface[1])
				if not status then
					print(msg)
					clients[client] = nil
				else
					dispatch(iface)
				end
			end
		end
	end

	assert_table(sock)
  
	init_client(sock)

    for i=1,20 do
		print(string.format("Step #%d: %q",i,sock.rbuffer))
		if (i%2==0) and (i<=10) then
			for client, iface in pairs(clients) do
				iface.write(string.format("hello from step: %d",i))
			end
		end

		process_clients()
	end
end