proc _snake_get_powerup_from(@id) {
	switch(@id) {
		case 1:
		case 46:
			return('tnt');
		case 2:
		case 152:
			return('missile');
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
	}
	return(null);
}

proc _snake_add_powerup(@game) {
	@region = 'snake_'.@game['arena'].rand(1, @game['surfaces'] + 1);
	@loc = _snake_valid_location(@region);
	if(@loc) {
		@r = rand(2) + 1;
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
			break();
		}
	}
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
	@snake['ability'] = @powerup;
	play_sound(@snake['loc'], associative_array('sound': 'ENDERMAN_TELEPORT', 'pitch': 2, 'volume': 2));
	if(!@game['snakes'][@player]['bot']) {
		@item = pinv(@player, 0);
		if(@item && @item['type'] == _snake_get_block_from(@powerup)) {
			@item['qty'] += 1;
			set_pinv(@player, associative_array(0: @item));
		} else {
			set_pinv(@player, associative_array(0: associative_array('type': _snake_get_block_from(@powerup))));
		}
	}
	return(true);
}

proc _snake_ability(@player, @game) {
	@snake = @game['snakes'][@player];
	switch(@snake['ability']) {
		case 'tnt':
			if(@snake['bot']) {
				_snake_drop_tnt(@snake['loc']);
			} else {
				@item = pinv(@player, 0);
				if(@item) {
					if(@item['qty'] == 1) {
						set_pinv(@player, associative_array(0: null));
					} else {
						@item['qty'] -= 1;
						set_pinv(@player, associative_array(0: @item));
					}
					_snake_drop_tnt(@snake['loc']);
					set_timeout(4000, closure(){
						if(@snake['alive'] && @snake['ability'] == 'tnt') {
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
				_snake_launch_missile(@snake['loc'], @snake['dir'], @game);
			} else {
				@item = pinv(@player, 0);
				if(@item) {
					if(@item['qty'] == 1) {
						set_pinv(@player, associative_array(0: null));
					} else {
						@item['qty'] -= 1;
						set_pinv(@player, associative_array(0: @item));
					}
					_snake_launch_missile(@snake['loc'], @snake['dir'], @game);
					set_timeout(4000, closure(){
						if(@snake['alive'] && @snake['ability'] == 'missile') {
							@item = pinv(@player, 0);
							if(@item) {
								@item['qty'] += 1;
								set_pinv(@player, associative_array(0: @item));
							} else {
								set_pinv(@player, associative_array(0: associative_array('name': 'REDSTONE_BLOCK')));
							}
						}
					});
				}
			}
	}
}

proc _snake_drop_tnt(@loc) {
	play_sound(@loc, associative_array('sound': 'FUSE', 'volume': 2));
	@tnt = spawn_entity('PRIMED_TNT', 1, array(@loc[0] + 0.5, @loc[1] + 0.5, @loc[2] + 0.5, @loc[3]))[0];
	set_entity_spec(@tnt, associative_array('fuseticks': 60));
}

proc _snake_launch_missile(@loc, @dir, @game) {
	@missile = associative_array('dir': @dir, 'loc': @loc[], 'skip': true);
	play_named_sound(@loc, associative_array('sound': 'entity.shulker.shoot', 'volume': 2, 'pitch': 2));
	@move = closure(@clear = true){
		if(!@missile['skip']) {
			set_block_at(@missile['loc'], 0, false);
		}
		if(array_size(@game['snakes']) < 2) {
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
				clear_task();
			}
		} else if(@block == '152:0') {
			@dir = _snake_direction_of(@missile['loc'], '0:0', @missile['dir']);
			if(@dir) {
				@missile['dir'] = @dir;
			}
		} else {
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
				set_block_at(@missile['loc'], 0, false);
				_snake_drop_tnt(@missile['loc']);
			}
			@missile['loc'][0] += 0.5;
			@missile['loc'][1] += 0.5;
			@missile['loc'][2] += 0.5;
			play_effect(@missile['loc'], 'CLOUD', associative_array('speed': 0.07, 'particleCount': 5));
		}
	}
	execute(false, @move);
	set_interval(50, @move);
}
