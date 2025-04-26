register_command('compass', array(
	description: 'Sets a compass target.',
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
		@compass = pinv(player(), null);
		if(!@compass || @compass['name'] !== 'COMPASS') {
			die('Not holding a compass.');
		}
		if(!@compass['meta']) {
			@compass['meta'] = associative_array();
		}
		@compass['meta']['lodestone'] = false;
		@target = @args[0];
		if(@target == 'spawn') {
			@compass['meta']['target'] = get_spawn();
			@compass['meta']['display'] = color('white')._world_name(pworld()).' Spawn';
			set_pinv(player(), null, @compass);
			msg(color('green').'Compass is now pointing to '._world_name(pworld()).' spawn.');
		} else if(@target === '<x,y>') {
			@loc = ploc();
			@x = @loc['x'];
			@z = @loc['z'];
			msg("You can use comma or space separated x and y coordinates.\nExample: /compass @x,@z");
		} else {
			try {
				@player = player(@target);
				if(pworld(@player) != pworld()) {
 					die('Player is not in this world.');
				}
				@compass['meta']['target'] = ploc(@player);
				@compass['meta']['display'] = color('white').@player.'\'s previous location in '._world_name(pworld(@player));
				set_pinv(player(), null, @compass);
				msg(color('green').'Compass is now pointing to the current location of '.@player.'.');
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
					@compass['meta']['target'] = array(double(@x), 0, double(@z), pworld());
					@compass['meta']['display'] = color('white').'X: '.@x.', Z: '.@z.' '._world_name(pworld());
					set_pinv(player(), null, @compass);
					msg(color('green').'Compass is now pointing to X: '.@x.', Z: '.@z.' in '._world_name(pworld()));
				} else {
					return(false);
				}
			}
		}
	}
));
