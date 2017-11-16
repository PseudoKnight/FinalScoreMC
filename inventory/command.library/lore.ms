register_command('lore', array(
	'description': 'Sets the lore on an item.',
	'usage': '/lore <line#> <lore string>',
	'permission': 'command.items',
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		return(array());
	},
	'executor': closure(@alias, @sender, @args, @info) {
		if(array_size(@args) < 2 || !is_numeric(@args[0]) || integer(@args[0]) < 1) {
			return(false);
		}
		@meta = get_itemmeta(null);
		if(is_null(@meta)) {
			@meta = associative_array('lore': array());
		} else if(is_null(@meta['lore'])) {
			@meta['lore'] = array();
		}
		@line = integer(@args[0]) - 1;
		@meta['lore'][@line] = colorize(array_implode(@args[1..-1]));
		set_itemmeta(null, @meta);
	}
));
