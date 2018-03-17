proc _worms_spawn(@player, @game) {
	@worm = @game['players'][@player];
	@count = integer(20 / array_size(@game['players']));
	@worm['segments'] = _worms_create_segments(location_shift(ploc(@player), 'down'), @count, @worm['color'], @game);
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
	if(@score >= 50) {
		foreach(@p in array_keys(@game['players'])) {
			if(@p != @player) {
				_worms_kill(@p, @game);
			}
		}
	}
}
