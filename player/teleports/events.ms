if(!import('requests')) {
	@ignorelist = get_value('session.requests')
	if(!@ignorelist) {
		@ignorelist = associative_array();
	} else {
		clear_value('session.requests');
	}
	export('requests', @ignorelist);
}

# Main teleport handler
bind('player_teleport', null, null, @event) {
	@from = @event['from'];
	@to = @event['to'];
	@fromWorld = @from['world'];
	@toWorld = @to['world'];

	if(@event['type'] == 'END_GATEWAY') {
		if(@fromWorld == 'world_the_end'
		&& (get_block(location_shift(@from, 'east')) == 'END_GATEWAY'
		|| get_block(location_shift(@from, 'west')) == 'END_GATEWAY'
		|| get_block(location_shift(@from, 'north')) == 'END_GATEWAY'
		|| get_block(location_shift(@from, 'south')) == 'END_GATEWAY')) {
			// this is probably a stargate in the end
			cancel();
			die();
		} else if(abs(@from['x']) > 512 || abs(@from['z']) > 512) {
			// coming from the ring islands, do a safe tp
			@to = get_spawn(@fromWorld);
			modify_event('to', @to);
		}
	} else if(@event['type'] == 'ENDER_PEARL' && @fromWorld == 'custom') {
		cancel();
	}

	if(_is_survival_world(@fromWorld) && _is_survival_world(@toWorld)) {
		@uuid = puuid();

		@vehicle = null;
		try {
			@vehicle = get_entity_vehicle(@uuid);
		} catch(BadEntityException @ex) {
			die();
		}
		@type = entity_type(@vehicle);
		if(array_contains(array('DONKEY', 'HORSE', 'LLAMA', 'MULE', 'SKELETON_HORSE', 'ZOMBIE_HORSE', 'STRIDER'), @type)) {
			set_timeout(1, closure(){
				try {
					set_entity_loc(@vehicle, @to);
					set_timeout(1, closure(){
						set_entity_rider(@vehicle, @uuid);
					});
				} catch(Exception @ex) {
					msg('Failed to teleport your horse with you.');
					console('Failed to teleport horse.', false);
				}
			});
		}

		// Teleport leashed entities with player
		@item = pinv(player(), null);
		if(@item && @item['name'] == 'LEAD') {
			@entities = array();
			foreach(@e in entities_in_radius(@from, 8)) {
				if(is_entity_living(@e) && get_leashholder(@e) == @uuid) {
					@entities[] = @e;
					set_leashholder(@e, null);
				}
			}
			try {
				load_chunk(@from); // keep chunks loaded
				set_timeout(50, closure(){
					foreach(@e in @entities) {
						set_entity_loc(@e, @to);
						set_leashholder(@e, @uuid);
					}
					unload_chunk(@from);
				});
			} catch(Exception @ex) {
				msg('Failed to teleport some leashed mobs with you.');
				console('Failed to teleport some leashed mobs.', false);
			}
		}
	}
}
