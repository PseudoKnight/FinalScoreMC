register_command('generate', array(
	'description': 'Generates something using a script.',
	'usage': '/generate <type> <region> [config] [seed]',
	'permission': 'command.generate',
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		return(array());
	},
	'executor': closure(@alias, @sender, @args, @info) {
		if(!@args) {
			return(false);
		}
		_generator_create(@args[0], @args[1], pworld(), array_get(@args, 2, 'dungeon'), integer(array_get(@args, 3, 0)));
	}
));
