register_command('tempboat', array(
	'description': 'Creates a temporary boat like /tempcart.',
	'usage': '/tempboat <player>',
	'permission': 'command.tempboat',
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		return(array());
	},
	'executor': closure(@alias, @sender, @args, @info) {
		if(is_null(@loc = get_command_block())) {
			die();
		}
		@loc = array(@loc[0] + 0.5, @loc[1] + 2, @loc[2] + 0.5, @loc[3]);
		@player = @args[0];
		if(@loc[3] != pworld(@player)) {
			die('This commandblock cannot set a player into a tempboat across worlds.');
		}
		@rider = puuid(@player);
		@boat = spawn_entity('boat', 1, @loc)[0];
		set_entity_rider(@boat, @rider);
		if(has_bind(@player.'vehicle_leave')) {
			die();
		}
		bind(vehicle_leave, array('id': @player.'vehicle_leave'), array('vehicletype': 'BOAT', 'passengertype': 'PLAYER'), @e, @player) {
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
		bind(player_quit, array(id: @player.'quit'), array('player': @player), @e, @boat) {
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
