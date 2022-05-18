proc _race_bind_events(@race) {
	@race['binds'][] = bind('entity_dismount', null, array(type: 'PLAYER'), @event, @race) {
		try {
			@player = player(@event['id']);
			if(array_index_exists(@race['players'], @player) && entity_exists(@event['mountid'])) {
				set_timeout(1, closure(try(entity_remove(@event['mountid']))))
			}
		} catch(PlayerOfflineException @ex) {
			// entity was not a player
		}
	}

	@race['binds'][] = bind('player_toggle_sneak', null, array(sneaking: false, world: @race['world']), @event, @race) {
		if(array_index_exists(@race['players'], player())) {
			_race_place_player(@race, player(), @race['players'][player()]['loc']);
			if(@race['state'] == 'running') {
				set_timeout(1000, closure(){
					_race_drop_player(@race, player());
				});
			}
		}
	}

	if(@race['type'] == 'boat' || @race['type'] == 'horse' || @race['type'] == 'pig') {
		@race['binds'][] = bind('vehicle_destroy', null, array('vehicletype': to_upper(@race['type'])), @event, @race) {
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
			array_remove(@race['players'], player());
			@vehicle1 = get_entity_vehicle(puuid());
			if(@vehicle1) {
				if(entity_type(@vehicle1) != 'ARMOR_STAND') {
					@vehicle2 = get_entity_vehicle(@vehicle1);
					if(@vehicle2) {
						entity_remove(@vehicle2);
					}
				}
				entity_remove(@vehicle1);
			}
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
