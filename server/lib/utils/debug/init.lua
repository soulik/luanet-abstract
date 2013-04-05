dbg = {}

local dfile = CONFIG.dev.log_file
local dfile2 = CONFIG.dev.dump_file
local dfmt = "%s %s\n"

function dump(_data,_name,spaces)
	spaces = spaces or ''
	local print = dbg.print
	local _name = _name or ""
	local _fmt = "%s%q => %q"
	local dt = type(_data)
	local d = {
		['string'] = function(name,data)
			print(_fmt:format(spaces,tostring(name),data))
		end,
		['other'] = function(name,data)
			print(_fmt:format(spaces,tostring(name),tostring(data)))
		end,
		['table'] = function(name,data)
			local _n = tostring(name)
			if (_n:len()>0) then
				print(_fmt:format(spaces,_n,'('..tostring(#data)..')'))
			end
			for k,v in pairs(data) do
				dump(v,k,spaces..' ')
			end
		end,
	}
	local fn = d[dt]
	if (type(fn)~="function") then
		fn = d['other']
	end
	fn(_name,_data)
end

function dbg.dump(data)
	local f,errmsg = io.open(dfile2,"wb")
	if (f) then
		f:write(data)
		f:close()
		return true
	else
		return false,errmsg
	end
end

function dbg.print(fmt,...)
	if (fmt) then
		local dmsg = string.format(fmt,...)
		local f,errmsg = io.open(dfile,"a")
		if (f) then
			_fmt = dfmt:format(os.date(),dmsg)
			local out = ""
			local res = pcall(function()
				out = _fmt:format()
			end)
			if not res then
				out = string.gsub(_fmt,"%%","%%")
			end
			f:write(out)
			f:close()
			return true
		else
			return false,errmsg
		end
	else
		return false,"Empty string"
	end
end

function hex_dump(buf,first,last)
  local out = {}
  local function align(n) return math.ceil(n/16) * 16 end
  for i=(align((first or 1)-16)+1),align(math.min(last or #buf,#buf)) do
  	if (i-1) % 16 == 0 then
  		table.insert(out,string.format('%08X  ', i-1))
  	end
   	table.insert(out, i > #buf and '   ' or string.format('%02X ', buf:byte(i)) )
    if i %  8 == 0 then
    	table.insert(out,' ')
    end
    
    if i % 16 == 0 then
    	table.insert(out,buf:sub(i-16+1, i):gsub('%c','.'), '\n' )
    end
  end
	return table.concat(out)
end

function try(res,errmsg)
	if (not res) then
		dbg.print("Error %q",errmsg)
	end
	return res,errmsg
end

local profiling = {}

function _p1(n)
	local p = profiling[n]
	local t = SDL.SDL_GetTicks()
	if not p then
		profiling[n] = {t0=t,t=0,sum={0,0,0},t10=0,t50=0,t100=0,i=0}
	else
		p.t0=t
	end
end

function _p2(n)
	local p = profiling[n]
	local t = SDL.SDL_GetTicks() -  p.t0
	p.t = t
	p.sum[1] = p.sum[1] + t
	p.sum[2] = p.sum[2] + t
	p.sum[3] = p.sum[3] + t
	p.i = p.i + 1
	
	if ((p.i%10)==0) then
		p.t10 = p.sum[1]*0.1
		p.sum[1] = 0
	end
	if ((p.i%50)==0) then
		p.t50 = p.sum[2]*0.02
		p.sum[2] = 0
	end
	if ((p.i%100)==0) then
		p.t100 = p.sum[3]*0.01
		p.sum[3] = 0
	end
	return t,p.t10,p.t50,p.t100
end

function _p(n)
	local p = profiling[n]
	if (p) then
		return p.t,p.t10,p.t50,p.t100
	else
		return 0,0,0,0
	end
end

function hexPtr(ptr)
	return string.format("0x%08x",ptr)
end