proc _worms_add_player(@player, @game) {
	set_peffect(@player, 1, 4, 9999, true, false);
	set_peffect(@player, 14, 0, 9999, true, false);
	
	@game['players'][@player] = array(
		'segments': array(),
		'color': rand(16),
	);
	
	@loc = ploc(@player);
	@loc['pitch'] = 90.0;
	set_ploc(@player, @loc);

	set_pscoreboard(@player, 'worms');
}

proc _worms_spawn_player(@player, @game) {
	@worm = @game['players'][@player];
	@count = integer(20 / array_size(@game['players']));
	@worm['segments'] = _worms_create_segments(location_shift(ploc(@player), 'down'), @count, @worm['color'], @game);
}

proc _worms_remove_player(@player, @game) {
	foreach(@segment in @game['players'][@player]['segments']) {
		try(entity_remove(@segment));
	}
	array_remove(@game['players'], @player);
	if(pworld(@player) == @game['world']) {
		set_peffect(@player, 14, 0, 0);
		set_peffect(@player, 1, 0, 0);
	}
}

proc _worms_kill_player(@player, @game) {
	_worms_remove_player(@player, @game);
	if(array_size(@game['players']) <= 1) {
		_worms_end(@game);
	}
}

proc _worms_player_add_segments(@player, @segment, @game) {
	@worm = @game['players'][@player];
	if(is_array(@segment)) {
		@worm['segments'] = array_merge(@worm['segments'], @segment);
	} else {
		@worm['segments'][] = @segment;
	}
	@score = array_size(@worm['segments']);
	set_pscore('segments', @player, @score, 'worms');
	if(@score >= 50) {
		foreach(@p in array_keys(@game['players'])) {
			if(@p != @player) {
				_worms_kill_player(@p, @game);
			}
		}
	}
}
