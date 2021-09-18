register_command('scbauto', array(
	description: 'Sets whether the block needs redstone or not.',
	usage: '/scbauto <true|false>',
	permission: 'command.cb',
	tabcompleter: closure(@alias, @sender, @args, @info) {
		if(array_size(@args) == 1) {
			return(_strings_start_with_ic(array('true', 'false'), @args[-1]));
		}
		return(array());
	},
	executor: closure(@alias, @sender, @args, @info) {
		if(!@args) {
			return(false);
		}
		@auto = integer(@args[0] == 'true');
		@block = ray_trace(8)['block'];
		if(@block == null) {
			die(color('gold').'No command block in range.');
		}
		try {
			@cmd = get_block_command(@block);
		} catch(FormatException @ex) {
			die('You are looking at '.get_block(@block).'. That is not a command block.');
		}
		@x = integer(@block['x']);
		@y = integer(@block['y']);
		@z = integer(@block['z']);
		sudo("/data merge block @x @y @z {auto:@auto}");
	}
));
