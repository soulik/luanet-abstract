local paths = {
	cpath = {'','./?.dll','./?/init.dll','./lib/?.dll','./lib/?/init.dll','./lib/?/core.dll','./lib/external/?/init.dll','./lib/external/?/core.dll','./lib/external/?.dll'},
	lpath = {'','./?.lua','./?/init.lua','./lib/?.lua','./lib/?/init.lua','./lib/?/core.lua','./lib/external/?/init.lua','./lib/external/?/core.lua','./lib/external/?.lua'},
}

package.cpath = table.concat(paths.cpath,';')
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
