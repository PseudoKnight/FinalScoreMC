@allowedCommands = array('/clear', '/effect', '/entity', '/fill', '/fillx', '/give', '/particle', '/platform', '/minecraft:playsound', '/playsound', '/sayas', '/setblock',
	'/setblockx', '/spawnpoint', '/stopsound', '/teleport', '/tempboat', '/tempcart', '/time', '/timer', '/title', '/tp', '/velocity', '/warp', '/lava', '/execute');
@limitedCommands = array('/sayas', '/playsound', '/stopsound');
register_command('scb', array(
	description: 'Set the command in the targeted command block.',
	usage: '/scb [cmd]',
	permission: 'command.cb',
	tabcompleter: _create_tabcompleter(
		array('command.cb.extended': @allowedCommands,
			null: @limitedCommands),
		array('</sayas': array('<from>'),
			'</playsound': reflect_pull('enum', 'Sound'),
			'</execute': array('if', 'unless')),
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

		proc _valid_arguments(@args, @allowedSubCommands = @allowedCommands) {
			if(@args[0] === '/execute') {
				if(@args[1] !== 'if' && @args[1] !== 'unless') {
					msg(color('gold').'Cannot use the command /execute in a commandblock without "if" or "unless".');
					return(false);
				}
				@runIndexes = array_indexes(@args, 'run');
				foreach(@runIndex in @runIndexes) {
					@subCommand = @args[@runIndex + 1];
					if(@subCommand[0] === '/') {
						msg(color('gold').'Commands must not start with "/" after "run" in /execute.');
						return(false);
					}
					@allowed = true;
					if(@subCommand === 'runalias') {
						@subCommand = @args[@runIndex + 2];
						if(@subCommand[0] !== '/') {
							msg(color('gold').'Commands after "runalias" must start with "/" in /execute.');
							return(false);
						}
						if(!is_alias(array_implode(@args[cslice(@runIndex + 2, -1)]))) {
							msg(color('gold').'Must use a valid alias after "runalias". Either the command is incomplete or is not an alias.');
							return(false);
						}
					} else {
						if(@subCommand !== 'playsound' // can use both vanilla and alias for this command
						&& is_alias('/'.array_implode(@args[cslice(@runIndex + 1, -1)]))) {
							msg(color('gold').'Must use "run runalias" before a command that is an alias.');
							return(false);
						}
						@subCommand = '/'.@subCommand;
					}
					if(!array_contains(@allowedSubCommands, @subCommand)) {
						msg(color('gold').'Cannot run '.@subCommand.' in /execute.');
						return(false);
					}
				}
			} else if(@args[0] === '/sayas') {
				if(array_size(@args) < 4) {
					msg(color('gold').'Too few arguments.');
					return(false);
				}
				if(@args[2][0] !== '@') {
					msg(color('gold').'Expected a target player selector as the second argument. Example: @p');
					return(false);
				}
			}
			foreach(@arg in @args) {
				if(reg_match('^@[ae]', @arg) && !string_contains(@arg, 'distance=')) {
					msg(color('gold').'Do not use unlimited @a or @e selectors. Please use ranges. Example: @a[distance=..8]');
					return(false);
				}
			}
			return(true);
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
				if(_valid_arguments(@args)) {
					set_block_command(@block, @event['command']);
					msg('Command set: ' .color('green').@event['command']);
				}
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
			if(_valid_arguments(@args)) {
				@cmd = array_implode(@args);
				set_block_command(@block, @cmd);
				msg('Command set: '.color('green').@cmd);
			}
		}
	}
));
