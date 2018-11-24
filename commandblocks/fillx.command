register_command('fillx', array(
	'description': 'An extended fill command with additional modes: fall, toggle.',
	'usage': '/fillx <x1> <y1> <z1> <x2> <y2> <z2> <blockdata> [mode] [extra]',
	'permission': 'command.setblockx',
	'executor': closure(@alias, @sender, @args, @info) {
		if(array_size(@args) < 4) {
			return(false);
		}
		@cmdblk = get_command_block();
		@world = @cmdblk['world'];
		@l1 = _relative_coords(@cmdblk, @args[0], @args[1], @args[2]);
		@l2 = _relative_coords(@cmdblk, @args[3], @args[4], @args[5]);
		@blockdata = @args[6];
		switch(@args[7]) {
			case 'fall':
				@xMax = max(@l1['x'], @l2['x']) + 0.5;
				@yMax = max(@l1['y'], @l2['y']);
				@zMax = max(@l1['z'], @l2['z']) + 0.5;
				for(@x = min(@l1['x'], @l2['x']) + 0.5, @x <= @xMax, @x += 1.0) {
					for(@y = min(@l1['y'], @l2['y']), @y <= @yMax, @y++) {
						for(@z = min(@l1['z'], @l2['z']) + 0.5, @z <= @zMax, @z += 1.0) {
							@loc = array(@x, @y, @z, @world);
							@blockdata = get_blockdata_string(@world);
							if(@blockdata != 'minecraft:air') {
								set_block(@loc, 'AIR', false);
								spawn_falling_block(@loc, @blockdata);
							}
						}
					}
				}
			case 'toggle':
				@xMax = max(@l1['x'], @l2['x']) + 0.5;
				@yMax = max(@l1['y'], @l2['y']);
				@zMax = max(@l1['z'], @l2['z']) + 0.5;
				for(@x = min(@l1['x'], @l2['x']), @x <= @xMax, @x++) {
					for(@y = min(@l1['y'], @l2['y']), @y <= @yMax, @y++) {
						for(@z = min(@l1['z'], @l2['z']), @z <= @zMax, @z++) {
							@loc = array(@x, @y, @z, @world);
							@block = get_blockdata_string(@loc);
							if(string_position(@block, @args[8]) >= 0) {
								set_blockdata_string(@loc, @blockdata);
							} else if(string_position(@block, @blockdata) >= 0) {
								set_blockdata_string(@loc, @args[8]);
							}
						}
					}
				}
			default:
				run(@alias.' '.array_implode(@args));
		}
	}
));
