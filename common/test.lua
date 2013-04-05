local paths = {
	cpath = {'','./?.dll','./?/init.dll','./lib/?.dll','./lib/?/init.dll','./lib/?/core.dll','./lib/external/?/init.dll','./lib/external/?/core.dll','./lib/external/?.dll'},
	lpath = {'','./?.lua','./?/init.lua','./lib/?.lua','./lib/?/init.lua','./lib/?/core.lua','./lib/external/?/init.lua','./lib/external/?/core.lua','./lib/external/?.lua','./lib/external/lunit/?.lua'},
}

package.cpath = table.concat(paths.cpath,';')
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