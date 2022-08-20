register_command('kickall', array(
	description: 'Kicks all players with the given message',
	usage: '/kickall <message>',
	permission: 'command.kickall',
	executor: closure(@alias, @sender, @args, @info) {
		@message = array_implode(@args);
		foreach(@p in all_players()) {
			pkick(@p, @message);
		}
	}
));
