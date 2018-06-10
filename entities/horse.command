register_command('horse', array(
	'description': 'Spawns a temporary race horse.',
	'usage': '/horse',
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		return(array());
	},
	'executor': closure(@alias, @sender, @args, @info) {
		if(pmode() !== 'CREATIVE' || get_entity_vehicle(puuid())) {
			die(color('gold').'You are not in creative mode.');
		}
		@horse = spawn_entity('horse', 1, location_shift(ploc(), 'up'))[0];
		set_mob_age(@horse, 0);
		tame_mob(@horse);
		set_entity_spec(@horse, array('jump': 0.8, 'saddle': array('name': 'saddle')));
		set_entity_rider(@horse, puuid());
	
		bind('vehicle_leave', array('id': player().'horse_leave'), array('vehicletype': 'HORSE', 'passengertype': 'PLAYER'),
				@e, @player = player()) {
	
			if(@e['player'] == @player) {
				unbind();
				unbind(@player.'horse_quit');
				try {
					entity_remove(@e['vehicle']);
				} catch(BadEntityException @ex) {
					// horse removed already or unloaded
				}
			}
		}
	
		bind('player_quit', array('id': player().'horse_quit'), array('player': player()), @e, @horse) {
			unbind();
			unbind(player().'horse_leave');
			try {
				entity_remove(@horse);
			} catch(BadEntityException @ex) {
				// horse removed already or unloaded
			}
		}
	}
));
