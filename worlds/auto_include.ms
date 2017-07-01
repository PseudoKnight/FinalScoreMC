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
	Returns world group
*/
proc _world_group(@world) {
	@worlds = _worlds_config();
	if(array_index_exists(@worlds, @world)) {
		return(@worlds[@world]['group']);
	}
	return(null);
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
	@worlds = _worlds_config();
	@world_name = to_lower(@world);
	@world_id = '';
	if(array_index_exists(@worlds, @world)) {
		@world_id = @worlds[@world_name];
	} else {
		@world_name  = reg_replace('[_-]', '', @world_name);
		if(array_index_exists(@worlds, @world_name)) {
			@world_id = @worlds[@world_name];
		} else {
			throw(InvalidWorldException, 'A world by the name "'.@world.'" does not exist.');
		}
	}
	@world_id = @worlds[@world_name];
	if(is_array(@world_id)) {
		return(@world_name);
	} else {
		return(@world_id);
	}
}

/*
	Returns if the world is a survival world
*/
proc _is_survival_world(@world) {
	return(has_metadata(@world, 'survival'));
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

/*
	Creates and adds a world to config temporarily
*/
proc _create_world(@name, @world) {
	@worlds = _worlds_config();
	@worlds[@name] = @world;
	if(array_index_exists(@world, 'seed')) {
		if(array_index_exists(@world, 'generator')) {
			create_world(@name, 'NORMAL', @world['environment'], @world['seed'], @world['generator']);
		} else {
			create_world(@name, 'NORMAL', @world['environment'], @world['seed']);
		}
	} else {
		create_world(@name, 'NORMAL', @world['environment']);
	}
	// Flags a world in the survival world group
	if(@world['group'] == 'survival') {
		set_metadata(@name, 'survival', true);
	}
	// Since difficulty isn't currently loaded from level.dat
	@difficulty = 'NORMAL';
	if(array_index_exists(@world, 'difficulty')) {
		@difficulty = @world['difficulty'];
	}
	set_difficulty(@name, @difficulty);
}
