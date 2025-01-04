register_command('worm', array(
	description: 'Spawns a worm',
	usage: '/worm [length]',
	permission: 'command.entity',
	tabcompleter: closure(return(array())),
	executor: closure(@alias, @sender, @args, @info) {
		@loc = ptarget_space();
		@loc['yaw'] = 0;
		@loc['pitch'] = 0;
		@length = array_get(@args, 0, 11);
		include('custom.library/worm.ms');
		_worm_spawn(@loc, array(length: @length));
	}
));