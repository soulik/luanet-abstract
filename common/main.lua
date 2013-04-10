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
local threads = (require 'threads')()

local loaded_units = {}

local function load_unit(unit_name)
	local unit = (require(unit_name))()
	if unit then
		loaded_units[unit_name] = unit
		threads.add(unit_name, unit.main)
	else
		dbg.print("Could not load unit: %q",unit_name)
	end
end

threads.init()
for i,unit_name in ipairs(CONFIG.units) do
	local status, msg = pcall(load_unit, unit_name)
	if not status then
		dbg.print("Could not load unit: %q\nMessage:\n%s",unit_name, msg)
	end
end
threads.run()
