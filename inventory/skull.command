register_command('skull', array(
	'description': 'Generates a skull with a specific account name.',
	'usage': '/skull <name>',
	'permission': 'command.skull',
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		return(array());
	},
	'executor': closure(@alias, @sender, @args, @info) {
		if(@args) {
			pgive_item(array('name': 'SKULL_ITEM', 'data': 3, 'meta': array('owner': @args[0])));
		} else {
			return(false);
		}
	}
));