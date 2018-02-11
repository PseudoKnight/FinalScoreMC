proc _snake_bots() {
	return(array('Grumpy','BatSnake','SharkBot','CrazyBot', 'NinjaBot'));
}

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
					@targetLoc = location_shift(@game['snakes'][@target]['loc'], @game['snakes'][@target]['dir']);
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
				if(_is_snake_tail(get_block_at(@snake['target']['loc']))) {
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
			} else {
				@snake['turned'] = true;
			}
			@snake['last-dir'] = @snake['dir'];
			@snake['dir'] = @dir;
		}
	case 'BatSnake':
		if(!@snake['target']) {
			if(@snake['ability-count'][0] < 4) {
				if(!_snake_bot_target_powerup(@snake, @game, 'boost')
				&& !_snake_bot_target_powerup(@snake, @game, 'missile')
				&& @snake['ability-count'][0]) {
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
					@targetLoc = location_shift(@game['snakes'][@target]['loc'], @game['snakes'][@target]['dir']);
					if(_snake_bot_change_dir(@snake, @snake['loc'], @targetLoc)) {
						return();
					}
				}
			} else {
				// go to target
				if(_is_snake_tail(get_block_at(@snake['target']['loc']))) {
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
			} else {
				@snake['turned'] = true;
			}
			@snake['last-dir'] = @snake['dir'];
			@snake['dir'] = @dir;
		}
	case 'SharkBot':
		if(!@snake['target']) {
			if(!(!@snake['ability-count'][0] && _snake_bot_target_powerup(@snake, @game, 'boost')
			|| !@snake['ability-count'][1] && _snake_bot_target_powerup(@snake, @game, 'missile')
			|| !@snake['ability-count'][2] && _snake_bot_target_powerup(@snake, @game, 'tnt')
			|| !@snake['ability-count'][3] && _snake_bot_target_powerup(@snake, @game, 'laser'))) {
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
					@targetLoc = location_shift(@game['snakes'][@target]['loc'], @game['snakes'][@target]['dir']);
					if(_snake_bot_change_dir(@snake, @snake['loc'], @targetLoc)) {
						if(@snake['ability-count'][3] && @snake['dir'] != @game['snakes'][@target]['dir']) {
							@aligned = false;
							for(@i = 0, @i < 3, @i++) {
								if(@snake['loc'][@i] == @targetLoc[@i]) {
									if(@aligned) {
										_snake_ability(@bot, 3, @game);
										return();
									}
									@aligned = true;
								}
							}
						} else if(@snake['top'] != 'up' && @snake['loc'][1] > @targetLoc[1]) {
							_snake_ability(@bot, 2, @game);
						}
						return();
					}
				}
			} else {
				// go to target
				if(_is_snake_tail(get_block_at(@snake['target']['loc']))) {
					@snake['target'] = null;
				} else if(_snake_bot_change_dir(@snake, @snake['loc'], @snake['target']['loc'])) {
					return();
				}
			}
		}
		if(@percent < 10
		|| !_snake_safe_path(@snake['loc'], @snake['top'], @snake['dir'], @game['missiles'])) {
			@dir = _snake_safe_dir(@snake);
			if(@dir == @snake['dir']) {
				_snake_ability(@bot, 1, @game);
			} else {
				@snake['turned'] = true;
			}
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
					@targetLoc = location_shift(@game['snakes'][@target]['loc'], @game['snakes'][@target]['dir']);
					if(_snake_bot_change_dir(@snake, @snake['loc'], @targetLoc)) {
						if(@snake['top'] != 'up' && @snake['loc'][1] > @targetLoc[1]) {
							_snake_ability(@bot, 0, @game);
						}
						return();
					}
				}
			} else {
				// go to target
				if(_is_snake_tail(get_block_at(@snake['target']['loc']))) {
					@snake['target'] = null;
				} else if(_snake_bot_change_dir(@snake, @snake['loc'], @snake['target']['loc'])) {
					return();
				}
			}
		}
		if(@game['tnt']) {
			foreach(@i: @tnt in @game['tnt']) {
				try {
					@loc = entity_loc(@tnt);
					if(_distance(@snake['loc'], @loc) < 6) {
						@targetLoc = @snake['loc'][];
						@targetLoc[0] += @snake['loc'][0] - @loc[0];
						@targetLoc[1] += @snake['loc'][1] - @loc[1];
						@targetLoc[2] += @snake['loc'][2] - @loc[2];
						_snake_bot_change_dir(@snake, @snake['loc'], @targetLoc);
						return();
					}
				} catch(BadEntityException @ex) {
					array_remove(@game['tnt'], @i);
				}
			}
		} else if(!_snake_safe_path(@snake['loc'], @snake['top'], @snake['dir'], @game['missiles'])) {
			@dir = _snake_safe_dir(@snake);
			@snake['last-dir'] = @snake['dir'];
			@snake['dir'] = @dir;
			@snake['turned'] = true;
		}
	case 'NinjaBot':
		if(!@snake['target']) {
			if(!_snake_bot_target_powerup(@snake, @game)) {
				_snake_bot_target_snake(@snake, @game);
			}
		} else if(@snake['target']['interest'] == 0) {
			@snake['target'] = null;
		}
		@randAbility = rand(5);
		if(@snake['ability-count'][@randAbility] > 0 && (@randAbility != 0 || @snake['boost'] == 0)) {
			_snake_ability(@bot, @randAbility, @game);
		}
		if(@snake['target']) {
			@snake['target']['interest']--;
			if(@snake['target']['type'] == 'snake') {
				@target = @snake['target']['name'];
				if(!array_index_exists(@game['snakes'], @target) || !@game['snakes'][@target]['alive']) {
					@snake['target'] = null;
				} else {
					@targetLoc = location_shift(@game['snakes'][@target]['loc'], @game['snakes'][@target]['dir']);
					_snake_bot_change_dir(@snake, @snake['loc'], @targetLoc);
				}
			} else {
				// go to target
				if(_is_snake_tail(get_block_at(@snake['target']['loc']))) {
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
			@snake['turned'] = true;
		}
	}
}

proc _snake_bot_target_powerup(@snake, @game, @type = 'all') {
	@closest = 25;
	foreach(@powerup in @game['powerups']) {
		if(!array_contains(@game['nukes'], @powerup['region']) && (@type == 'all' || @powerup['type'] == @type)) {
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
	if(array_index_exists(@snake, 'team') && is_string(@game['flags'][@snake['team']])) {
		@snake['target'] = array('type': 'snake', 'name': @game['flags'][@snake['team']], 'interest': 50);
	} else {
		foreach(@bot: @othersnake in @game['snakes']) {
			if(!array_contains(@game['nukes'], @othersnake['region'])
			&& @othersnake['alive']
			&& ((@game['botsOnly'] && @snake['bot'] != @othersnake['bot'] || !@othersnake['bot'])
			|| (!array_index_exists(@snake, 'team') || @snake['team'] != @othersnake['team']))) {
				@dist = _distance(@othersnake['loc'], @snake['loc']);
				if(@dist < @closest) {
					@snake['target'] = array('type': 'snake', 'name': @bot, 'interest': 50);
					@closest = @dist;
				}
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
		&& _snake_safe_block(get_block_at(location_shift(@loc1, @dir)))) {
			@snake['last-dir'] = @snake['dir'];
			@snake['dir'] = @dir;
			@snake['turned'] = true;
			return(true);
		}
	}
	return(false);
}
