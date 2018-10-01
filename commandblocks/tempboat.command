register_command('tempboat', array(
	'description': 'Creates a temporary boat like /tempcart.',
	'usage': '/tempboat <player>',
	'permission': 'command.tempboat',
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		return(array());
	},
	'executor': closure(@alias, @sender, @args, @info) {
		@loc = get_command_block();
		@player = _get_nearby_player(@loc, 3);
		if(!@player) {
			die();
		}
		if(is_null(@loc)) {
			@loc = entity_loc(puuid(@player));
			@loc['y'] += 1;
		} else {
			@loc['x'] += 0.5;
			@loc['y'] += 2;
			@loc['z'] += 0.5;
			if(@loc['world'] != pworld(@player)) {
				die('This commandblock cannot set a player into a tempboat across worlds.');
			}
		}
		@rider = puuid(@player);
		@boat = spawn_entity('boat', 1, @loc)[0];
		set_entity_silent(@boat, true);
		set_entity_rider(@boat, @rider);
		@loc = ploc(@player);
		set_interval(1000, closure(){
			if(ponline(@player) && entity_exists(@boat)) {
				@currentLoc = ploc(@player);
				if(@currentLoc['y'] < 61) {
					set_entity_rider(null, puuid(@player));
					set_timeout(200, closure(){
						set_ploc(@player, @loc);
						scriptas(@player,
							sudo('/tempboat '.@player);
						);
					});
				} else if(get_block(@currentLoc) == 'PACKED_ICE') {
					@loc['x'] = @currentLoc['x'];
					@loc['y'] = @currentLoc['y'];
					@loc['z'] = @currentLoc['z'];
					@loc['yaw'] = @currentLoc['yaw'];
					@loc['pitch'] = @currentLoc['pitch'];
				}
			} else {
				clear_task();
			}
		});
		if(has_bind(@player.'vehicle_leave')) {
			die();
		}
		bind('vehicle_leave', array('id': @player.'vehicle_leave'), array('vehicletype': 'BOAT', 'passengertype': 'PLAYER'), @e, @player) {
			if(@e['player'] == @player) {
				unbind();
				unbind(@player.'quit');
				try {
					entity_remove(@e['vehicle']);
				} catch(BadEntityException @ex) {
					// already removed or unloaded
				}
			}
		}
		bind('player_quit', array(id: @player.'quit'), array('player': @player), @e, @boat) {
			unbind();
			unbind(player().'vehicle_leave');
			try {
				entity_remove(@boat);
			} catch(BadEntityException @ex) {
				// already removed or unloaded
			}
		}
	}
));
