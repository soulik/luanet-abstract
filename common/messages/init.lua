require 'utils/queue'

return function()
	local o = {
	}
	local queue = utils.queue()

	local push = function(name,params,ret)
		queue.push({
			name = name,
			params = params,
			ret = ret,
		})
	end

	local pop = function()
		if queue.size()>0 then
			return queue.pop()
		end
	end

	local empty = function()
		if queue.size()>0 then
			return false
		else
			return true
		end
	end

	o.push = push
	o.pop = pop
	o.empty = empty

	o.register = function(name, controller)
		push('register', {name = name, controller = controller})	
	end

	return o
end