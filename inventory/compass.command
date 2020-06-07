register_command('compass', array(
	'description': 'Sets the compass target.',
	'usage': '/compass <here|spawn|home [player]|playerName|x z>',
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		if(array_size(@args) == 1) {
			@completions = array_merge(all_players(), array('here', 'spawn', 'home'));
			return(_strings_start_with_ic(@completions, @args[-1]));
		}
	},
	'executor': closure(@alias, @sender, @args, @info) {
		if(!@args) {
			return(false);
		}
		@target = @args[0];
		switch(@target) {
			case 'spawn':
				set_compass_target(get_spawn());
				msg(color('green').'Compass is now pointing to '._worldname(pworld()).'\'s spawn.');
	
			case 'home':
				@pdata = null;
				if(array_size(@args) > 1) {
					@pdata = _pdata(@arg[1]);
				} else {
					@pdata = _pdata(player());
				}
				if(!array_index_exists(@pdata, 'homes')) {
					die(color('gold').'No home to target.');
				}
				if(!array_index_exists(@pdata['homes'], pworld())) {
					die(color('gold').'No home in this world to target.');
				}
				set_compass_target(@pdata['homes'][pworld()]);
				msg(color('green').'Compass is now pointing to '.if(array_size(@args) > 1, @arg[1].'\'s', 'your').' home.');
	
			case 'here':
				set_compass_target(ploc());
				msg(color('green').'Compass is now pointing to this location.');
	
			default:
				try {
					@player = player(@target);
					if(pworld(@player) != pworld(), die('Player is not in this world.'));
					set_compass_target(ploc(@player));
					msg(color('green').'Compass is now pointing to '.@player.'\'s last location.');
				} catch(PlayerOfflineException @ex) {
					if(array_size(@args) < 2) {
						die(color('gold').'Unknown compass target: '.array_implode(@args).'. Available targets: '
								.'spawn, home [PlayerName], here, PlayerName, x [y] z.');
					}
					@x = @args[0];
					@z = @args[1];
					if(array_size(@args) == 3) {
						@z = @args[2];
					}
					if(is_numeric(@x) && is_numeric(@z)) {
						set_compass_target(array(double(@x), 0, double(@z), pworld()));
						msg(color('green').'Compass is now pointing to x:'.@target.' z:'.@args[1]);
					}
				}
		}
	}
));
