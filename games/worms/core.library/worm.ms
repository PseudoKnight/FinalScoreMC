proc _worms_spawn(@player, @game) {
	@worm = @game['players'][@player];
	@count = integer(20 / array_size(@game['players']));
	@worm['segments'] = _worms_create_segments(location_shift(ploc(@player), 'down', @game['height']), @count, @worm['color'], @game);
}

proc _worms_kill(@player, @game) {
	_worms_remove_player(@player, @game);
	if(array_size(@game['players']) <= 1) {
		_worms_end(@game);
	}
}

proc _worms_add_segments(@player, @segment, @game) {
	@worm = @game['players'][@player];
	if(is_array(@segment)) {
		@worm['segments'] = array_merge(@worm['segments'], @segment);
	} else {
		@worm['segments'][] = @segment;
	}
	@score = array_size(@worm['segments']);
	set_pscore('segments', @player, @score, 'worms');
	if(@score >= 35) {
		team_add_player('leaders', @player, 'worms');
		play_sound(ploc(@player), array(sound: 'BLOCK_NOTE_BLOCK_BIT', pitch: 0.5 + (@score - 35) / 10));
		if(@score >= 50) {
			foreach(@p in array_keys(@game['players'])) {
				title(@p, @player.' achieved 50 segments!', '');
				if(@p != @player) {
					_worms_kill(@p, @game);
				}
			}
		}
	} else {
		team_remove_player('leaders', @player, 'worms');
	}
}
