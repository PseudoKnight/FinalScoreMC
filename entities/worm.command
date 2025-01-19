register_command('worm', array(
	description: 'Spawns a worm',
	usage: '/worm [length]',
	permission: 'command.entity',
	tabcompleter: closure(return(array())),
	executor: closure(@alias, @sender, @args, @info) {
		@loc = ptarget_space();
		@loc['yaw'] = 0;
		@loc['pitch'] = 0;
		include('custom.library/worm.ms');
		if(array_size(@args) == 1) {
			_worm_spawn(@loc, array(length: @args[0]));
		} else if(array_size(@args) == 2) {
			_worm_spawn(@loc, array(length: @args[0], width: @args[1]));
		} else {
			_worm_spawn(@loc);
		}
	}
));