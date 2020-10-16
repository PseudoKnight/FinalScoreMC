// Returns a starting location within the world border
proc _get_spawn_location(@retries = 3) {
	@worldborder = get_world_border('shard');
	@width = @worldborder['width'];
	@loc = @worldborder['center'];
	@loc['x'] += rand() * @width - @width / 2;
	@loc['z'] += rand() * @width - @width / 2;
	@loc = get_highest_block_at(@loc);
	if(@retries && (@loc['y'] == 0)) {
		@loc = _get_spawn_location(--@retries);
	}
	return(@loc);
}

// Unloads the shard world and cleans-up data
proc _unload_shard() {
	@game = import('shard');
	
	// Scavenger Hunt clean-up
	export('shard.card', null);
	export('shard.colors', null);
	foreach(@chest in get_virtual_inventories()) {
		if(string_ends_with(@chest, 'card')) {
			delete_virtual_inventory(@chest);
		}
	}
	
	try {
		if(extension_exists('CHDynmap')) {
			dm_delete_marker('markers', 'shard');
		}
	} catch(NotFoundException @ex) {
		// shard probably doesn't exist, but continue anyway
	}
	
	unbind('shard-worldchanged');
	foreach(@p in all_players()) {
		if(pworld(@p) == 'shard') {
			queue_push(closure(){
				if(pworld(@p) == 'shard') {
					@pdata = _pdata(@p);
					set_entity_fall_distance(puuid(@p), 0);
					set_ploc(@p, @pdata['survival']['loc']);
				}
			}, 'shard');
		}
	}
	queue_push(closure(){
		if(!array_contains(get_worlds(), 'shard')) {
			die();
		}
		if(array_size(all_players('shard')) == 0 && _unload_world('shard', false)) {
			remove_scoreboard('shard');
			_remove_activity('shard');
			foreach(@bind in @game['binds']) {
				unbind(@bind);
			}
			export('shard', null);
		} else {
			console('Failed to unload shard world!', false);
		}
	}, 'shard');
}
