register_command('put', array(
	description: 'Teleports the specified player to the location you\'re looking at.',
	usage: '/put <player>',
	permission: 'command.put',
	executor: closure(@alias, @sender, @args, @info) {
		if(!@args) {
			return(false);
		}
		@loc = ray_trace(96)['block'];
		if(!@loc) {
			die('Location out of range.');
		}
		@loc['x'] += 0.5;
		@loc[0] += 0.5;
		@loc['z'] += 0.5;
		@loc[2] += 0.5;
		@player = _find_player(@args[0]);
		if(pworld(@player) != pworld() && !has_permission('command.put.anywhere')) {
			die(color('gold').'You cannot put players from another world.');
		}
		set_ploc(@player, @loc);
	}
));
