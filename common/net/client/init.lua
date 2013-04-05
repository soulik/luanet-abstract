require 'socket/socket'
local peer_handler = require 'net/peer'
local net_messages = (require 'net/messages')()

return function()
	local o = {
		running = true,
	}

	local peers = {}
	local peers_by_name = {}
	local peers_num = 0

	local function quit()
		o.running = false
	end

	local r_sockets, w_sockets = {},{}

	local function connect(host, port)
		local peer, msg = socket.connect(host, port)
		if not peer then
			if msg ~= "timeout" then
				dbg.print("Could not connect to: %s:%d", host, port)
				return false, msg
			else
				return peer, msg
			end
		end
		peer:settimeout(0)
		dbg.print("Connected to: %s:%d", host, port)
		return peer
	end

	local function disconnect(peer)
		local name = string.format("%s:%d", peer:getpeername())
		messages.push('peer_disconnected', name)
		peer:shutdown("both")
		peers[peer] = nil
		peers_num = peers_num - 1
	end

	local function init()
		setmetatable(r_sockets,{ __mode="v"})
		setmetatable(w_sockets,{ __mode="v"})
		setmetatable(peers_by_name,{ __mode="v"})
		dbg.print("Using LuaSocket version %s",socket._VERSION)
		return true
	end

	local function dispatch(peer)
		local r = peer.read()
		if r then
			net_messages.process(peer, r)
		end
	end

	function o.send_to(name, data)
		local peer = peers_by_name[name]
		if peer then
			return peer.write(data)
		end
		return false
	end

	function o.send_to_all(data)
		if peers_num>0 then
			local success = 0
			for name, peer in pairs(peers_by_name) do
				if peer.write(data) then
					success = success + 1
				end
			end
			return true, success, peers_num
		end
		return false
	end

	function o.get_peers_list()
		return peers_by_name
	end

	local function init_connection(peer)
		local _peer = peer_handler(peer)
		peers[peer] = _peer
		table.insert(r_sockets, peer)
		table.insert(w_sockets, peer)
		local name = string.format("%s:%d", peer:getpeername())
		peers_by_name[name] = peer
		peers_num = peers_num + 1
		messages.push('peer_connected',name)
		
		_peer:msg('message','test', function(...)
			print("ret :)", ...)
		end)

	end

	local function process_peers()
		local rc, wc, msg = socket.select(r_sockets, w_sockets, 0)
		for i,s in ipairs(rc) do
			local peer = peers[s]
			if peer then
				local O = peer[2]
				O.r_ready = true
			end
		end
		for i,s in ipairs(wc) do
			local peer = peers[s]
			if peer then
				local O = peer[2]
				O.w_ready = true
			end
		end

		if not msg then
			for peer, iface in pairs(peers) do
				local co = iface[1]
				local cstatus = coroutine.status(co)
				if cstatus ~= "dead" then
					local status, msg = coroutine.resume(iface[1])
					if not status then
						dbg.print(msg)
						disconnect(peer)
					else
						dispatch(iface)
					end
				else
					disconnect(peer)
				end
			end
		end
		net_messages.step()
	end

	function o.main()
		init()
		messages.push('set_net_controller', o)

		while o.running do
			if peers_num > 0 then
				process_peers()
		   	else
		   		for name, params in pairs(CONFIG.net.servers) do
					local socket, msg = connect(params.address, params.port)
					if socket then
						init_connection(socket)
						break
					elseif msg=='timeout' then
					end
				end
			end
			coroutine.yield()
		end
	end

	o.quit = quit
	return o
end