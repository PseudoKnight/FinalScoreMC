proc _race_bind_events(@race) {
	@race['binds'][] = bind(entity_dismount, null, array('type': 'PLAYER'), @event, @race) {
		try {
			@player = player(@event['id']);
			if(array_index_exists(@race['players'], @player)) {
				@racer = @race['players'][@player];
				if(@racer['state'] == 'finished') {
					entity_remove(@event['mountid']);
				} else {
					cancel();
					if(@racer['horn'] + 500 < time()) {
						play_sound(entity_loc(@event['id']), array('sound': 'ENTITY_VILLAGER_YES'));
						@racer['horn'] = time();
					}
				}
			}
		} catch(PlayerOfflineException @ex) {
			// entity was not a player
		}
	}
	
	if(@race['type'] == 'boat' || @race['type'] == 'horse' || @race['type'] == 'pig') {
		@race['binds'][] = bind(vehicle_destroy, null, array('vehicletype': to_upper(@race['type'])), @event, @race) {
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

	@race['binds'][] = bind(player_quit, null, null, @event, @race) {
		if(array_index_exists(@race['players'], player())) {
			array_remove(@race['players'], player());
			@vehicle = get_entity_vehicle(puuid());
			if(@vehicle) {
				if(entity_type(@vehicle) == 'ARMOR_STAND') {
					entity_remove(@vehicle);
					@vehicle = get_entity_vehicle(puuid());
				}
				if(@vehicle) {
					entity_remove(@vehicle);
				}
			}
			set_ploc(@race['lobby']);
		}
	}
}

proc _race_unbind_events(@race) {
	foreach(@bind in @race['binds']) {
		unbind(@bind);
	}
}
