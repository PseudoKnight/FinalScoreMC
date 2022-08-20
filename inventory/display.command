register_command('display', array(
	description: 'Sets the display name of the item in hand.',
	usage: '/display <name>',
	permission: 'command.items',
	tabcompleter: closure(@alias, @sender, @args, @info) {
		return(array());
	},
	executor: closure(@alias, @sender, @args, @info) {
		@name = array_implode(@args);
		@meta = get_itemmeta(null);
		if(is_null(@meta)) {
			@meta = associative_array();
		}
		if(@name) {
			@meta['display'] = colorize(@name);
		} else {
			array_remove(@meta, 'display');
		}
		set_itemmeta(null, @meta);
	}
));
