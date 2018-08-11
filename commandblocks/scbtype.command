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
			die(color('gold').'You are looking at '.get_block(@block).'. That is not a command block.');
		}
		@type = get_block(@block);
		@type = if(@type == 'COMMAND_BLOCK', 'chain_command_block', 'command_block');
		@data = get_blockdata_string(@block);
		@data = reg_replace('^[^\\[]+', @type, @data);
		set_blockdata_string(@block, @data);
		set_block_command(@block, @cmd);
	}
));
