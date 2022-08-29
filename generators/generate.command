register_command('generate', array(
	description: 'Generates something using a script.',
	usage: '/generate <type> <config> <region> [seed=0] [markers=true]',
	permission: 'command.generate',
	tabcompleter: closure(@alias, @sender, @args, @info) {
		return(array());
	},
	executor: closure(@alias, @sender, @args, @info) {
		if(!@args) {
			return(false);
		}
		if(@args[0] == 'reload') {
			@count = x_recompile_includes('generator.library');
			msg(color('green').'Done recompiling '.@count.' scripts.');
		} else if(@args[0] == 'interrupt') {
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
