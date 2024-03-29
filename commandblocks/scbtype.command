register_command('scbtype', array(
	description: 'Toggles commandblock type between impulse and chain.',
	usage: '/scbtype',
	permission: 'command.cb',
	tabcompleter: closure(return(array())),
	executor: closure(@alias, @sender, @args, @info) {
		@block = ray_trace(8)['block'];
		if(@block == null) {
			die(color('gold').'No command block in range.');
		}
		@cmd = null;
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
