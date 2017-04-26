register_command('cloud', array(
	'description': 'Spawns a particle cloud.',
	'usage': '/cloud <x> <y> <z> <particle> <radius> [color]',
	'permission': 'command.cloud',
	'executor': closure(@alias, @sender, @args, @info) {
		@numArgs = array_size(@args);
		if(@numArgs != 2 && @numArgs != 5 && @numArgs != 6) {
			return(false);
		}
		
		@loc = get_command_block();
		if(!@loc) {
			@loc = _relative(ploc(), 'up');
		}
		@color = array(0, 0, 0);
		@particle = 0;
		@radius = 1;
		
		if(@numArgs > 4) {
			@loc = _relative_coords(@loc, @args[0], @args[1], @args[2]);
			@particle = 3;
			@radius = 4;
			if(@numArgs == 6) {
				@color = split(',', @args[5], 2);
			}
		}
		
		@cloud = spawn_entity('AREA_EFFECT_CLOUD', 1, @loc)[0];
		set_entity_spec(@cloud, array(
			'duration': math_const('INTEGER_MAX') - 20,
			'particle': @args[@particle],
			'radius': min(16, double(@args[@radius])),
			'color': @color,
		));
	},
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		if(array_size(@args) == 4) {
			return(_strings_start_with_ic(reflect_pull('enum', 'Particle'), @args[-1]));
		}
	}
));
