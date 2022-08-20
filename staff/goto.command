register_command('goto', array(
	description: 'Teleports you to the specified player.',
	usage: '/goto <player>',
	permission: 'command.goto',
	executor: closure(@alias, @sender, @args, @info) {
		if(!@args) {
			return(false);
		}
		@player = _find_player(@args[0]);
		if(!has_permission('command.goto.anywhere') && _is_survival_world(pworld(@player))) {
			die(color('gold').'You cannot goto that player.');
		}
		set_ploc(player(), ploc(@player));
	}
));
