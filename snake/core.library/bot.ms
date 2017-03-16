proc _snake_bot_update(@bot, @game) {
	@snake = @game['snakes'][@bot];
	@percent = rand(100);
	switch(@bot) {
	case 'Grumpy':
		if(!@snake['target']) {
			if(@snake['ability-count'][1] == 0 || !_snake_bot_target_snake(@snake, @game)) {
				_snake_bot_target_powerup(@snake, @game, 'missile');
			}
		} else if(@snake['target']['interest'] == 0) {
			@snake['target'] = null;
		}
		if(@snake['boost'] == 0 && @snake['ability-count'][0] > 0) {
			_snake_ability(@bot, 0, @game);
		}
		if(@snake['target']) {
			@snake['target']['interest']--;
			if(@snake['target']['type'] == 'snake') {
				@target = @snake['target']['name'];
				if(!array_index_exists(@game['snakes'], @target) || !@game['snakes'][@target]['alive']) {
					@snake['target'] = null;
				} else {
					@targetLoc = _relative(@game['snakes'][@target]['loc'], @game['snakes'][@target]['dir']);
					if(_snake_bot_change_dir(@snake, @snake['loc'], @targetLoc)) {
						if(_snake_opposite_dir(@snake['dir']) == @game['snakes'][@target]['dir']
						|| (@snake['ability-count'][1] > 1 && @snake['dir'] != @game['snakes'][@target]['dir'])) {
							@aligned = false;
							for(@i = 0, @i < 3, @i++) {
								if(@snake['loc'][@i] == @targetLoc[@i]) {
									if(@aligned) {
										_snake_ability(@bot, 1, @game);
										return();
									}
									@aligned = true;
								}
							}
						}
						return();
					}
				}
			} else {
				// go to target
				if(split(':', get_block_at(@snake['target']['loc']))[0] == '159') {
					@snake['target'] = null;
				} else if(_snake_bot_change_dir(@snake, @snake['loc'], @snake['target']['loc'])) {
					return();
				}
			}
		}
		if(!_snake_safe_path(@snake['loc'], @snake['top'], @snake['dir'], @game['missiles'])) {
			@dir = _snake_safe_dir(@snake);
			if(@dir == @snake['dir']) {
				_snake_ability(@bot, 1, @game);
			}
			@snake['last-dir'] = @snake['dir'];
			@snake['dir'] = @dir;
		}
	case 'BatSnake':
		if(!@snake['target']) {
			if(@snake['ability-count'][0] < 4) {
				if(!_snake_bot_target_powerup(@snake, @game, 'boost') && @snake['ability-count'][0]) {
					_snake_bot_target_snake(@snake, @game);
				}
			} else {
				_snake_bot_target_snake(@snake, @game);
			}
		} else if(@snake['target']['interest'] == 0) {
			@snake['target'] = null;
		}
		if(@snake['boost'] == 0 && @snake['ability-count'][0] > 0) {
			_snake_ability(@bot, 0, @game);
		}
		if(@snake['target']) {
			@snake['target']['interest']--;
			if(@snake['target']['type'] == 'snake') {
				@target = @snake['target']['name'];
				if(!array_index_exists(@game['snakes'], @target) || !@game['snakes'][@target]['alive']) {
					@snake['target'] = null;
				} else {
					@targetLoc = _relative(@game['snakes'][@target]['loc'], @game['snakes'][@target]['dir']);
					if(_snake_bot_change_dir(@snake, @snake['loc'], @targetLoc)) {
						return();
					}
				}
			} else {
				// go to target
				if(split(':', get_block_at(@snake['target']['loc']))[0] == '159') {
					@snake['target'] = null;
				} else if(_snake_bot_change_dir(@snake, @snake['loc'], @snake['target']['loc'])) {
					return();
				}
			}
		}
		if(!_snake_safe_path(@snake['loc'], @snake['top'], @snake['dir'], @game['missiles'])) {
			@dir = _snake_safe_dir(@snake);
			@snake['last-dir'] = @snake['dir'];
			@snake['dir'] = @dir;
		}
	case 'SharkBot':
		if(!@snake['target']) {
			_snake_bot_target_snake(@snake, @game);
		} else if(@snake['target']['interest'] == 0) {
			@snake['target'] = null;
		}
		if(@snake['target']) {
			@snake['target']['interest']--;
			@target = @snake['target']['name'];
			if(!array_index_exists(@game['snakes'], @target) || !@game['snakes'][@target]['alive']) {
				@snake['target'] = null;
			} else {
				@targetLoc = _relative(@game['snakes'][@target]['loc'], @game['snakes'][@target]['dir']);
				if(_snake_bot_change_dir(@snake, @snake['loc'], @targetLoc)) {
					if(@snake['ability-count'][1]) {
						@aligned = false;
						for(@i = 0, @i < 3, @i++) {
							if(@snake['loc'][@i] == @targetLoc[@i]) {
								if(@aligned) {
									_snake_ability(@bot, 1, @game);
									return();
								}
								@aligned = true;
							}
						}
					}
					return();
				}
			}
		}
		if(@percent < 10
		|| !_snake_safe_path(@snake['loc'], @snake['top'], @snake['dir'], @game['missiles'])) {
			@dir = _snake_safe_dir(@snake);
			@snake['last-dir'] = @snake['dir'];
			@snake['dir'] = @dir;
		}
	case 'CrazyBot':
		if(!@snake['target']) {
			if(@snake['ability-count'][2] < 3) {
				if(!_snake_bot_target_powerup(@snake, @game, 'tnt') && @snake['ability-count'][2]) {
					_snake_bot_target_snake(@snake, @game);
				}
			} else {
				_snake_bot_target_snake(@snake, @game);
			}
		} else if(@snake['target']['interest'] == 0) {
			@snake['target'] = null;
		}
		if(@snake['target']) {
			@snake['target']['interest']--;
			if(@snake['target']['type'] == 'snake') {
				@target = @snake['target']['name'];
				if(!array_index_exists(@game['snakes'], @target) || !@game['snakes'][@target]['alive']) {
					@snake['target'] = null;
				} else {
					@targetLoc = _relative(@game['snakes'][@target]['loc'], @game['snakes'][@target]['dir']);
					if(_snake_bot_change_dir(@snake, @snake['loc'], @targetLoc)) {
						if(@snake['top'] != 'up' && @snake['loc'][1] > @targetLoc[1]) {
							_snake_ability(@bot, 0, @game);
						}
						return();
					}
				}
			} else {
				// go to target
				if(split(':', get_block_at(@snake['target']['loc']))[0] == '159') {
					@snake['target'] = null;
				} else if(_snake_bot_change_dir(@snake, @snake['loc'], @snake['target']['loc'])) {
					return();
				}
			}
		}
		if(@game['tnt']) {
			foreach(@tnt in @game['tnt']) {
				@loc = entity_loc(@tnt);
				if(_distance(@snake['loc'], @loc) < 6) {
					@targetLoc = @snake['loc'][];
					@targetLoc[0] += @snake['loc'][0] - @loc[0];
					@targetLoc[1] += @snake['loc'][1] - @loc[1];
					@targetLoc[2] += @snake['loc'][2] - @loc[2];
					_snake_bot_change_dir(@snake, @snake['loc'], @targetLoc);
					return();
				}
			}
		} else if(!_snake_safe_path(@snake['loc'], @snake['top'], @snake['dir'], @game['missiles'])) {
			@dir = _snake_safe_dir(@snake);
			@snake['last-dir'] = @snake['dir'];
			@snake['dir'] = @dir;
		}
	}
}

proc _snake_bot_target_powerup(@snake, @game, @type = 'all') {
	@closest = 25;
	foreach(@powerup in @game['powerups']) {
		if(@type == 'all' || @powerup['type'] == @type) {
			@dist = _distance(@powerup['loc'], @snake['loc']);
			if(@dist < @closest) {
				@snake['target'] = associative_array('type': 'powerup', 'loc': @powerup['loc'], 'interest': 50);
				@closest = @dist;
			}
		}
	}
	return(is_array(@snake['target']));
}

proc _snake_bot_target_snake(@snake, @game) {
	@closest = 25;
	foreach(@bot: @othersnake in @game['snakes']) {
		if((@game['botsOnly'] && @snake['bot'] != @othersnake['bot'] || !@othersnake['bot']) && @othersnake['alive']) {
			@dist = _distance(@othersnake['loc'], @snake['loc']);
			if(@dist < @closest) {
				@snake['target'] = associative_array('type': 'snake', 'name': @bot, 'interest': 50);
				@closest = @dist;
			}
		}
	}
	return(is_array(@snake['target']));
}

proc _snake_bot_change_dir(@snake, @loc1, @loc2) {
	@x = @loc1[0] - @loc2[0];
	@y = @loc1[1] - @loc2[1];
	@z = @loc1[2] - @loc2[2];
	@dist = array();
	@dist[] = array('x', abs(@x));
	@dist[] = array('y', abs(@y));
	@dist[] = array('z', abs(@z));
	array_sort(@dist, closure(@left, @right) {
		return(@left[1] < @right[1]);
	});
	foreach(@d in @dist) {
		@dir = null;
		switch(@d[0]) {
			case 'x':
				if(@x > 0) {
					@dir = 'west';
				} else if(@x < 0) {
					@dir = 'east';
				}
			case 'z':
				if(@z > 0) {
					@dir = 'north';
				} else if(@z < 0) {
					@dir = 'south';
				}
			case 'y':
				if(@y > 0) {
					@dir = 'down';
				} else if(@y < 0) {
					@dir = 'up';
				}
		}
		if(@dir && @dir != @snake['dir']
		&& @dir != _snake_opposite_dir(@snake['dir'])
		&& _snake_safe_block(get_block_at(_relative(@loc1, @dir)))) {
			@snake['last-dir'] = @snake['dir'];
			@snake['dir'] = @dir;
			return(true);
		}
	}
	return(false);
}
