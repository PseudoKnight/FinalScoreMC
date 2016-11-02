proc _snake_bot_update(@bot, @game) {
	@snake = @game['snakes'][@bot];
	@percent = rand(100);
	switch(@bot) {
	case 'Grumpy':
		if(!@snake['target']) {
			if(!_snake_bot_target_snake(@snake, @game)) {
				_snake_bot_target_powerup(@snake, @game);
			}
		}
		if(@snake['target']) {
			if(@snake['target']['type'] == 'snake') {
				@target = @snake['target']['name'];
				if(!@game['snakes'][@target]['alive']
				|| @snake['region'] != @game['snakes'][@target]['region']) {
					@snake['target'] = null;
				} else {
					@targetLoc = _relative(@game['snakes'][@target]['loc'], @game['snakes'][@target]['dir']);
					@dir = _snake_farthest_dir(@snake['loc'], @targetLoc);
					if(@dir && _snake_safe_block(_relative(@snake['loc'], @dir))) {
						@snake['last-dir'] = @snake['dir'];
						@snake['dir'] = @dir;
						if(@snake['loc'][0] == @targetLoc[0]
						|| @snake['loc'][1] == @targetLoc[1]
						|| @snake['loc'][2] == @targetLoc[2]) {
							_snake_ability(@bot, @game);
						}
						return();
					}
				}
			} else {
				// go to target
				@dir = _snake_farthest_dir(@snake['loc'], @snake['target']['loc']);
				if(@dir && _snake_safe_block(_relative(@snake['loc'], @dir))) {
					@snake['last-dir'] = @snake['dir'];
					@snake['dir'] = @dir;
					return();
				} else if(split(':', get_block_at(@snake['target']['loc']))[0] == '159') {
					@snake['target'] = null;
				}
			}
		}
		if(@percent < 10
		|| !_snake_safe_block(_relative(@snake['loc'], @snake['dir']))
		|| !_snake_safe_block(_relative(@snake['loc'], @snake['dir'], 3), false)) {
			@dir = _snake_safe_dir(@snake['loc'], @snake['dir'], @snake['last-dir']);
			@snake['last-dir'] = @snake['dir'];
			@snake['dir'] = @dir;
			_snake_ability(@bot, @game);
		}
	case 'BatSnake':
		if(!@snake['target']) {
			if(!@snake['ability'] || @snake['ability-count'] < 4) {
				_snake_bot_target_powerup(@snake, @game, 'boost');
			} else {
				_snake_bot_target_snake(@snake, @game);
			}
		}
		if(@snake['boost'] == 0 && @snake['ability'] == 'boost') {
			_snake_ability(@bot, @game);
		}
		if(@snake['target']) {
			if(@snake['target']['type'] == 'snake') {
				@target = @snake['target']['name'];
				if(!@game['snakes'][@target]['alive']
				|| @snake['region'] != @game['snakes'][@target]['region']) {
					@snake['target'] = null;
				} else {
					@targetLoc = _relative(@game['snakes'][@target]['loc'], @game['snakes'][@target]['dir']);
					@dir = _snake_farthest_dir(@snake['loc'], @targetLoc);
					if(@dir && _snake_safe_block(_relative(@snake['loc'], @dir))) {
						@snake['last-dir'] = @snake['dir'];
						@snake['dir'] = @dir;
						return();
					}
				}
			} else {
				// go to target
				@dir = _snake_farthest_dir(@snake['loc'], @snake['target']['loc']);
				if(@dir && _snake_safe_block(_relative(@snake['loc'], @dir))) {
					@snake['last-dir'] = @snake['dir'];
					@snake['dir'] = @dir;
					return();
				} else if(split(':', get_block_at(@snake['target']['loc']))[0] == '159') {
					@snake['target'] = null;
				}
			}
		}
		if(!_snake_safe_block(_relative(@snake['loc'], @snake['dir']), true, array('46', '95', '152'))
		|| !_snake_safe_block(_relative(@snake['loc'], @snake['dir'], 3), false)) {
			@dir = _snake_safe_dir(@snake['loc'], @snake['dir'], @snake['last-dir']);
			@snake['last-dir'] = @snake['dir'];
			@snake['dir'] = @dir;
		}
	case 'SharkBot':
		if(!@snake['target']) {
			_snake_bot_target_snake(@snake, @game);
		}
		if(@snake['target']) {
			@target = @snake['target']['name'];
			if(!@game['snakes'][@target]['alive']
			|| @snake['region'] != @game['snakes'][@target]['region']) {
				@snake['target'] = null;
			} else {
				@targetLoc = _relative(@game['snakes'][@target]['loc'], @game['snakes'][@target]['dir']);
				@dir = _snake_farthest_dir(@snake['loc'], @targetLoc);
				if(@dir && _snake_safe_block(_relative(@snake['loc'], @dir))) {
					@snake['last-dir'] = @snake['dir'];
					@snake['dir'] = @dir;
					if(@snake['loc'][0] == @targetLoc[0]
					|| @snake['loc'][1] == @targetLoc[1]
					|| @snake['loc'][2] == @targetLoc[2]) {
						_snake_ability(@bot, @game);
					}
					return();
				}
			}
		}
		if(@percent < 10
		|| !_snake_safe_block(_relative(@snake['loc'], @snake['dir']))
		|| !_snake_safe_block(_relative(@snake['loc'], @snake['dir'], 3), false)) {
			@dir = _snake_safe_dir(@snake['loc'], @snake['dir'], @snake['last-dir']);
			@snake['last-dir'] = @snake['dir'];
			@snake['dir'] = @dir;
		}
	}
}

proc _snake_bot_target_powerup(@snake, @game, @type = 'all') {
	@closest = 1000;
	foreach(@powerup in @game['powerups']) {
		if((@type == 'all' || @powerup['type'] == @type)) {
			@dist = _distance(@powerup['loc'], @snake['loc']);
			if(@dist < @closest) {
				@snake['target'] = associative_array('type': 'powerup', 'loc': @powerup['loc']);
				@closest = @dist;
			}
		}
	}
	return(is_array(@snake['target']));
}

proc _snake_bot_target_snake(@snake, @game) {
	foreach(@bot: @othersnake in @game['snakes']) {
		if(!@othersnake['bot'] && @othersnake['alive'] && @othersnake['region'] == @snake['region']) {
			@snake['target'] = associative_array('type': 'snake', 'name': @bot);
			return(true);
		}
	}
	return(false);
}
