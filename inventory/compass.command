register_command('compass', array(
	description: 'Sets the compass target.',
	usage: '/compass <spawn|player|x,z>',
	tabcompleter: closure(@alias, @sender, @args, @info) {
		if(array_size(@args) == 1) {
			@completions = array_merge(array('<x,z>', 'spawn'), all_players(pworld()));
			return(_strings_start_with_ic(@completions, @args[-1]));
		}
		return(array());
	},
	executor: closure(@alias, @sender, @args, @info) {
		if(!@args) {
			return(false);
		}
		@target = @args[0];
		if(@target == 'spawn') {
			set_compass_target(get_spawn());
			msg(color('green').'Compass is now pointing to spawn again.');
		} else {
			try {
				@player = player(@target);
				if(pworld(@player) != pworld()) {
 					die('Player is not in this world.');
				}
				set_compass_target(ploc(@player));
				msg(color('green').'Compass is now pointing to last location of '.@player.'.');
			} catch(PlayerOfflineException @ex) {
				if(array_size(@args) == 1) {
					@args = split(',', @target);
				}
				if(array_size(@args) < 2) {
					return(false);
				}
				@x = @args[0];
				@z = @args[1];
				if(array_size(@args) == 3) {
					@z = @args[2];
				}
				if(is_numeric(@x) && is_numeric(@z)) {
					set_compass_target(array(double(@x), 0, double(@z), pworld()));
					msg(color('green').'Compass is now pointing to x:'.@x.' z:'.@z);
				} else {
					return(false);
				}
			}
		}
	}
));
