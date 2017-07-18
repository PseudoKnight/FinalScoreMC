register_command('put', array(
	'description': 'Teleports the specified player to the location you\'re looking at.',
	'usage': '/put <player>',
	'permission': 'command.put',
	'executor': closure(@alias, @sender, @args, @info) {
		if(!@args) {
			return(false);
		}
		@loc = pcursor();
		@loc['x'] += 0.5;
		@loc[0] += 0.5;
		@loc['z'] += 0.5;
		@loc[2] += 0.5;
		@player = _find_player(@args[0]);
		set_ploc(@player, @loc);
	}
));
