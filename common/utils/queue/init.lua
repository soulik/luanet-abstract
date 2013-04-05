if type(utils) ~= "table" then
	utils = {}
end

function utils.queue()
	local o = {}
	local data = {}
	function o.empty()
		if (#data > 0) then
			return false
		else
			return true
		end
	end

	function o.push(d)
		table.insert(data,d)
	end

	function o.pop(index)
		local count = #data
		if count>0 then
			local index = index or 1
			local item
			if index<=count then
				item = table.remove(data,index)
			end
			return item
		end
	end

	function o.peek(index)
		local count = #data
		if count>0 then
			local index = index or 1
			local item = data[index]
			return item
		end
	end

	function o.sort(fn)
		table.sort(data,fn)
	end

	function o.size()
		return #data
	end

	return o
end
