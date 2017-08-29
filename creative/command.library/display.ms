register_command('display', array(
	'description': 'Sets the display name of the item in hand.',
	'usage': '/display <name>',
	'permission': 'command.items',
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		return(array());
	},
	'executor': closure(@alias, @sender, @args, @info) {
		if(!@args) {
			return(false);
		}
		@meta = get_itemmeta(null);
		if(is_null(@meta)) {
			@meta = associative_array();
		}
		@meta['display'] = colorize(array_implode(@args));
		set_itemmeta(null, @meta);
	}
));
