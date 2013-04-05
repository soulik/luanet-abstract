CONFIG = {
	dev = {
		log_file = "debug.log",
		dump_file = "debug_dump.log",
		profile = false,
		debug = false,
	},
	net = {
		address = "*",
		port = 10000,
	},
	units = {
		'dispatcher',
		'jobs',
		'net/server',
	},
}