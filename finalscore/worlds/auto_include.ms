/*
	Returns the worlds config
*/
proc _worlds_config() {
	@worlds = import('worlds');
	if(is_null(@worlds)) {
		@worlds = yml_decode(read('config.yml'));
		export('worlds', @worlds);
	}
	return(@worlds);
}

/*
	Returns world alias when given world folder name
*/
proc _worldname(@world) {
	@worlds = _worlds_config();
	@world = to_lower(@world);
	try {
		return(@worlds[@world]['name']);
	} catch(IndexOverflowException @ex) {
		# default to lower case name
		return(@world);
	}
}

/*
	Returns a world folder name when given a world alias
*/
proc _worldid(@world) {
	@worlds = array(
		'alpha': 'world',
		'alphanether': 'world_nether',
		'delta': 'world3',
		'deltanether': 'world3_nether',
		'gamma': 'world4',
		'gammanether': 'world4_nether',
		'theend': 'world_the_end',
		'custom': 'custom',
		'frogpark': 'custom',
		'dev': 'dev',
		'outworld': 'outworld',
		'omega': 'omega',
		'omeganether': 'omega_nether',
		'outworld': 'outworld',
		'outworldnether': 'outworld_nether',
	)
	@alias = to_lower(reg_replace('[_-]', '', @world))
	if(array_index_exists(@worlds, @alias)) {
		return(@worlds[@alias])
	} else {
		return(to_lower(@world))
	}
}

/*
	Returns if the world is a survival world
*/
proc _is_survival_world(@world) {
	@worlds = _worlds_config();
	try {
		return(@worlds[@world]['mode'] == 'survival');
	} catch(IndexOverflowException @ex) {
		# default to true
		return(true);
	}
}

/*
	Returns if the world allows teleports
*/
proc _allows_teleports(@world) {
	@worlds = _worlds_config();
	try {
		return(@worlds[@world]['teleports']);
	} catch(IndexOverflowException @ex) {
		# default to true
		return(true);
	}
}
