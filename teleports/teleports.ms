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
	if(@fromWorld != @toWorld && (!_is_survival_world(@fromWorld) || !_is_survival_world(@toWorld))) {
		if(@event['type'] == 'SPECTATE') {
			cancel();
			die(color('yellow').'You cannot spectate a player not in this dimension.');
		}
		set_timeout(50, closure(){
			@pdata = _pdata(player());
			@worlds = _worlds_config();
			@mode = @worlds[@fromWorld]['mode'];
			if(!array_index_exists(@pdata, @mode)) {
				@pdata[@mode] = associative_array();
			}
			@pdata[@mode]['loc'] = array(
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

	@vehicle = get_entity_vehicle(puuid());
	@type = entity_type(@vehicle);
	if(array_contains(array('DONKEY', 'HORSE', 'LLAMA', 'MULE', 'SKELETON_HORSE', 'ZOMBIE_HORSE'), @type)
	&& _is_survival_world(@fromWorld)
	&& _is_survival_world(@toWorld)) {
		set_timeout(50, closure(){
			try {
				set_entity_loc(@vehicle, @to);
				# a longer delay is necessary in 1.9 to reduce glitching
				set_timeout(100, closure(){
					set_entity_rider(@vehicle, puuid());
				});
			} catch(Exception @ex) {
				msg('Failed to teleport your horse with you.');
				console('Failed to teleport horse.', false);
			}
		});
	}
}

# Block enderpearls
bind(player_interact, null, array('item': 368, 'button': 'right'), @event) {
	if(pworld() === 'custom') {
		cancel();
	}
}
