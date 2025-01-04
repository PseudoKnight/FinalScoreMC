proc _map_exists(@id) {
	@base = sys_properties('user.dir');
	return(file_exists("@base/maps/@id.mca"));
}

proc _map_create(@id, @dimension) {
	store_value('map', @id, array(
		owner: puuid(),
		dimension: @dimension,
	));
}

proc _map_load(@id) {
	@exists = _map_exists(@id);

	// load map data
	@map = get_value('map', @id);
	if(!@map) {
		throw(NotFoundException, 'Map data by that ID doesn\'t exist.');
	}

	// reserve a scratch world
	@world = '';
	@worlds = get_worlds();
	for(@i = 0, @i < 10, @i++) {
		if(!array_contains(@worlds, 'dev'.@i)) {
			@world = 'dev'.@i;
			break();
		}
	}
	if(!@world) {
		throw(InvalidWorldException, 'All world slots filled.');
	}

	// copy map to scratch world directory
	if(@exists) {
		@base = sys_properties('user.dir');
		copy_file("@base/maps/@id.mca", "@base/worlds/@world/region/r.0.0.mca");
	}

	// load scratch world with id alias
	_create_world(@world, array(
		name: @id,
		mode: 'CREATIVE',
		group: 'dev',
		environment: @map['dimension'],
		seed: 0,
		generator: 'CleanroomGenerator:.',
		spawning: array(
			'ticks-per-monster-spawns': 0,
			'ticks-per-animal-spawns': 0
		)
	));

	// set map settings
	if(!@exists) {
		@center = array(256, 64, 256, @world);
		set_world_border(@world, array(
			center: @center,
			width: 512,
		));
		set_spawn(@center);
		set_block(location_shift(@center, 'down'), 'BEDROCK');
	}

	// teleport caller to world spawn
	set_timeout(250, closure(){
		set_ploc(location_shift(get_spawn(@world), 'down'));
	});
}

proc _map_save(@id, @world) {
	@base = sys_properties('user.dir');
	copy_file("@base/worlds/@world/region/r.0.0.mca", "@base/maps/@id.mca");
}

proc _map_delete(@id) {
	@base = sys_properties('user.dir');
	delete_file("@base/maps/@id.mca");
}
