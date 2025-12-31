if(!import('requests')) {
	@ignorelist = get_value('session.requests')
	if(!@ignorelist) {
		@ignorelist = associative_array();
	} else {
		clear_value('session.requests');
	}
	export('requests', @ignorelist);
}

/*
	Handles additional entity teleports when player teleports
	(and safer end gateway teleports from end islands)
 */
bind('player_teleport', null, null, @event) {
	@from = @event['from'];
	@to = @event['to'];
	@fromWorld = @from['world'];
	@toWorld = @to['world'];

	if(@event['type'] == 'END_GATEWAY') {
		if(get_block(location_shift(@from, 'east')) == 'END_GATEWAY'
		|| get_block(location_shift(@from, 'west')) == 'END_GATEWAY'
		|| get_block(location_shift(@from, 'north')) == 'END_GATEWAY'
		|| get_block(location_shift(@from, 'south')) == 'END_GATEWAY') {
			// This is a stargate, which will be handled on a separate plugin teleport event
			die();
		} else if(string_ends_with(@fromWorld, '_the_end')
		&& (abs(@from['x']) > 512 || abs(@from['z']) > 512)) {
			// coming from the ring islands, do a safe tp
			@to = get_spawn(@fromWorld);
			modify_event('to', @to);
		}
	} else if(@event['type'] == 'ENDER_PEARL' && @fromWorld == 'custom') {
		cancel();
	}

	if(_is_survival_world(@fromWorld) && _is_survival_world(@toWorld)) {
		if(@fromWorld == @toWorld && distance(@from, @to) < 6) {
			// ignore mount/dismount teleports
			die();
		}
		@uuid = null;
		try {
			@uuid = puuid();
		} catch(BadEntityException @ex) {
			// possibly teleported on join
			die();
		}

		@vehicle = get_entity_vehicle(@uuid);

		@leashedEntities = array();
		foreach(@e in entities_in_radius(@from, 16)) {
			@type = entity_type(@e);
			if((is_entity_living(@e) || string_ends_with(@type, 'BOAT') || string_ends_with(@type, 'RAFT'))
					&& get_leashholder(@e) == @uuid) {
				@leashedEntities[] = @e;
				set_leashholder(@e, null);
			}
		}

		if(@vehicle || @leashedEntities) {
			if(@vehicle != null) {
				@riders = get_entity_riders(@vehicle);
				set_entity_rider(@vehicle, null);
				set_entity_loc(@vehicle, @to);
				set_timeout(10, closure(){
					foreach(@rider in @riders) {
						set_entity_rider(@vehicle, @rider);
					}
				});
			}
			foreach(@e in @leashedEntities) {
				set_entity_loc(@e, @to);
				set_timeout(10, closure(){
					set_leashholder(@e, @uuid);
				});
			}
		}
	}
}
