register_command('fillx', array(
	description: 'An extended fill command with additional modes: fall, toggle.',
	usage: '/fillx <x1> <y1> <z1> <x2> <y2> <z2> <blockdata> <mode> [toggled_blockdata]',
	permission: 'command.fillx',
	executor: closure(@alias, @sender, @args, @info) {
		if(array_size(@args) < 8) {
			return(false);
		}
		@cmdblk = get_command_block();
		@world = @cmdblk['world'];
		@l1 = _relative_coords(@cmdblk, @args[0], @args[1], @args[2]);
		@l2 = _relative_coords(@cmdblk, @args[3], @args[4], @args[5]);
		@blockdata = @args[6];
		@mode = @args[7];

		@xMin = min(@l1['x'], @l2['x']);
		@yMin = min(@l1['y'], @l2['y']);
		@zMin = min(@l1['z'], @l2['z']);
		@xMax = max(@l1['x'], @l2['x']);
		@yMax = max(@l1['y'], @l2['y']);
		@zMax = max(@l1['z'], @l2['z']);

		@limit = get_gamerule(@world, 'max_block_modifications');
		if(abs(@xMax - @xMin) * abs(@yMax - @yMin) * abs(@zMax - @zMin) > @limit) {
			die('Exceeded block limit.');
		}

		if(@mode === 'fall') {
			for(@x = @xMin, @x <= @xMax, @x += 1.0) {
				for(@y = @yMin, @y <= @yMax, @y++) {
					for(@z = @zMin, @z <= @zMax, @z += 1.0) {
						@loc = array(@x, @y, @z, @world);
						@blockdata = get_blockdata_string(@loc);
						if(@blockdata !== 'minecraft:air') {
							set_block(@loc, 'AIR', false);
							spawn_falling_block(_center(@loc, 0.0), @blockdata);
						}
					}
				}
			}
		} else if(@mode === 'toggle') {
			for(@x = @xMin, @x <= @xMax, @x++) {
				for(@y = @yMin, @y <= @yMax, @y++) {
					for(@z = @zMin, @z <= @zMax, @z++) {
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
		} else {
			return(false);
		}
	}
));
