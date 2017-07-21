register_command('dungeon', array(
	'description': 'Generates a dungeon.',
	'usage': '/dungeon [region] [type] [seed]',
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		return(array());
	},
	'executor': closure(@alias, @sender, @args, @info) {
		if(!@args) {
			return(false);
		}
		include('../core.library/generator.ms');
		_generate_dungeon(@args[0], pworld(), array_get(@args, 1, 'dungeon'), integer(array_get(@args, 2, 0)));
	}
));
