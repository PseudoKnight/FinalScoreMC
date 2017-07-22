register_command('skull', array(
	'description': 'Generates a skull with a specific account name.',
	'usage': '/skull <name>',
	'permission': 'command.items',
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		return(array());
	},
	'executor': closure(@alias, @sender, @args, @info) {
		if(@args) {
			pgive_item(player(), '397:3', 1, array('owner': @args[0]));
		} else {
			return(false);
		}
	}
));
