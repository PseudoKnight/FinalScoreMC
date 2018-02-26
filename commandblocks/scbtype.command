register_command('scbtype', array(
	'description': 'Toggles commandblock type between impulse and chain.',
	'usage': '/scbtype',
	'permission': 'command.cb',
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		return(array());
	},
	'executor': closure(@alias, @sender, @args, @info) {
		@block = pcursor(array(0, 8, 9, 27, 28, 50, 55, 63, 64, 65, 66, 68, 69,
			70, 71, 72, 75, 76, 77, 96, 131, 132, 143, 147, 148, 149, 150, 157));
		try {
			@cmd = get_block_command(@block);
		} catch(FormatException @ex) {
			die(color('gold').'You are looking at '.data_name(get_block_at(@block)).'. That is not a command block.');
		}
		@blockdata = split(':', get_block_at(@block), 1);
		@type = if(@blockdata[0] == '137', 211, 137);
		set_block_at(@block, @type.':'.@blockdata[1]);
		set_block_command(@block, @cmd);
	}
));
