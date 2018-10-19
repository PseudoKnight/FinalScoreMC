register_command('generate', array(
	'description': 'Generates something using a script.',
	'usage': '/generate <type> <config> <region> [seed]',
	'permission': 'command.generate',
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		return(array());
	},
	'executor': closure(@alias, @sender, @args, @info) {
		if(!@args) {
			return(false);
		}
		if(@args[0] == 'reload') {
			_generator_reload();
		} else {
			_generator_create(@args[0], @args[1], @args[2], pworld(), integer(array_get(@args, 3, 0)), closure(@start, @end, @spawns) {
				set_ploc(@start);
				set_block(@end, 'BEACON', false);
			});
		}
	}
));
