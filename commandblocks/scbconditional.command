register_command('scbconditional', array(
	'description': 'Toggles conditional mode.',
	'usage': '/scbconditional',
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
		@data = get_blockdata_string(@block);
		@value = !(reg_match('conditional\\=([a-z]+)', @data)[1] == 'true');
		@data = reg_replace('conditional\\=[a-z]+', 'conditional='.@value, @data);
		set_blockdata_string(@block, @data);
	}
));
