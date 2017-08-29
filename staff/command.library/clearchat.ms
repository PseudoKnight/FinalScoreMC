register_command('clearchat', array(
	'description': 'Sends 20 empty lines to all player\'s chat window.',
	'usage': '/clearchat',
	'permission': 'command.clearchat',
	'executor': closure(@alias, @sender, @args, @info) {
		for(@i = 0, @i < 20, @i++) {
			broadcast('');
		}
	}
));
