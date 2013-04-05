require 'socket/socket'

local ffi = require 'ffi'

ffi.cdef[[
	typedef int    Int32;	
]]

Int32 = ffi.typeof("Int32")

local lfs = require 'lfs'

function os.utime()
  local ms = socket.gettime()*1000
  return ms
end


function io.load(fname)
	local f = io.open(fname)
	if f then
		local buffer = f:read("*a")
		f:close()
		return buffer
	else
		return false
	end
end

function io.save(fname,data)
	local f = io.open(fname,"w")
	if f then
		f:write(data)
		f:close()
		return true
	else
		return false
	end
end

os.mkdir = lfs.mkdir

function string.bin32(data, len)
	local len = len or ffi.sizeof(data)
	local b = ffi.new('unsigned long[1]',{data})
	return ffi.string(b, len)
end

function string.template(s,t)
	local out = string.gsub(s,"{{([%w_+-]+)}}",t)
	return out
end

function string.trim(s)
	if type(s)=="string" then
		local out = string.match(s,"^%s*(.-)%s*$")
		if out and string.len(out)>0 then
			return out
		else			
			return ""
		end
	else
		return
	end
end

local function kilo(n)
	return math.pow(1024,n)
end

function get_bytes_text(n)
	local fn = function(nn,fmt)
		local fmt = fmt or "%0.2f"
    	return string.format(fmt,nn)
	end
	if (n<kilo(1)) then
    	return fn(n,"%d").." B"
	elseif ((n>=kilo(1)) and (n<kilo(2))) then
		return fn(n/kilo(1)).." KiB"
	elseif ((n>=kilo(2)) and (n<kilo(3))) then
		return fn(n/kilo(2)).." MiB"
	elseif ((n>=kilo(3)) and (n<kilo(4))) then
		return fn(n/kilo(3)).." GiB"
	else
		return fn(n/kilo(4)).." TiB"
	end
end
