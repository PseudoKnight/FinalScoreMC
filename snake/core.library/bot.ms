proc _snake_bot_update(@bot, @game) {
	@snake = @game['snakes'][@bot];
	@percent = rand(100);
	switch(@bot) {
	case 'Sleepy':
		if(!@snake['target']) {
			if(!_snake_bot_target_snake(@snake, @game)
			&& (!@snake['ability'] || @percent < 14)) {
				_snake_bot_target_powerup(@snake, @game);
			}
		}
		if(@snake['target']) {
			// go to target
			if(@snake['target']['type'] == 'powerup') {
				@dir = _snake_farthest_dir(@snake['loc'], @snake['target']['loc']);
				if(@dir && _snake_safe_block(_relative(@snake['loc'], @dir))) {
					@snake['last-dir'] = @snake['dir'];
					@snake['dir'] = @dir;
				} else if(split(':', get_block_at(@snake['target']['loc']))[0] == '159') {
					@snake['target'] = null;
				}
			} else {
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
					}
				}
			}
		}
		if(!_snake_safe_block(_relative(@snake['loc'], @snake['dir']))
		|| !_snake_safe_block(_relative(@snake['loc'], @snake['dir'], 3), false)) {
			@dir = _snake_safe_dir(@snake['loc'], @snake['dir'], @snake['last-dir']);
			@snake['last-dir'] = @snake['dir'];
			@snake['dir'] = @dir;
			_snake_ability(@bot, @game);
		} else if(@percent < 7) {
			// turn
			@dir = _snake_safe_dir(@snake['loc'], @snake['dir'], @snake['last-dir']);
			@snake['last-dir'] = @snake['dir'];
			@snake['dir'] = @dir;
		}
	case 'Dopey':
		if(!@snake['target']) {
			if(!_snake_bot_target_snake(@snake, @game)
			&& (!@snake['ability'] || @percent < 30)) {
				_snake_bot_target_powerup(@snake, @game);
			}
		}
		if(@percent < 20
		|| !_snake_safe_block(_relative(@snake['loc'], @snake['dir']))
		|| !_snake_safe_block(_relative(@snake['loc'], @snake['dir'], 3), false)) {
			@dir = _snake_safe_dir(@snake['loc'], @snake['dir'], @snake['last-dir']);
			@snake['last-dir'] = @snake['dir'];
			@snake['dir'] = @dir;
			_snake_ability(@bot, @game);
		} else if(@snake['target']) {
			// go to target
			if(@snake['target']['type'] == 'powerup') {
				@dir = _snake_farthest_dir(@snake['loc'], @snake['target']['loc']);
				if(@dir && _snake_safe_block(_relative(@snake['loc'], @dir))) {
					@snake['last-dir'] = @snake['dir'];
					@snake['dir'] = @dir;
				} else if(split(':', get_block_at(@snake['target']['loc']))[0] == '159') {
					@snake['target'] = null;
				}
			} else {
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
					}
				}
			}
		}
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
	case 'Bashful':
		@othersnake = array_rand(@game['snakes'])[0];
		if(@othersnake != @bot
		&& @game['snakes'][@othersnake]['alive']
		&& @snake['region'] == @game['snakes'][@othersnake]['region']) {
			@dir = _snake_opposite_dir(_snake_farthest_dir(@snake['loc'], @game['snakes'][@othersnake]['loc']));
			if(@dir && _snake_safe_block(_relative(@snake['loc'], @dir))) {
				@snake['last-dir'] = @snake['dir'];
				@snake['dir'] = @dir;
				return();
			}
		}
		if(@snake['target']) {
			// go to target
			@dir = _snake_farthest_dir(@snake['loc'], @snake['target']['loc']);
			if(@dir && _snake_safe_block(_relative(@snake['loc'], @dir))) {
				@snake['last-dir'] = @snake['dir'];
				@snake['dir'] = @dir;
				return();
			} else if(split(':', get_block_at(@snake['target']['loc']))[0] == '159') {
				@snake['target'] = null;
			}
		} else {
			_snake_bot_target_powerup(@snake, @game);
		}
		if(@percent < 10
		|| !_snake_safe_block(_relative(@snake['loc'], @snake['dir']))
		|| !_snake_safe_block(_relative(@snake['loc'], @snake['dir'], 3), false)) {
			@dir = _snake_safe_dir(@snake['loc'], @snake['dir'], @snake['last-dir']);
			@snake['last-dir'] = @snake['dir'];
			@snake['dir'] = @dir;
			_snake_ability(@bot, @game);
		}
	case 'Happy':
		if(!@snake['target']) {
			if(!_snake_bot_target_snake(@snake, @game)
			&& (!@snake['ability'] || @percent < 50)) {
				_snake_bot_target_powerup(@snake, @game);
			}
		}
		if(@snake['target']) {
			// go to target
			if(@snake['target']['type'] == 'powerup') {
				@dir = _snake_farthest_dir(@snake['loc'], @snake['target']['loc']);
				if(@dir && _snake_safe_block(_relative(@snake['loc'], @dir))) {
					@snake['last-dir'] = @snake['dir'];
					@snake['dir'] = @dir;
				} else if(split(':', get_block_at(@snake['target']['loc']))[0] == '159') {
					@snake['target'] = null;
				}
			} else {
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
					}
				}
			}
		} else if(!_snake_safe_block(_relative(@snake['loc'], @snake['dir']))
		|| !_snake_safe_block(_relative(@snake['loc'], @snake['dir'], 3), false)) {
			@dir = _snake_safe_dir(@snake['loc'], @snake['dir'], @snake['last-dir']);
			@snake['last-dir'] = @snake['dir'];
			@snake['dir'] = @dir;
			_snake_ability(@bot, @game);
		} else if(@percent < 15) {
			// turn
			@dir = _snake_safe_dir(@snake['loc'], @snake['dir'], @snake['last-dir']);
			@snake['last-dir'] = @snake['dir'];
			@snake['dir'] = @dir;
		}

	case 'Sneezy':
		if(!@snake['target']) {
			if(!_snake_bot_target_snake(@snake, @game)
			&& (!@snake['ability'] || @percent < 25)) {
				_snake_bot_target_powerup(@snake, @game);
			}
		}
		if(@snake['target']) {
			// go to target
			if(@snake['target']['type'] == 'powerup') {
				@dir = _snake_farthest_dir(@snake['loc'], @snake['target']['loc']);
				if(@dir && _snake_safe_block(_relative(@snake['loc'], @dir))) {
					@snake['last-dir'] = @snake['dir'];
					@snake['dir'] = @dir;
				} else if(split(':', get_block_at(@snake['target']['loc']))[0] == '159') {
					@snake['target'] = null;
				}
			} else {
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
					}
				}
			}
		}
		if(!_snake_safe_block(_relative(@snake['loc'], @snake['dir']))
		|| !_snake_safe_block(_relative(@snake['loc'], @snake['dir'], 3), false)) {
			@dir = _snake_safe_dir(@snake['loc'], @snake['dir'], @snake['last-dir']);
			@snake['last-dir'] = @snake['dir'];
			@snake['dir'] = @dir;
			_snake_ability(@bot, @game);
		} else if(@percent < 15) {
			// turn
			@dir = _snake_safe_dir(@snake['loc'], @snake['dir'], @snake['last-dir']);
			@snake['last-dir'] = @snake['dir'];
			@snake['dir'] = @dir;
		} else if(@snake['ability'] && @percent < 30) {
			_snake_ability(@bot, @game);
		}
	}
}

proc _snake_bot_target_powerup(@snake, @game, @type = 'all') {
	foreach(@powerup in @game['powerups']) {
		if((@type == 'all' || @powerup['type'] == @type) && @powerup['region'] == @snake['region']) {
			@snake['target'] = associative_array('type': 'powerup', 'loc': @powerup['loc']);
			return(true);
		}
	}
	return(false);
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
