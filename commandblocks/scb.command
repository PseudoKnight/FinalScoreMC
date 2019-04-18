@allowedCommands = array('/effect', '/fill', '/fillx', '/give', 'particle', '/platform', '/playsound', '/sayas', '/setblock',
	'/setblockx', '/stopsound', '/teleport', '/tempboat', '/tempcart', '/time', '/timer', '/tp', '/velocity', '/warp');
register_command('scb', array(
	'description': 'Set the command in the targeted command block.',
	'usage': '/scb [cmd]',
	'permission': 'command.cb',
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		if(array_size(@args) == 1) {
			return(_strings_start_with_ic(@allowedCommands, @args[-1]));
		}
		return(array());
	},
	'executor': closure(@alias, @sender, @args, @info) {
		@block = pcursor();
		try {
			get_block_command(@block);
		} catch(FormatException @ex) {
			die(color('red').'You are looking at '.get_block(@block).'. That is not a command block.');
		}
		if(!@args) {
			msg(color('yellow').'Type the desired command in chat:');
			psetop(true);
			@binds = array();
			@binds[] = bind('player_quit', null, array('player': player()), @event, @binds) {
				psetop(false);
				foreach(@bind in @binds) {
					unbind(@bind);
				}
			}
			@binds[] = bind('player_command', null, array('player': player()), @event, @binds, @block, @allowedCommands) {
				cancel();
				psetop(false);
				foreach(@bind in @binds) {
					unbind(@bind);
				}
				@args = parse_args(@event['command']);
				if(!array_contains_ic(@allowedCommands, @args[0])) {
					die(color('gold').'Cannot use the command '.@args[0].' in a commandblock. Must be one of: '.array_implode(@allowedCommands));
				}
				@isAlias = is_alias(array_implode(@args));
				foreach(@arg in @args) {
					if(reg_match('^@[ae]', @arg) &&
					((@isAlias && !string_contains(@arg, 'r='))
					|| !@isAlias && !string_contains(@arg, 'distance='))) {
						die(color('gold').'Do not use unlimited @a or @e selectors. Please use ranges.'
						 		.' eg. @a['.if(@isAlias, 'r=8]', 'distance=..8]'));
					}
				}
				set_block_command(@block, @event['command']);
				msg('Command set: ' .color('green').@event['command']);
			}
		} else {
			if(!array_contains_ic(@allowedCommands, @args[0])) {
				die(color('gold').'Cannot use the command '.@args[0].' in a commandblock. Must be one of: '.array_implode(@allowedCommands));
			}
			@isAlias = is_alias(array_implode(@args));
			foreach(@arg in @args) {
				if(reg_match('^@[ae]', @arg) &&
				((@isAlias && !string_contains(@arg, 'r='))
				|| !@isAlias && !string_contains(@arg, 'distance='))) {
					die(color('gold').'Do not use unlimited @a or @e selectors. Please use ranges.'
					 		.' eg. @a['.if(@isAlias, 'r=8]', 'distance=..8]'));
				}
			}
			@cmd = array_implode(@args);
			set_block_command(@block, @cmd);
			msg('Command set: '.color('green').@cmd);
		}
	}
));
