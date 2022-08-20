register_command('setblockx', array(
	description: 'An extended setblock command with additional modes: timed, fall, toggle.',
	usage: '/setblockx <x> <y> <z> <blockdata> [mode] [extra]',
	permission: 'command.setblockx',
	tabcompleter: closure(@alias, @sender, @args, @info) {
		return(array());
	},
	executor: closure(@alias, @sender, @args, @info) {
		if(array_size(@args) < 4) {
			return(false);
		}
		@cmdblk = get_command_block();
		@loc = _relative_coords(@cmdblk, @args[0], @args[1], @args[2]);
		@blockdata = @args[3];
		switch(@args[4]) {
			case 'fall':
				@block = get_blockdata_string(@loc);
				if(@block !== 'minecraft:air') {
					set_block(@loc, 'AIR');
					@loc['x'] += 0.5;
					@loc['z'] += 0.5;
					spawn_falling_block(@loc, @block);
				}
			case 'timed':
				@ms = null;
				@replaceblock = null;
				if(array_size(@args) == 6) {
					@ms = @args[5];
					@replaceblock = get_blockdata_string(@loc);
				} else {
					@ms = @args[5];
					@replaceblock = @args[6];
				}
				set_blockdata_string(@loc, @blockdata, false);
				set_timeout(@ms, closure(){
					set_blockdata_string(@loc, @replaceblock);
				});
			case 'toggle':
				@block = get_blockdata_string(@loc);
				if(string_position(@block, @args[5]) >= 0) {
					set_blockdata_string(@loc, @blockdata, false);
				} else if(string_position(@block, @blockdata) >= 0) {
					set_blockdata_string(@loc, @args[5], false);
				}
			default:
				run(@alias.' '.array_implode(@args));
		}
	}
));
