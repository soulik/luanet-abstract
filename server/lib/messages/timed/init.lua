require 'utils/queue'

return function()
	local o = {
	}
	local queue = utils.queue()
	local sort_fn = function(a,b)
		if type(a.delay)=="number" and type(b.delay)=="number" then
			return (a.delay > b.delay)
		end
		return false
	end

	o.push = function(delay,fn,params,ret)
		local delay = delay or 0
		queue.push({
			delay = os.gettime() + delay,
			fn = fn,
			params = params,
			ret = ret,
		})
		queue.sort(sort_fn)
	end

	o.pop = function()
		local t = os.gettime()
		local count = queue.size()
		local items = {}
		if count>0 then
			local i
			for i=1,count do
				local item = queue.peek(i)
				if type(item)=="table" then
					local delay = item.delay
					if type(delay)=="number" and (t >= delay) then
						table.insert(items,queue.pop(i))
					end
				end
			end
			return items
		end
		return false
	end

	o.empty = function()
		if queue.size()>0 then
			return false
		else
			return true
		end
	end

	return o
end