register_command('bball', array(
	'description': 'Spawn a ball',
	'usage': '/bball',
	'permission': 'command.bball',
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		return(array());
	},
	'executor': closure(@alias, @sender, @args, @info) {
		@loc = get_command_block();
		if(!@loc
		|| array_contains(get_bars(), 'hoops')
		|| import('hoops')) {
			die()
		}
		@loc['x'] += 0.5;
		@loc['y'] += 2.0;
		@loc['z'] += 0.5;
		
		include('core.library/ball.ms');
		include('core.library/player.ms');
		_hoops_ball_create(@loc);
	}
));
