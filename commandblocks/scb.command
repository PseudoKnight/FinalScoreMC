@allowedcmds = array('/velocity', '/tp', '/sayas', '/testfor', '/testforblock', '/testforblocks', '/playsound',
	'/setblock', '/fill', '/tempcart', '/bedspawn', '/give', '/effect', '/warp', '/tellraw', '/time', '/stopsound',
	'/timer', '/tempboat', '/platform');
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
		@block = pcursor();
		try {
			get_block_command(@block);
		} catch(FormatException @ex) {
			die(color('gold').'You are looking at '.get_block(@block).'. That is not a command block.');
		}
		@cmd = array_implode(@args);
		if(@match = reg_match('^\\/(?:minecraft\\:)?(setblock.*)', @cmd)) {
			if(array_contains(array('replace', 'keep', 'destroy'), @args[5])) {
				@cmd = '/minecraft:'.@match[1];
			} else {
				@cmd = '/'.@match[1];
			}
		} else if(@match = reg_match('^\\/(?:minecraft\\:)?(fill.*)', @cmd)) {
			if(array_contains(array('replace', 'keep', 'destroy', 'hollow', 'outline'), @args[8])) {
				@cmd = '/minecraft:'.@match[1];
			} else {
				@cmd = '/'.@match[1];
			}
		} else if(is_alias(@cmd)) {
			@cmd = '/runalias '.@cmd;
		}
		set_block_command(@block, @cmd);
		msg('Command set: '.color('green').@cmd);
	}
));
