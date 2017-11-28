register_command('s', array(
	'description': 'Sends a chat message from console.',
	'usage': '/s <FakePlayerName> <message>',
	'permission': 'command.s',
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		return(array());
	},
	'executor': closure(@alias, @sender, @args, @info) {
		if(array_size(@args) < 2) {
			return(false);
		}
		@name = @args[0];
		@message = array_implode(@args[1..-1]);
		broadcast(colorize('&8'.simple_date('h:mm').'&7 [console] &b'.@name.'&8:&r '.@message));
		if(function_exists('dm_broadcast_to_web')) {
			dm_broadcast_to_web(@message, @name)
		}
		runas('~console', '/discord broadcast **'.@name.'**: '.@message);
	}
));
