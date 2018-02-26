@allowedcmds = array('/velocity', '/tp', '/sayas', '/testfor', '/testforblock', '/testforblocks', '/playsound',
	'/setblock', '/tempcart', '/bedspawn', '/give', '/effect', '/warp', '/tellraw', '/time', '/stopsound', '/timer', '/tempboat');
register_command('scb', array(
	'description': 'Set the command in the targeted command block.',
	'usage': '/scb <cmd>',
	'permission': 'command.cb',
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		if(array_size(@args) == 1) {
			return(_strings_start_with_ic(@allowedcmds, @args[-1]));
		}
		return(array());
	},
	'executor': closure(@alias, @sender, @args, @info) {
		if(!@args) {
			return(false);
		}
		if(!array_contains_ic(@allowedcmds, @args[0])) {
			die(color('gold').'Allowed commands: '.array_implode(@allowedcmds));
		}
		foreach(@arg in @args) {
			if(reg_match('@[ae]\\[[^r]', @arg)) {
				die(color('gold').'Cannot use unlimited @a or @e selectors. Please use ranges. eg. @a[r=8]');
			}
		}
		@block = pcursor(array(0, 8, 9, 27, 28, 50, 55, 63, 64, 65, 66, 68, 69,
			70, 71, 72, 75, 76, 77, 96, 131, 132, 143, 147, 148, 149, 150, 157));
		try {
			get_block_command(@block);
		} catch(FormatException @ex) {
			die(color('gold').'You are looking at '.data_name(get_block_at(@block)).'. That is not a command block.');
		}
		@cmd = array_implode(@args);
		if(is_alias(@cmd)) {
			@cmd = '/runalias '.@cmd;
		}
		set_block_command(@block, @cmd);
		msg('Command set: '.color('green').@cmd);
	}
));
