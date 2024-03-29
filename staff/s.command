register_command('s', array(
	description: 'Sends a chat message from console.',
	usage: '/s <FakePlayerName> <message>',
	permission: 'command.s',
	tabcompleter: closure(@alias, @sender, @args, @info) {
		return(array());
	},
	executor: closure(@alias, @sender, @args, @info) {
		if(array_size(@args) < 2) {
			return(false);
		}
		@name = @args[0];
		@message = array_implode(@args[1..-1]);
		broadcast(_timestamp().colorize('&7[console] &b'.@name.'&8:&r '.@message));
		if(function_exists('dm_broadcast_to_web')) {
			dm_broadcast_to_web(@message, @name)
		}
		if(function_exists('discord_broadcast')) {
			discord_broadcast('minecraft_chat', '**'.@name.'**: '.@message);
		}
	}
));
