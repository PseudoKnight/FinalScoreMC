register_command('tempboat', array(
	description: 'Creates a temporary boat like /tempcart.',
	usage: '/tempboat <player>',
	permission: 'command.tempboat',
	tabcompleter: closure(@alias, @sender, @args, @info) {
		return(array());
	},
	executor: closure(@alias, @sender, @args, @info) {
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
		@boat = spawn_entity('OAK_BOAT', 1, @loc)[0];
		set_entity_silent(@boat, true);
		set_entity_rider(@boat, @rider);
		if(has_bind(@player.'vehicle_leave')) {
			die();
		}
		bind('vehicle_leave', array(id: @player.'vehicle_leave'), array(vehicletype: 'OAK_BOAT', passengertype: 'PLAYER'), @e, @player) {
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
