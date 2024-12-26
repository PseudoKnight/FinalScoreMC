proc _race_bind_events(@race) {
	@race['binds'][] = bind('entity_dismount', null, array(type: 'PLAYER'), @event, @race) {
		try {
			@player = player(@event['id']);
			if(array_index_exists(@race['players'], @player)) {
				cancel();
				if(@race['type'] === 'pig') {
					play_sound(ploc(), array(sound: 'ENTITY_PIG_AMBIENT', pitch: 2 ** ((rand(25) - 12) / 12), volume: 1));
				} else if(@race['type'] !== 'kart') {
					play_sound(ploc(), array(sound: 'BLOCK_NOTE_BLOCK_CHIME', pitch: 2 ** ((rand(25) - 12) / 12), volume: 1));
				}
			}
		} catch(PlayerOfflineException @ex) {
			// entity was not a player
		}
	}

	if(@race['type'] === 'boat' || @race['type'] === 'horse' || @race['type'] === 'pig') {
		@race['binds'][] = bind('vehicle_destroy', null, array(vehicletype: to_upper(@race['type'])), @event, @race) {
			@rider = get_entity_rider(@event['vehicle']);
			if(@rider) {
				try {
					@player = player(@rider);
					if(array_index_exists(@race['players'], @player)) {
						cancel();
					}
				} catch(PlayerOfflineException @ex) {
					// entity rider was not a player
				}
			}
		}
	}

	@race['binds'][] = bind('player_quit', null, null, @event, @race) {
		if(array_index_exists(@race['players'], player())) {
			_race_remove_vehicle(player(), @race);
			array_remove(@race['players'], player());
			set_ploc(@race['lobby']);
			_race_check_players(@race);
		}
	}

	@race['binds'][] = bind('player_command', null, null, @event, @race) {
		if(array_index_exists(@race['players'], player())
		&& array_contains(array('/accept', '/warp', '/spawn', '/home', '/join', '/dev', '/park', '/survival', '/tpa'), @event['prefix'])) {
			_race_remove_player(@race, player());
			_race_check_players(@race);
		}
	}
}

proc _race_unbind_events(@race) {
	foreach(@bind in @race['binds']) {
		unbind(@bind);
	}
}
