register_command('generate', array(
	description: 'Generates something using a script.',
	usage: '/generate <type> <config> <region> [seed=0] [markers=true]',
	permission: 'command.generate',
	tabcompleter: closure(@alias, @sender, @args, @info) {
		if(array_size(@args) == 1) {
			return(_strings_start_with_ic(array('dungeon', 'scaled_level'), @args[-1]));
		} else if(array_size(@args) == 2) {
			if(@args[0] == 'dungeon') {
				return(_strings_start_with_ic(array('dungeon', 'phd', 'stronghold', 'test'), @args[-1]));
			} else if(@args[0] == 'scaled_level') {
				return(_strings_start_with_ic(array('dirt', 'showdown', 'static'), @args[-1]));
			}
		} else if(array_size(@args) == 3) {
			return(_strings_start_with_ic(sk_current_regions(), @args[-1]));
		} else if(array_size(@args) == 5) {
			return(_strings_start_with_ic(array('true', 'false'), @args[-1]));
		}
		return(array());
	},
	executor: closure(@alias, @sender, @args, @info) {
		if(!@args) {
			return(false);
		}
		if(@args[0] == 'interrupt') {
			x_interrupt('DungeonPlanner');
		} else {
			_generator_create(@args[0], @args[1], @args[2], pworld(), integer(array_get(@args, 3, 0)), closure(@start, @end, @spawns) {
				if(array_get(@args, 4, 'true') == 'true') {
					set_block(@start, 'EMERALD_BLOCK');
					set_block(location_shift(@end, 'up'), 'CAKE', false);
					foreach(@floor in @spawns) {
						foreach(@spawn in @floor) {
							set_block(@spawn, 'OAK_SIGN', false);
							try(set_sign_text(@spawn, array('Doors: '.@spawn[4], 'Distance: '.@spawn[5])))
						}
					}
				}
			});
		}
	}
));
