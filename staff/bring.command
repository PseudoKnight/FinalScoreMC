register_command('bring', array(
	description: 'Teleports the specified player to you.',
	usage: '/bring <player>',
	permission: 'command.bring',
	executor: closure(@alias, @sender, @args, @info) {
		if(!@args) {
			return(false);
		}
		@player = _find_player(@args[0]);
		if(pworld(@player) != pworld() && !has_permission('command.bring.anywhere')) {
			die(color('gold').'You cannot bring players from another world.');
		}
		set_ploc(@player, ploc());
	}
));
