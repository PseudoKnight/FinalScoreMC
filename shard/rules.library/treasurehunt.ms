proc _create_treasure(@delay, @rules) {
	set_timeout(@delay * 1000, closure(){
		@worldborder = get_world_border('shard');
		@width = max(1, @worldborder['width'] - @rules['width'] / @rules['treasurehunt']);
		@loc = @worldborder['center'];
		@loc['x'] += rand() * @width - @width / 2;
		@loc['y'] = rand(4, 62);
		@loc['z'] += rand() * @width - @width / 2;
		set_block_at(@loc, 130);
		set_metadata(@loc, 'treasure', 1);
		set_world_border('shard', array('width': @width, 'seconds': 300));
		foreach(@p in all_players()) {
			if(pworld(@p) == 'shard') {
				set_compass_target(@p, @loc);
				tmsg(@p, 'The treasure is at '.integer(@loc['x']).' '.integer(@loc['y']).' '.integer(@loc['z']).'!');
			}
		}
	});
}

proc _end_treasurehunt(@winner, @binds) {
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
	});
}

create_objective('Treasures', 'DUMMY', 'shard');
set_objective_display('Treasures', array('slot': 'SIDEBAR'), 'shard');
_create_treasure(max(5, 60 * @rules['buffertime']), @rules);

@binds[] = 'shard-break';
bind(block_break, array('id': 'shard-break'), array('type': 130), @event, @rules, @binds) {
	if(has_metadata(@event['location'], 'treasure')) {
		play_sound(@event['location'], array('sound': 'LEVEL_UP', 'pitch': 0.7));
		foreach(@p in all_players()) {
			if(pworld(@p) == 'shard') {
				tmsg(@p, player().' has found the treasure!');
			}
		}
		if(@rules['teams']) {
			@team = _get_team(player());
			@score = get_pscore('Treasures', @team, 'shard') + 1;
			set_pscore('Treasures', @team, @score, 'shard');
			if(@score == @rules['treasurehunt']) {
				_end_treasurehunt(@team, @binds);
				die();
			}
		} else {
			@score = get_pscore('Treasures', player(), 'shard') + 1;
			set_pscore('Treasures', player(), @score, 'shard');
			if(@score == @rules['treasurehunt']) {
				_end_treasurehunt(player(), @binds);
				die();
			}
		}
		remove_metadata(@event['location'], 'treasure');
		_create_treasure(60, @rules);
	}
}
