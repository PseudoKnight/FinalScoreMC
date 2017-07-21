register_command('scbauto', array(
	'description': 'Sets whether the block needs redstone or not.',
	'usage': '/scbauto <true|false>',
	'permission': 'command.cb',
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		if(array_size(@args) == 1) {
			return(_strings_start_with_ic(array('true', 'false'), @args[-1]));
		}
		return(array());
	},
	'executor': closure(@alias, @sender, @args, @info) {
		if(!@args) {
			return(false);
		}
		@auto = integer(@args[0] == 'true');
		@block = pcursor(array(0, 8, 9, 27, 28, 50, 55, 63, 64, 65, 66, 68, 69,
			70, 71, 72, 75, 76, 77, 96, 131, 132, 143, 147, 148, 149, 150, 157));
		try {
			@cmd = get_block_command(@block);
		} catch(FormatException @ex) {
			die('You are looking at '.data_name(get_block_at(@block)).'. That is not a command block.');
		}
		@x = @block['x'];
		@y = @block['y'];
		@z = @block['z'];
		sudo("/blockdata @x @y @z {auto:@auto}");
	}
));
