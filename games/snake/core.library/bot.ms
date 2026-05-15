proc _snake_bots() {
	return(array(
		Grumpy: 'LIME_TERRACOTTA',
		BatSnake: 'LIGHT_BLUE_TERRACOTTA',
		SharkBot: 'LIGHT_BLUE_CONCRETE',
		CrazyBot: 'PINK_TERRACOTTA',
		NinjaBot: 'LIME_CONCRETE'));
}

proc _snake_bot_update(@bot, @game) {
	@snake = @game['snakes'][@bot];
	@percent = rand(100);
	switch(@bot) {
	case 'Grumpy':
		_snake_bot_lose_interest(@snake, @game);
		if(!@snake['target']) {
			if(@snake['ability-count'][1] == 0 || !_snake_bot_target_snake(@snake, @game)) {
				_snake_bot_target_powerup(@snake, @game, 'missile');
			}
		}
		if(@snake['boost'] <= 0 && @snake['ability-count'][0] > 0) {
			_snake_ability(@bot, 0, @game);
		}
		if(@snake['target']) {
			if(@snake['target']['type'] === 'snake') {
				@target = @snake['target']['name'];
				@targetLoc = location_shift(@game['snakes'][@target]['loc'], @game['snakes'][@target]['dir']);
				if(_snake_bot_change_dir(@snake, @snake['loc'], @targetLoc)) {
					if(_snake_opposite_dir(@snake['dir']) === @game['snakes'][@target]['dir']
					|| (@snake['ability-count'][1] > 1 && @snake['dir'] !== @game['snakes'][@target]['dir'])) {
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
			} else if(_snake_bot_change_dir(@snake, @snake['loc'], @snake['target']['loc'])) {
				return();
			}
		}
		if(!_snake_safe_path(@snake, @game['missiles'])
		&& !_snake_bot_safe_turn(@snake, @game)) {
			_snake_ability(@bot, 1, @game);
		}
	case 'BatSnake':
		_snake_bot_lose_interest(@snake, @game);
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
		}
		if(@snake['boost'] <= 0 && @snake['ability-count'][0] > 0) {
			_snake_ability(@bot, 0, @game);
		}
		if(@snake['target']) {
			if(@snake['target']['type'] === 'snake') {
				@target = @snake['target']['name'];
				@targetLoc = location_shift(@game['snakes'][@target]['loc'], @game['snakes'][@target]['dir']);
				if(_snake_bot_change_dir(@snake, @snake['loc'], @targetLoc)) {
					return();
				}
			} else if(_snake_bot_change_dir(@snake, @snake['loc'], @snake['target']['loc'])) {
				return();
			}
		}
		if(!_snake_safe_path(@snake, @game['missiles'])
		&& !_snake_bot_safe_turn(@snake, @game)) {
			_snake_ability(@bot, 1, @game);
		}
	case 'SharkBot':
		_snake_bot_lose_interest(@snake, @game);
		if(!@snake['target']) {
			if(!(!@snake['ability-count'][0] && _snake_bot_target_powerup(@snake, @game, 'boost')
			|| !@snake['ability-count'][1] && _snake_bot_target_powerup(@snake, @game, 'missile')
			|| !@snake['ability-count'][2] && _snake_bot_target_powerup(@snake, @game, 'tnt')
			|| !@snake['ability-count'][3] && _snake_bot_target_powerup(@snake, @game, 'laser'))) {
				_snake_bot_target_snake(@snake, @game);
			}
		}
		if(@snake['boost'] <= 0 && @snake['ability-count'][0] > 0) {
			_snake_ability(@bot, 0, @game);
		}
		if(@snake['target']) {
			if(@snake['target']['type'] === 'snake') {
				@target = @snake['target']['name'];
				@targetLoc = location_shift(@game['snakes'][@target]['loc'], @game['snakes'][@target]['dir']);
				if(_snake_bot_change_dir(@snake, @snake['loc'], @targetLoc)) {
					if(@snake['ability-count'][3] && @snake['dir'] !== @game['snakes'][@target]['dir']) {
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
					} else if(@snake['top'] !== 'up' && @snake['loc'][1] > @targetLoc[1]) {
						_snake_ability(@bot, 2, @game);
					}
					return();
				}
			} else if(_snake_bot_change_dir(@snake, @snake['loc'], @snake['target']['loc'])) {
				return();
			}
		}
		if(@percent < 10
		|| !_snake_safe_path(@snake, @game['missiles'])
		&& !_snake_bot_safe_turn(@snake, @game)) {
			_snake_ability(@bot, 1, @game);
		}
	case 'CrazyBot':
		_snake_bot_lose_interest(@snake, @game);
		if(!@snake['target']) {
			if(@snake['ability-count'][2] < 3) {
				if(!_snake_bot_target_powerup(@snake, @game, 'tnt') && @snake['ability-count'][2]) {
					_snake_bot_target_snake(@snake, @game);
				}
			} else {
				_snake_bot_target_snake(@snake, @game);
			}
		}
		if(@snake['target']) {
			if(@snake['target']['type'] == 'snake') {
				@target = @snake['target']['name'];
				@targetLoc = location_shift(@game['snakes'][@target]['loc'], @game['snakes'][@target]['dir']);
				if(_snake_bot_change_dir(@snake, @snake['loc'], @targetLoc)) {
					@deltaY = @snake['loc'][1] - @targetLoc[1];
					if(@deltaY > 0) {
						@deltaXZ = max(abs(@snake['loc'][0] - @targetLoc[0]), abs(@snake['loc'][2] - @targetLoc[2]));
						if(@snake['dir'] === 'down' && @deltaY > @deltaXZ
						|| @snake['dir'] !== 'down' && @snake['dir'] !== 'up' && @deltaY <= @deltaXZ) {
							_snake_ability(@bot, 2, @game);
						}
					}
					return();
				}
			} else if(_snake_bot_change_dir(@snake, @snake['loc'], @snake['target']['loc'])) {
				return();
			}
		}
		if(@game['tnt']) {
			foreach(@i: @tnt in @game['tnt']) {
				try {
					@loc = entity_loc(@tnt);
					if(distance(@snake['loc'], @loc) < 6) {
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
		}
		if(!_snake_safe_path(@snake, @game['missiles'])
		&& !_snake_bot_safe_turn(@snake, @game)) {
			_snake_ability(@bot, 2, @game);
		}
	case 'NinjaBot':
		_snake_bot_lose_interest(@snake, @game);
		if(!@snake['target']) {
			if(!_snake_bot_target_powerup(@snake, @game)) {
				_snake_bot_target_snake(@snake, @game);
			}
		}
		@randAbility = rand(5);
		if(@snake['ability-count'][@randAbility] > 0 && (@randAbility > 0 || @snake['boost'] <= 0)) {
			_snake_ability(@bot, @randAbility, @game);
		}
		if(@snake['target']) {
			if(@snake['target']['type'] === 'snake') {
				@target = @snake['target']['name'];
				@targetLoc = location_shift(@game['snakes'][@target]['loc'], @game['snakes'][@target]['dir']);
				if(_snake_bot_change_dir(@snake, @snake['loc'], @targetLoc)) {
					return();
				}
			} else if(_snake_bot_change_dir(@snake, @snake['loc'], @snake['target']['loc'])) {
				return();
			}
		}
		if(!_snake_safe_path(@snake, @game['missiles'])) {
			_snake_bot_safe_turn(@snake, @game);
		}
	}
}

proc _snake_bot_target_powerup(@snake, @game, @type = 'all') {
	@closest = 25;
	foreach(@powerup in @game['powerups']) {
		if(!array_contains(@game['nukes'], @powerup['region']) && (@type === 'all' || @powerup['type'] === @type)) {
			@dist = distance(@powerup['loc'], @snake['loc']);
			if(@dist < @closest) {
				@snake['target'] = array(
					type: 'powerup',
					loc: @powerup['loc'],
					region: @powerup['region'],
					interest: 50);
				@closest = @dist;
			}
		}
	}
	if(@game['debug'] && is_array(@snake['target'])) {
		set_entity_spec(@snake['debug'], array(text: @type));
	}
	return(is_array(@snake['target']));
}

proc _snake_bot_target_snake(@snake, @game) {
	@closest = 25;
	if(array_index_exists(@snake, 'team') && is_string(@game['flags'][@snake['team']])) {
		@team = @snake['team'];
		@snake['target'] = array(
			type: 'snake',
			name: @game['flags'][@team],
			interest: 50);
	} else {
		foreach(@bot: @othersnake in @game['snakes']) {
			if(!array_contains(@game['nukes'], @othersnake['region'])
			&& @othersnake['alive']
			&& @snake['bot'] !== @othersnake['bot']
			&& (@game['botsOnly'] || !@othersnake['bot'])
			&& (!array_index_exists(@snake, 'team') || @snake['team'] != @othersnake['team'])) {
				@dist = distance(@othersnake['loc'], @snake['loc']);
				if(@dist < @closest) {
					@snake['target'] = array(
						type: 'snake',
						name: @bot,
						interest: 50);
					@closest = @dist;
				}
			}
		}
	}
	if(@game['debug'] && is_array(@snake['target'])) {
		set_entity_spec(@snake['debug'], array(text: @snake['target']['name']));
	}
	return(is_array(@snake['target']));
}

proc _snake_bot_lose_interest(@snake, @game) {
	if(@snake['target']) {
		if(--@snake['target']['interest'] <= 0) {
			@snake['target'] = null;
		} else if(@snake['target']['type'] === 'snake') {
			@target = @snake['target']['name'];
			if(!array_index_exists(@game['snakes'], @target)
			|| !@game['snakes'][@target]['alive']
			|| array_contains(@game['nukes'], @game['snakes'][@target]['region'])) {
				@snake['target'] = null;
			}
		} else if(_is_snake_tail(get_block(@snake['target']['loc']))
		|| array_contains(@game['nukes'], @snake['target']['region'])) {
			@snake['target'] = null;
		}
		if(@game['debug'] && !@snake['target']) {
			set_entity_spec(@snake['debug'], array(text: ''));
		}
	}
}

proc _snake_bot_safe_turn(@snake, @game) {
	@dir = _snake_safe_dir(@snake);
	if(@dir === @snake['dir']) {
		return(false);
	}
	@snake['turned'] = true;
	@snake['last-dir'] = @snake['dir'];
	@snake['dir'] = @dir;
	return(true);
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
		if(!@dir || @dir === @snake['dir'] || @dir === _snake_opposite_dir(@snake['dir'])) {
			continue();
		}
		@checkLoc = location_shift(@loc1, @dir);
		if(_snake_safe_block(get_block(@checkLoc), @checkLoc, @snake['last-dir'])) {
			@snake['last-dir'] = @snake['dir'];
			@snake['dir'] = @dir;
			@snake['turned'] = true;
			return(true);
		}
	}
	return(false);
}
