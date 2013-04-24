local paths = {
	cpath = {
		['Windows'] = {
			['x86'] = {'','./{}/?.dll','./{}/?/init.dll','./lib/{}/?.dll','./lib/{}/?/init.dll','./lib/{}/?/core.dll','./lib/external/{}/?/init.dll','./lib/external/{}/?/core.dll','./lib/external/{}/?.dll',},
			['x64'] = {'','./{}/?.dll','./{}/?/init.dll','./lib/{}/?.dll','./lib/{}/?/init.dll','./lib/{}/?/core.dll','./lib/external/{}/?/init.dll','./lib/external/{}/?/core.dll','./lib/external/{}/?.dll',},
		},
		['Linux'] = {
			['x86'] = {'','./{}/?.so','./{}/?/init.so','./lib/{}/?.so','./lib/{}/?/init.so','./lib/{}/?/core.so','./lib/external/{}/?/init.so','./lib/external/{}/?/core.so','./lib/external/{}/?.so',},
			['x64'] = {'','./{}/?.so','./{}/?/init.so','./lib/{}/?.so','./lib/{}/?/init.so','./lib/{}/?/core.so','./lib/external/{}/?/init.so','./lib/external/{}/?/core.so','./lib/external/{}/?.so',},
			['arm'] = {'','./{}/?.so','./{}/?/init.so','./lib/{}/?.so','./lib/{}/?/init.so','./lib/{}/?/core.so','./lib/external/{}/?/init.so','./lib/external/{}/?/core.so','./lib/external/{}/?.so',},
		},
	},
	lpath = {'','./?.lua','./?/init.lua','./lib/?.lua','./lib/?/init.lua','./lib/?/core.lua','./lib/external/?/init.lua','./lib/external/?/core.lua','./lib/external/?.lua'},
}

local cpath = function(current_os, current_arch)
	local cpath_os = paths.cpath[current_os]
	if type(cpath_os)=="table" then
		local cpath_arch = cpath_os[current_arch]
		if type(cpath_arch)=="table" then
			local platform_path = string.format("platform-specific/%s/%s", current_os, current_arch)
			return string.gsub(table.concat(cpath_arch,';'),"{}",platform_path)
		else
			print(string.format("This CPU architecture %q is not currently supported", current_arch))
			os.exit(1)
		end
	else
		print(string.format("This OS %q is not currently supported", current_os))
		os.exit(1)
	end
end

package.cpath = cpath(jit.os, jit.arch)
package.path = table.concat(paths.lpath,';')

require 'config'
require 'utils'
require 'utils/debug'

local scriptname = ...
if scriptname then
	local argv = { select(2,...) }
	if scriptname ~= "" then
		local function force(name)
	    	pcall( function() loadfile(name)() end )
		end
		local lpath = './lib/tests/'
		force( lpath..scriptname..".lua" )
		force( lpath..scriptname.."-console.lua" )
	end
	require "lunit"
	local stats = lunit.main(argv)
		if stats.errors > 0 or stats.failed > 0 then
		os.exit(1)
	end
else
	print(string.format("Syntax: test unit-test-name"))
end
