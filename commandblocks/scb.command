@allowedCommands = array('/clear', '/effect', '/entity', '/fill', '/fillx', '/give', '/particle', '/platform', '/minecraft:playsound', '/playsound', '/sayas', '/setblock',
	'/setblockx', '/spawnpoint', '/stopsound', '/teleport', '/tempboat', '/tempcart', '/time', '/timer', '/title', '/tp', '/velocity', '/warp', '/lava');
@limitedCommands = array('/sayas', '/playsound', '/stopsound');
register_command('scb', array(
	description: 'Set the command in the targeted command block.',
	usage: '/scb [cmd]',
	permission: 'command.cb',
	tabcompleter: _create_tabcompleter(
		array('command.cb.extended': @allowedCommands,
			null: @limitedCommands),
		array('</sayas': array('<from>'),
			'</playsound': reflect_pull('enum', 'Sound')),
		array('<</sayas': array('@p'),
			'<</playsound': array('[pitch]')),
	),
	executor: closure(@alias, @sender, @args, @info) {
		@block = ray_trace(8)['block'];
		if(@block == null) {
			die(color('gold').'No command block in range.');
		}
		if(!sk_can_build(@block)) {
			die(color('red').'Cannot build here.');
		}
		try {
			get_block_command(@block);
		} catch(FormatException @ex) {
			die(color('red').'You are looking at '.get_block(@block).'. That is not a command block.');
		}
		if(has_permission('command.cb.extended') && !@args) {
			msg(color('yellow').'Type the desired command in chat:');
			psetop(true);
			@binds = array();
			@binds[] = bind('player_quit', null, array(player: player()), @event, @binds) {
				psetop(false);
				foreach(@bind in @binds) {
					unbind(@bind);
				}
			}
			@binds[] = bind('player_interact', null, array(player: player()), @event) {
				cancel();
				msg(color('yellow').'Type the desired command in chat:');
			}
			@binds[] = bind('player_command', null, array(player: player()), @event, @binds, @block, @allowedCommands) {
				cancel();
				psetop(false);
				foreach(@bind in @binds) {
					unbind(@bind);
				}
				@args = parse_args(@event['command']);
				if(!array_contains_ic(@allowedCommands, @args[0])) {
					die(color('gold').'Cannot use the command '.@args[0].' in a commandblock. Must be one of: '.array_implode(@allowedCommands));
				}
				foreach(@arg in @args) {
					if(reg_match('^@[ae]', @arg) && !string_contains(@arg, 'distance=')) {
						die(color('gold').'Do not use unlimited @a or @e selectors. Please use ranges. Example: @a[distance=..8]');
					}
				}
				set_block_command(@block, @event['command']);
				msg('Command set: ' .color('green').@event['command']);
			}
		} else if(@args) {
			// check for allowed commands
			if(!has_permission('command.cb.extended')) {
				if(!array_contains_ic(@limitedCommands, @args[0])) {
					die(color('gold').'Cannot use the command '.@args[0].' in a commandblock. Must be one of: '.array_implode(@limitedCommands));
				}
			} else if(!array_contains_ic(@allowedCommands, @args[0])) {
				die(color('gold').'Cannot use the command '.@args[0].' in a commandblock. Must be one of: '.array_implode(@allowedCommands));
			}

			// command argument validations
			foreach(@arg in @args) {
				if(reg_match('^@[ae]', @arg) && !string_contains(@arg, 'distance=')) {
					die(color('gold').'Do not use unlimited @a or @e selectors. Please use ranges. Example: @a[distance=..8]');
				}
			}
			if(@args[0] == '/sayas') {
				if(array_size(@args) < 4) {
					die(color('gold').'Too few arguments.');
				} else if(@args[2][0] !== '@') {
					die(color('gold').'Expected a target player selector as the second argument. Example: @p');
				}
			}

			// set command
			@cmd = array_implode(@args);
			set_block_command(@block, @cmd);
			msg('Command set: '.color('green').@cmd);
		}
	}
));
