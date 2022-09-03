register_command('particles', array(
	description: 'Creates particle effects for a player.',
	usage: '/particles <effect> [player]',
	permission: 'command.particles',
	tabcompleter: closure(@alias, @sender, @args, @info) {
		if(array_size(@args) == 1) {
			return(_strings_start_with_ic(array('hoop'), @args[-1]));
		}
		return(array());
	},
	executor: closure(@alias, @sender, @args, @info) {
		if(!@args) {
			return(false);
		}
		@player = player();
		if(array_size(@args) == 2) {
			@player = _find_player(@args[1]);
		}
		switch(@args[0]) {
			case 'hoop':
				tmsg(@player, 'Sneak to clear particle effect.');
				set_interval(50, closure(){
					if(psneaking(@player)) {
						clear_task();
					}
					@location = location_shift(ploc(@player), 'up', 2);
					@world = @location['world'];
					@yaw = to_radians(@location['yaw']);
					@pitch = to_radians(@location['pitch']);
					for(@r = -3.141, @r < 3.141, @r += 0.2) {
						spawn_particle(array(
							'x': @location['x'] + 1.5 * (cos(@yaw) * cos(@r + @pitch)),
							'y': @location['y'] + 1.5 * (sin(@r + @pitch)),
							'z': @location['z'] + 1.5 * (sin(@yaw) * cos(@r + @pitch)),
							'world': @world,
						), 'REDSTONE');
					}
				});
		}
	}
));