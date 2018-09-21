@worlds = import('worlds');
if(!@worlds) {
	@worlds = yml_decode(read('config.yml'));
	export('worlds', @worlds);
}
@loadedWorlds = get_worlds();
foreach(@id: @world in @worlds) {
	if(!is_array(@world) || array_index_exists(@world, 'enabled') && !@world['enabled']) {
		continue();
	}
	if(!array_contains(@loadedWorlds, @id)) {
		if(array_index_exists(@world, 'generator')) {
			create_world(@id, 'NORMAL', @world['environment'], @world['seed'], @world['generator']);
		} else {
			create_world(@id, 'NORMAL', @world['environment']);
		}
	}
	
	// Flags a world in the survival world group
	if(@world['group'] == 'survival') {
		set_metadata(@id, 'survival', true);
	}
	
	// Since difficulty isn't currently loaded from level.dat
	@difficulty = 'NORMAL';
	if(array_index_exists(@world, 'difficulty')) {
		@difficulty = @world['difficulty'];
	}
	set_difficulty(@id, @difficulty);
	
	// Disable natural spawning on certain worlds, otherwise use server defaults
	if(array_index_exists(@world, 'spawning')) {
		if(extension_exists('CHPaper')) {
			set_spawning(@id, @world['spawning']);
		}
	}
}
