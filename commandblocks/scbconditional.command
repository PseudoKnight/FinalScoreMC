register_command('scbconditional', array(
	'description': 'Toggles conditional mode.',
	'usage': '/scbconditional',
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
		@data = get_blockdata_string(@block);
		@value = !(reg_match('conditional\\=([^,\\]]+)', @data)[1] == 'true');
		@data = reg_replace('conditional\\=[^,\\]]+', 'conditional='.@value, @data);
		set_blockdata_string(@block, @data);
	}
));
