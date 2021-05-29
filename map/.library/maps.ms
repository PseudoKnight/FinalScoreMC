proc _base_directory() {
	return('../../../../..');
}

proc _map_exists(@id) {
	return(file_exists(_base_directory().'/maps/'.@id.'.mca'));
}

proc _map_load(@id, @world) {
	// reserve a scratch world
	@world = '';
	@worlds = get_worlds();
	for(@i = 0, @i < 10, @i++) {
		if(!array_contains(@worlds, 'dev'.@i)) {
			@world = 'dev'.@i;
		}
	}
	if(!@world) {
		throw(InvalidWorldException, 'All world slots filled.');
	}

	// copy map to scratch world directory
	@base = _base_directory();
	copy_file("@base/maps/@id.mca", "@base/@world/region/r.0.0.mca");

	// load scratch world with id alias
	_create_world(@worldName, array(
		name: @id,
		mode: 'CREATIVE',
		group: 'dev',
		environment: 'NORMAL',
		seed: 0,
		generator: 'CleanroomGenerator:.',
		spawning: array(
			'ticks-per-monster-spawns': 0,
			'ticks-per-animal-spawns': 0
		)
	));
}

proc _map_save(@id, @world) {
	@base = _base_directory();
	copy_file("@base/@world/region/r.0.0.mca", "@base/maps/@id.mca");
}
