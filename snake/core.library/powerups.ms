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
				spawn_entity('PRIMED_TNT', 1, array(
					@snake['loc'][0] + 0.5, @snake['loc'][1] + 0.5, @snake['loc'][2] + 0.5, @snake['loc'][3]
				));
			} else {
				@item = pinv(@player, 0);
				if(@item) {
					if(@item['qty'] == 1) {
						set_pinv(@player, associative_array(0: null));
					} else {
						@item['qty'] -= 1;
						set_pinv(@player, associative_array(0: @item));
					}
					spawn_entity('PRIMED_TNT', 1, array(
						@snake['loc'][0] + 0.5, @snake['loc'][1] + 0.5, @snake['loc'][2] + 0.5, @snake['loc'][3]
					));
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
				// ignore for now
			} else {
				@item = pinv(@player, 0);
				if(@item) {
					if(@item['qty'] == 1) {
						set_pinv(@player, associative_array(0: null));
					} else {
						@item['qty'] -= 1;
						set_pinv(@player, associative_array(0: @item));
					}
					@missile = associative_array('dir': @snake['dir'], 'loc': @snake['loc'][], 'skip': true);
					set_interval(50, 0, closure(){
						if(!@missile['skip']) {
							set_block_at(@missile['loc'], 0, false);
						}
						@missile['loc'] = _relative(@missile['loc'], @missile['dir']);
						@block = get_block_at(@missile['loc']);
						if(@block == '0:0') {
							if(!@missile['skip']) {
								set_block_at(@missile['loc'], '152', false);
							} else {
								@missile['skip'] = false;
							}
						} else {
							clear_task();
							if(@block != '169:0') {
								set_block_at(@missile['loc'], 0, false);
							}
							if(@snake['alive'] && @snake['ability'] == 'missile') {
								@item = pinv(@player, 0);
								if(@item) {
									@item['qty'] += 1;
									set_pinv(@player, associative_array(0: @item));
								} else {
									set_pinv(@player, associative_array(0: associative_array('name': 'REDSTONE_BLOCK')));
								}
							}
						}
					});
				}
			}
	}
}
