local windows = jit.os == 'Windows'

local ffi = require 'ffi'
if windows then
   ffi.cdef[[
     int GetTickCount(void);
     unsigned long SleepEx(unsigned long dwMilliseconds, bool bAlertable);
  ]]
else
   ffi.cdef[[
	 struct timeval {
	    long tv_sec;
	    long tv_usec;
	 };

	 int gettimeofday(struct timeval * tp, void *tzp);
   ]]
end

local function mtime()
   if windows then
      return ffi.C.GetTickCount()
   else
      local tv = ffi.new('struct timeval[1]')
      ffi.C.gettimeofday(tv, nil)
      return tv[0].tv_sec * 1000 + (tv[0].tv_usec / 1000)
   end
end

os.gettime = function()
	return mtime()
end

os.sleep = function(ms, alertable)
	if windows then
		local alertable = alertable
		if not (type(alertable)=="boolean") then
			alertable = false
		end
		return ffi.C.SleepEx(ms, alertable)
	end
end