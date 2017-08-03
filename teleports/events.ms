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
bind(player_teleport, null, null, @event) {
	@from = @event['from'];
	@to = @event['to'];
	@fromWorld = @from['world'];
	@toWorld = @to['world'];
	if(@fromWorld != @toWorld) {
		@worlds = _worlds_config();
		@fromGroup = @worlds[@fromWorld]['group'];
		@toGroup = @worlds[@toWorld]['group'];
		if(@fromGroup != @toGroup) {
			if(@event['type'] == 'SPECTATE') {
				cancel();
				die(color('yellow').'You cannot spectate a player not in this dimension.');
			}
			if(@fromWorld != 'shard') { // temporary world, don't save location
				set_timeout(50, closure(){
					@pdata = _pdata(player());
					if(!array_index_exists(@pdata, @fromGroup)) {
						@pdata[@fromGroup] = associative_array();
					}
					@pdata[@fromGroup]['loc'] = array(
						round(@from['x'], 3),
						round(@from['y'], 3) - 1,
						round(@from['z'], 3),
						@from['world'],
						round(@from['yaw'], 1),
						round(@from['pitch'], 1),
					);
					_store_pdata(player(), @pdata);
				});
			}
		}
	} else if(@event['type'] == 'END_GATEWAY' && @fromWorld == 'world_the_end') {
		if(get_block_at(_relative(@from, 'east')) == '209:0'
		|| get_block_at(_relative(@from, 'west')) == '209:0'
		|| get_block_at(_relative(@from, 'north')) == '209:0'
		|| get_block_at(_relative(@from, 'south')) == '209:0') {
			cancel();
			die();
		} else if(abs(@from['x']) > 512 || abs(@from['z']) > 512) {
			// coming from the ring islands, do a safe tp
			cancel();
			set_ploc(get_spawn(@fromWorld));
		}
	}
	
	try {
		@uuid = puuid();
		
		// Teleport living vehicle with player
		@vehicle = get_entity_vehicle(@uuid);
		@type = entity_type(@vehicle);
		if(array_contains(array('DONKEY', 'HORSE', 'LLAMA', 'MULE', 'SKELETON_HORSE', 'ZOMBIE_HORSE'), @type)
		&& _is_survival_world(@fromWorld) && _is_survival_world(@toWorld)) {
			set_timeout(50, closure(){
				try {
					set_entity_loc(@vehicle, @to);
					set_timeout(50, closure(){
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
		if(@item && @item['name'] = 'LEASH') {
			@entities = array();
			foreach(@e in entities_in_radius(@from, 7)) {
				if(get_leashholder(@e) == @uuid) {
					@entities[] = @e;
					set_leashholder(@e, null);
				}
			}
			set_timeout(50, closure(){
				foreach(@e in @entities) {
					set_entity_loc(@e, @to);
					set_leashholder(@e, @uuid);
				}
			});
		}
	} catch(BadEntityException @ex) {
		// sometimes player doesn't have UUID during this event
	}
}

# Block enderpearls
bind(player_interact, null, array('item': 368, 'button': 'right'), @event) {
	if(pworld() === 'custom') {
		cancel();
	}
}
