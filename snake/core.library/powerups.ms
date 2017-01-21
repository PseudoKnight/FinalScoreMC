proc _snake_get_powerup_from(@id) {
	switch(@id) {
		case 1:
		case 46:
		case '46:0':
			return('tnt');
		case 2:
		case 152:
		case '152:0':
			return('missile');
		case 3:
		case 95:
		case '95:14':
			return('laser');
		case 4:
		case 133:
		case '133:0':
			return('boost');
	}
	return(null);
}

proc _snake_get_block_from(@powerup) {
	switch(@powerup) {
		case 1:
		case 'tnt':
			return(46);
		case 2:
		case 'missile':
			return(152);
		case 3:
		case 'laser':
			return('95:14');
		case 4:
		case 'boost':
			return(133);
	}
	return(null);
}

proc _snake_get_name_from(@powerup) {
	switch(@powerup) {
		case 'tnt':
			return('TNT');
		case 'missile':
			return('Missile');
		case 'laser':
			return('Laser');
		case 'boost':
			return('Speed Boost');
	}
	return(null);
}

proc _snake_add_powerup(@game) {
	@region = 'snake_'.@game['arena'].rand(1, @game['surfaces'] + 1);
	@loc = _snake_valid_location(@region);
	if(@loc) {
		@r = rand(4) + 1;
		@block = _snake_get_block_from(@r);
		@type = _snake_get_powerup_from(@r);
		set_block_at(@loc, @block, false);
		@game['powerups'][] = associative_array(
			'block': @block,
			'loc': @loc,
			'type': @type,
			'region': @region,
		);
	}
}

proc _snake_remove_powerup(@loc, @game) {
	foreach(@i: @pu in @game['powerups']) {
		if(@pu['loc'][0] == @loc[0] && @pu['loc'][1] == @loc[1] && @pu['loc'][2] == @loc[2]) {
			array_remove(@game['powerups'], @i);
			return(true);
		}
	}
	return(false);
}

proc _snake_remove_all_powerups(@game) {
	foreach(@pu in @game['powerups']) {
		set_block_at(@pu['loc'], '0:0', false);
	}
	@game['powerups'] = array();
}

proc _snake_powerup(@player, @powerup, @game) {
	if(!@powerup) {
		return(false);
	}
	@snake = @game['snakes'][@player];
	if(@snake['ability'] == @powerup) {
		@snake['ability-count'] += 1;
	} else {
		@snake['ability'] = @powerup;
		@snake['ability-count'] = 1;
	}
	play_sound(@snake['loc'], associative_array('sound': 'ENDERMAN_TELEPORT', 'pitch': 2, 'volume': 2));
	if(!@game['snakes'][@player]['bot']) {
		@item = pinv(@player, 0);
		if(@item && @item['type'] == split(':', _snake_get_block_from(@powerup))[0]) {
			@item['qty'] += 1;
			set_pinv(@player, associative_array(0: @item));
		} else {
			set_pinv(@player, associative_array(0: associative_array(
				'type': _snake_get_block_from(@powerup),
				'meta': associative_array('display': _snake_get_name_from(@powerup)),
			)));
		}
	}
	return(true);
}

proc _snake_ability(@player, @game) {
	@snake = @game['snakes'][@player];
	switch(@snake['ability']) {
		case 'tnt':
			if(@snake['bot']) {
				if(@snake['ability-count']) {
					_snake_drop_tnt(@snake['loc'], @snake['dir']);
					@snake['ability-count'] -= 1;
					set_timeout(5000, closure(){
						if(@snake['ability'] == 'tnt') {
							@snake['ability-count'] += 1;
						}
					});
				}
			} else {
				@item = pinv(@player, 0);
				if(@item) {
					if(@item['qty'] == 1) {
						set_pinv(@player, associative_array(0: null));
					} else {
						@item['qty'] -= 1;
						set_pinv(@player, associative_array(0: @item));
					}
					_snake_drop_tnt(@snake['loc'], @snake['dir']);
					set_timeout(5000, closure(){
						if(@snake['alive'] && @snake['ability'] == 'tnt' && pinv(@player, -106)) {
							@item = pinv(@player, 0);
							if(@item) {
								@item['qty'] += 1;
								set_pinv(@player, associative_array(0: @item));
							} else {
								set_pinv(@player, associative_array(0: associative_array('name': 'TNT')));
							}
						}
					});
				}
			}
		case 'missile':
			if(@snake['bot']) {
				if(@snake['ability-count']) {
					_snake_launch_missile(@snake['loc'][], @snake['dir'], @game);
					@snake['ability-count'] -= 1;
					set_timeout(5000, closure(){
						if(@snake['ability'] == 'missile') {
							@snake['ability-count'] += 1;
						}
					});
				}
			} else {
				@item = pinv(@player, 0);
				if(@item) {
					if(@item['qty'] == 1) {
						set_pinv(@player, associative_array(0: null));
					} else {
						@item['qty'] -= 1;
						set_pinv(@player, associative_array(0: @item));
					}
					_snake_launch_missile(@snake['loc'][], @snake['dir'], @game);
					set_timeout(5000, closure(){
						if(@snake['alive'] && @snake['ability'] == 'missile' && pinv(@player, -106)) {
							@item = pinv(@player, 0);
							if(@item) {
								@item['qty'] += 1;
								set_pinv(@player, associative_array(0: @item));
							} else {
								set_pinv(@player, associative_array(0: associative_array(
									'name': 'REDSTONE_BLOCK',
									'meta': associative_array('display': 'Missile'),
								)));
							}
						}
					});
				}
			}

		case 'laser':
			if(@snake['bot']) {
				if(@snake['ability-count']) {
					@count = @snake['ability-count'];
					_snake_shoot_laser(@player, @snake['loc'][], @snake['dir'], @count, @game);
					@snake['ability-count'] = 0;
					set_timeout(5000, closure(){
						if(@snake['ability'] == 'laser') {
							@snake['ability-count'] += @count;
						}
					});
				}
			} else {
				@item = pinv(@player, 0);
				if(@item) {
					@amount = @item['qty'];
					set_pinv(@player, associative_array(0: null));
					_snake_shoot_laser(@player, @snake['loc'][], @snake['dir'], @amount, @game);
					set_timeout(5000, closure(){
						if(@snake['alive'] && @snake['ability'] == 'laser' && pinv(@player, -106)) {
							@item = pinv(@player, 0);
							if(@item) {
								@amount += @item['qty'];
							}
							set_pinv(@player, associative_array(0: associative_array(
								'name': 'STAINED_GLASS',
								'data': 14,
								'qty': @amount,
								'meta': associative_array('display': 'Laser'),
							)));
						}
					});
				}
			}
		case 'boost':
			if(@snake['bot']) {
				if(@snake['ability-count']) {
					play_sound(@snake['loc'], associative_array('sound': 'GHAST_FIREBALL', 'volume': 3));
					@count = @snake['ability-count'];
					@snake['boost'] = @count;
					@snake['ability-count'] = 0;
					set_timeout(5000, closure(){
						@snake['boost'] = 0;
						if(@snake['ability'] == 'boost') {
							@snake['ability-count'] += @count;
						}
					});
				}
			} else {
				@item = pinv(@player, 0);
				if(@item) {
					play_sound(@snake['loc'], associative_array('sound': 'GHAST_FIREBALL', 'volume': 3));
					@amount = @item['qty'];
					set_pinv(@player, associative_array(0: null));
					@snake['boost'] = @amount;
					set_timeout(5000, closure(){
						@snake['boost'] = 0;
						if(@snake['alive'] && @snake['ability'] == 'boost' && pinv(@player, -106)) {
							@item = pinv(@player, 0);
							if(@item) {
								@amount += @item['qty'];
							}
							set_pinv(@player, associative_array(0: associative_array(
								'name': 'EMERALD_BLOCK',
								'qty': @amount,
								'meta': associative_array('display': 'Speed Boost'),
							)));
						}
					});
				}
			}
	}
}

proc _snake_drop_tnt(@loc, @dir) {
	play_sound(@loc, associative_array('sound': 'FUSE', 'volume': 2));
	if(@dir) {
		@loc = _relative(@loc, @dir);
	}
	@loc[0] += 0.5;
	@loc[1] += 0.5;
	@loc[2] += 0.5;
	@tnt = spawn_entity('PRIMED_TNT', 1, @loc)[0];
	set_entity_spec(@tnt, associative_array('fuseticks': if(@dir, 32, 1)));
	switch(@dir) {
		case 'north':
			set_entity_velocity(@tnt, associative_array('z': -1.2));
		case 'south':
			set_entity_velocity(@tnt, associative_array('z': 1.2));
		case 'east':
			set_entity_velocity(@tnt, associative_array('x': 1.2));
		case 'west':
			set_entity_velocity(@tnt, associative_array('x': -1.2));
		case 'up':
			set_entity_velocity(@tnt, associative_array('y': 1.2));
		case 'down':
			set_entity_velocity(@tnt, associative_array('y': -1.2));
	}
}

proc _snake_launch_missile(@loc, @dir, @game) {
	@missile = associative_array('dir': @dir, 'loc': @loc, 'skip': true);
	@key = time();
	@game['missiles'][@key] = @missile;
	play_named_sound(@loc, associative_array('sound': 'entity.shulker.shoot', 'volume': 2, 'pitch': 2));
	@move = closure(@clear = true){
		try {
			if(!@missile['skip']) {
				set_block_at(@missile['loc'], 0, false);
			}
			if(array_size(@game['snakes']) < 2) {
				array_remove(@game['missiles'], @key);
				if(@clear) {
					clear_task();
				}
				die();
			}
			@missile['loc'] = _relative(@missile['loc'], @missile['dir']);
			@block = get_block_at(@missile['loc']);
			if(@block == '0:0') {
				if(!@missile['skip']) {
					set_block_at(@missile['loc'], '152', false);
				} else {
					@missile['skip'] = false;
				}
			} else if(@block == '169:0') {
				@dir = _snake_direction_of(@missile['loc'], '0:0', _snake_opposite_dir(@missile['dir']));
				if(@dir) {
					@missile['dir'] = @dir;
					@missile['loc'] = _relative(@missile['loc'], @dir);
					if(!@missile['skip']) {
						set_block_at(@missile['loc'], '152', false);
					} else {
						@missile['skip'] = false;
					}
				} else if(@clear){
					array_remove(@game['missiles'], @key);
					clear_task();
				}
			} else if(@block == '152:0') {
				_snake_remove_powerup(@missile['loc'], @game);
				@dir = _snake_direction_of(@missile['loc'], '0:0', @missile['dir']);
				if(@dir) {
					@missile['dir'] = @dir;
					play_sound(@missile['loc'], associative_array('sound': 'IRONGOLEM_HIT', 'pitch': 1.5, 'volume': 2));
				}
			} else {
				array_remove(@game['missiles'], @key);
				if(@clear) {
					clear_task();
				}
				play_named_sound(@missile['loc'], associative_array('sound': 'entity.shulker_bullet.hit', 'volume': 2, 'pitch': 1.5));
				if(split(':', @block)[0] == '159') {
					set_block_at(@missile['loc'], 0, false);
					foreach(@player: @snake in @game['snakes']) {
						if(@snake['loc'][0] == @missile['loc'][0] && @snake['loc'][1] == @missile['loc'][1] && @snake['loc'][2] == @missile['loc'][2]) {
							_snake_kill(@player, @game);
						}
					}
				} else if(@block == '46:0') {
					_snake_remove_powerup(@missile['loc'], @game);
					set_block_at(@missile['loc'], 0, false);
					_snake_drop_tnt(@missile['loc']);
				}
				@missile['loc'][0] += 0.5;
				@missile['loc'][1] += 0.5;
				@missile['loc'][2] += 0.5;
				play_effect(@missile['loc'], 'CLOUD', associative_array('speed': 0.08, 'particleCount': 8, 'radius': 40));
			}
		} catch(Exception @ex) {
			if(@clear) {
				clear_task();
			}
			set_block_at(@missile['loc'], 0, false);
			array_remove(@game['missiles'], @key);
		}
	}
	execute(false, @move);
	set_interval(50, @move);
}

proc _snake_shoot_laser(@player, @loc, @dir, @range, @game) {
	@game['snakes'][@player]['laser-immune'] = true;
	@originalDir = @dir;
	play_named_sound(@loc, associative_array('sound': 'entity.guardian.death', 'volume': 3, 'pitch': 2));
	play_named_sound(@loc, associative_array('sound': 'entity.guardian.attack', 'volume': 3));
	@blocks = array();
	while(@range > 0){
		@loc = _relative(@loc, @dir);
		@block = get_block_at(@loc);
		if(@block == '0:0') {
			set_block_at(@loc, '95:14', false);
			@blocks[] = @loc;
		} else if(@block == '169:0' || @block == '152:0') {
			@range--;
			@newDir = _snake_direction_of(@loc, '0:0');
			if(@newDir) {
				@dir = @newDir;
			} else {
				break();
			}
		} else if(@block == '95:14') {
			break();
		} else {
			if(split(':', @block)[0] == '159') {
				foreach(@p: @snake in @game['snakes']) {
					if(@snake['loc'][0] == @loc[0] && @snake['loc'][1] == @loc[1] && @snake['loc'][2] == @loc[2]) {
						_snake_kill(@p, @game);
					}
				}
			} else if(@block == '46:0') {
				_snake_remove_powerup(@loc, @game);
				set_block_at(@loc, 0, false);
				_snake_drop_tnt(@loc);
			}
			break();
		}
	}
	@time = time();
	@loc[0] += 0.5;
	@loc[1] += 0.5;
	@loc[2] += 0.5;
	set_interval(100, closure(){
		try {
			play_effect(@loc, 'LAVA_POP', associative_array('speed': 0, 'particleCount': 8, 'offsetX': 0.5, 'offsetY': 0.5, 'offsetZ': 0.5, 'radius': 40));
			if(!array_index_exists(@game['snakes'], @player)
			|| !@game['snakes'][@player]['alive']
			|| @game['snakes'][@player]['dir'] != @originalDir
			|| time() > @time + 5000) {
				@game['snakes'][@player]['laser-immune'] = false;
				foreach(@loc in @blocks) {
					if(get_block_at(@loc) == '95:14') {
						set_block_at(@loc, 0, false);
					}
				}
				clear_task();
			}
		} catch(Exception @ex) {
			clear_task();
			foreach(@loc in @blocks) {
				if(get_block_at(@loc) == '95:14') {
					set_block_at(@loc, 0, false);
				}
			}
		}
	});
}
