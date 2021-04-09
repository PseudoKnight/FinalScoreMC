proc _create_treasure(@delay, @score, @rules) {
	set_timeout(@delay, closure(){
		set_objective_display('Distance', array('slot': 'SIDEBAR'), 'shard');
		@worldborder = get_world_border('shard');
		@width = max(32, @worldborder['width'] - @rules['width'] / (4 - @score));
		@loc = @worldborder['center'];
		@loc['x'] += rand() * @width - @width / 2;
		@loc['y'] = rand(4, 62);
		@loc['z'] += rand() * @width - @width / 2;
		set_block(@loc, 'ENDER_CHEST');
		set_metadata(@loc, 'treasure', 1);
		set_world_border('shard', array('width': @width, 'seconds': 300));
		foreach(@p in all_players()) {
			if(pworld(@p) == 'shard') {
				set_compass_target(@p, @loc);
				play_sound(ploc(@p), array('sound': 'ENTITY_ARROW_HIT_PLAYER'), @p);
			}
		}
		set_interval(1000, closure(){
			if(!array_contains(get_worlds(), 'shard') || get_block(@loc) != 'ENDER_CHEST') {
				clear_task();
			}
			foreach(@p in all_players()) {
				if(pworld(@p) == 'shard' && get_pscoreboard(@p) == 'shard') {
					@dist = integer(distance(@loc, ploc(@p)));
					set_pscore('Distance', @p, @dist, 'shard');
				}
			}
		});
	});
}

proc _end_treasurehunt(@winner) {
	if(ponline(@winner)) {
		_worldmsg('shard', color('green').@winner.' wins!');
	} else {
		@teams = get_teams('shard');
		@color = '';
		foreach(@team in @teams) {
			if(@winner == @team['name']) {
				@color = @team['prefix'];
				break();
			}
		}
		_worldmsg('shard', @color.@winner.' wins!');
	}

	set_timeout(20000, closure(){
		_unload_shard();
	});
}

create_objective('Treasures', 'DUMMY', 'shard');
set_objective_display('Treasures', array('slot': 'SIDEBAR', 'displayname': 'Treasures (3)'), 'shard');
create_objective('Distance', 'DUMMY', 'shard');
_create_treasure(max(5, @rules['buffertime']), 0, @rules);

@binds[] = 'shard-break';
bind('block_break', array('id': 'shard-break'), array('block': 'ENDER_CHEST'), @event, @rules) {
	if(has_metadata(@event['location'], 'treasure')) {
		play_sound(@event['location'], array('sound': 'ENTITY_PLAYER_LEVELUP', 'pitch': 0.7));
		set_objective_display('Treasures', array('slot': 'SIDEBAR'), 'shard');
		broadcast(player().' has found the treasure!', all_players('shard'));
		@score = 0;
		if(@rules['teams']) {
			@team = get_pteam(player(), 'shard')['name'];
			@score = get_pscore('Treasures', @team, 'shard') + 1;
			set_pscore('Treasures', @team, @score, 'shard');
			if(@score == 3) {
				_end_treasurehunt(@team);
				die();
			}
		} else {
			@score = get_pscore('Treasures', player(), 'shard') + 1;
			set_pscore('Treasures', player(), @score, 'shard');
			if(@score == 3) {
				_end_treasurehunt(player());
				die();
			}
		}
		remove_metadata(@event['location'], 'treasure');
		_create_treasure(60, @score, @rules);
	}
}
