// Returns a starting location within the world border
proc _get_spawn_location(@retries = 3) {
	@worldborder = get_world_border('shard');
	@width = @worldborder['width'];
	@loc = @worldborder['center'];
	@loc['x'] += rand() * @width - @width / 2;
	@loc['z'] += rand() * @width - @width / 2;
	@loc = get_highest_block_at(@loc);
	if(@retries && (@loc['y'] == 0 || get_block_at(@loc) == '9:0')) {
		@loc = _get_spawn_location(--@retries);
	}
	return(@loc);
}

// Returns team a player is in
proc _get_team(@player) {
	foreach(@team in get_teams('shard')) {
		if(array_contains(@team['players'], @player)) {
			return(@team['name']);
		}
	}
	return(null);
}

// Unloads the shard world and cleans-up data
proc _unload_shard() {
	@binds = import('shard.binds');
	export('shard.binds', null);
	
	// Scavenger Hunt clean-up
	export('shard.card', null);
	export('shard.colors', null);
	foreach(@chest in all_virtualchests()) {
		if(string_ends_with(@chest, 'card')) {
			del_virtualchest(@chest);
		}
	}
	
	if(extension_exists('CHDynmap')) {
		dm_delete_marker('markers', 'shard');
	}
	
	unbind('shard-worldchanged');
	foreach(@p in all_players()) {
		if(pworld(@p) == 'shard') {
			queue_push(closure(){
				if(pworld(@p) == 'shard') {
					@pdata = _pdata(@p);
					set_ploc(@p, @pdata['survival']['loc']);
				}
			}, 'shard');
		}
	}
	queue_push(closure(){
		if(!array_contains(get_worlds(), 'shard')) {
			die();
		}
		if(array_size(all_players('shard')) == 0 && unload_world('shard')) {
			remove_scoreboard('shard');
			array_remove(_worlds_config(), 'shard');
			_remove_activity('shard');
			foreach(@bind in @binds) {
				unbind(@bind);
			}
		} else {
			console('Failed to unload shard world!', false);
		}
	}, 'shard');
}
