register_command('relcoords', array(
	'description': 'Add relative coordinates to the targeted command block.',
	'usage': '/relcoords',
	'permission': 'command.cb',
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		return(array());
	},
	'executor': closure(@alias, @sender, @args, @info) {
		@block = pcursor();
		try {
			@cmd = get_block_command(@block);
		} catch(FormatException @ex) {
			die(color('gold').'You are looking at '.get_block(@block).'. That is not a command block.');
		}
		@loc1 = sk_pos1();
		@x1 = integer(@loc1[0] - @block['x']);
		@y1 = integer(@loc1[1] - @block['y']);
		@z1 = integer(@loc1[2] - @block['z']);
		@parts = parse_args(@cmd);
		if(array_contains_ic(@parts, '/fill')) {
			@loc2 = sk_pos2();
			@x2 = integer(@loc2[0] - @block['x']);
			@y2 = integer(@loc2[1] - @block['y']);
			@z2 = integer(@loc2[2] - @block['z']);
			set_block_command(@block, @cmd.' ~'.@x1.' ~'.@y1.' ~'.@z1.' ~'.@x2.' ~'.@y2.' ~'.@z2.' ');
		} else {
			set_block_command(@block, @cmd.' ~'.@x1.' ~'.@y1.' ~'.@z1.' ');
		}
	}
));
