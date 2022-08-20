register_command('setmotd', array(
	description: 'Sets the message of the day that displays to players on entering the server.',
	usage: '/setmotd <message>',
	permission: 'command.setmotd',
	executor: closure(@alias, @sender, @args, @info) {
		@message = colorize(array_implode(@args));
		store_value('motd', @message);
		msg('MOTD set to: '.@message);
	}
));
