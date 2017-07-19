register_command('cloud', array(
	'description': 'Spawns a particle cloud.',
	'usage': '/cloud [x y z] <particle> <radius> [seconds] [r,g,b]',
	'permission': 'command.cloud',
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		if(array_size(@args) == 4 || array_size(@args) == 1) {
			return(_strings_start_with_ic(reflect_pull('enum', 'Particle'), @args[-1]));
		}
		return(array());
	},
	'executor': closure(@alias, @sender, @args, @info) {
		@numArgs = array_size(@args);
		if(@numArgs < 2 || @numArgs > 7) {
			return(false);
		}
		
		@offset = 0;
		if(@numArgs > 4) {
			@offset = 3;
		}
		
		@loc = get_command_block();
		if(!@loc) {
			@loc = _relative(ploc(), 'up');
		}
		@color = array(0, 0, 0);
		@duration = 600;
		
		if(@numArgs > 4) {
			@loc = _relative_coords(@loc, @args[0], @args[1], @args[2]);
			if(@numArgs > 5) {
				@duration = integer(@args[5]) * 20;
				if(@numArgs == 7) {
					@color = split(',', @args[6], 2);
				}
			}
		} else if(@numArgs > 2) {
			@duration = integer(@args[2]) * 20;
			if(@numArgs == 4) {
				@color = split(',', @args[3], 2);
			}
		}
		
		@cloud = spawn_entity('AREA_EFFECT_CLOUD', 1, @loc)[0];
		set_entity_spec(@cloud, array(
			'duration': if(@duration == -20, math_const('INTEGER_MAX') - 20, @duration),
			'particle': @args[@offset],
			'radius': min(16, double(@args[@offset + 1])),
			'color': @color,
		));
	}
));
