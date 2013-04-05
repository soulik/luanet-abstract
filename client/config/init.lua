CONFIG = {
	dev = {
		log_file = "debug.log",
		dump_file = "debug_dump.log",
		profile = false,
		debug = false,
	},
	net = {
		servers = {
			main = {
				address = "127.0.0.1",
				port = 10000,
			},
		}
	},
	units = {
		'dispatcher',
		'jobs',
		'net/client',
	},
}