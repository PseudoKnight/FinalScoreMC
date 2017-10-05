proc _snake_get_powerup_from(@id) {
	switch(@id) {
		case 1:
		case 133:
		case '133:0':
			return('boost');
		case 2:
		case 152:
		case '152:0':
			return('missile');
		case 3:
		case 46:
		case '46:0':
			return('tnt');
		case 4:
		case 95:
		case '95:14':
			return('laser');
		case 5:
		case 138:
		case '138:0':
			return('nuke');
	}
	return(null);
}

proc _snake_get_block_from(@powerup) {
	switch(@powerup) {
		case 1:
		case 'boost':
			return(133);
		case 2:
		case 'missile':
			return(152);
		case 3:
		case 'tnt':
			return(46);
		case 4:
		case 'laser':
			return('95:14');
		case 5:
		case 'nuke':
			return(138);
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
		case 'nuke':
			return('Nuke');
	}
	return(null);
}

proc _snake_get_slot_from(@powerup) {
	switch(@powerup) {
		case 'boost':
			return(0);
		case 'missile':
			return(1);
		case 'tnt':
			return(2);
		case 'laser':
			return(3);
		case 'nuke':
			return(4);
	}
}

proc _snake_add_powerup(@game) {
	@region = 'snake_'.@game['arena'].rand(1, @game['surfaces'] + 1);
	@loc = _snake_valid_location(@region);
	if(@loc) {
		@r = rand(5) + 1;
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

proc _snake_check_powerups(@game) {
	foreach(@key: @pu in @game['powerups']) {
		if(!_snake_get_powerup_from(get_block_at(@pu['loc']))) {
			set_block_at(@pu['loc'], '0:0', false);
			array_remove(@game['powerups'], @key);
		}
	}
}

proc _snake_powerup(@player, @powerup, @game) {
	if(!@powerup) {
		return(false);
	}
	@snake = @game['snakes'][@player];
	@slot = _snake_get_slot_from(@powerup);
	@snake['ability-count'][@slot] += 1;
	if(!@snake['bot']) {
		@item = pinv(@player, @slot);
		@inv = associative_array();
		if(@item && @item['type'] == split(':', _snake_get_block_from(@powerup))[0]) {
			@item['qty'] += 1;
			@inv[@slot] = @item;
		} else {
			@inv[@slot] = associative_array(
				'type': _snake_get_block_from(@powerup),
				'meta': associative_array('display': _snake_get_name_from(@powerup)),
			);
		}
		set_pinv(@player, @inv);
		title(@player, '', color('dark_gray').'+'.@powerup, 2, 0, 40);
	}
	play_sound(@snake['loc'], associative_array('sound': 'ENDERMAN_TELEPORT', 'pitch': 2, 'volume': 4));
	return(true);
}

proc _snake_ability(@player, @slot, @game) {
	@snake = @game['snakes'][@player];
	@ability = _snake_get_powerup_from(@slot + 1);
	switch(@ability) {
		case 'tnt':
			if(@snake['bot']) {
				if(@snake['ability-count'][@slot]) {
					@game['tnt'][] = _snake_drop_tnt(@snake['loc'], @snake['dir']);
					@snake['ability-count'][@slot] -= 1;
					set_timeout(7000, closure(){
						@snake['ability-count'][@slot] += 1;
					});
				}
			} else {
				@item = pinv(@player, @slot);
				@world = pworld(@player);
				if(@item) {
					@inv = associative_array();
					if(@item['qty'] == 1) {
						@inv[@slot] = null;
					} else {
						@item['qty'] -= 1;
						@inv[@slot] = @item;
					}
					set_pinv(@player, @inv);
					@game['tnt'][] = _snake_drop_tnt(@snake['loc'], @snake['dir']);
					set_timeout(7000, closure(){
						if(@snake['alive'] && pworld(@player) == @world) {
							@item = pinv(@player, @slot);
							@inv = associative_array();
							if(@item) {
								@item['qty'] += 1;
								@inv[@slot] = @item;
							} else {
								@inv[@slot] = array('name': 'TNT');
							}
							set_pinv(@player, @inv);
						}
					});
				}
			}
		case 'missile':
			if(@snake['bot']) {
				if(@snake['ability-count'][@slot]) {
					_snake_launch_missile(@snake['loc'][], @snake['dir'], @game);
					@snake['ability-count'][@slot] -= 1;
					set_timeout(7000, closure(){
						@snake['ability-count'][@slot] += 1;
					});
				}
			} else {
				@item = pinv(@player, @slot);
				@world = pworld(@player);
				if(@item) {
					@inv = associative_array();
					if(@item['qty'] == 1) {
						@inv[@slot] = null;
					} else {
						@item['qty'] -= 1;
						@inv[@slot] = @item;
					}
					set_pinv(@player, @inv);
					_snake_launch_missile(@snake['loc'][], @snake['dir'], @game);
					set_timeout(7000, closure(){
						if(@snake['alive'] && pworld(@player) == @world) {
							@item = pinv(@player, @slot);
							@inv = associative_array();
							if(@item) {
								@item['qty'] += 1;
								@inv[@slot] = @item;
							} else {
								@inv[@slot] = associative_array(
									'name': 'REDSTONE_BLOCK',
									'meta': associative_array('display': 'Missile'),
								);
							}
							set_pinv(@player, @inv);
						}
					});
				}
			}

		case 'laser':
			if(@snake['bot']) {
				if(@snake['ability-count'][@slot]) {
					@count = @snake['ability-count'][@slot];
					@snake['laser'] = time() + (@count * 500);
					play_named_sound(@snake['loc'], array('sound': 'entity.guardian.death', 'volume': 4, 'pitch': 2));
					play_named_sound(@snake['loc'], array('sound': 'entity.guardian.attack', 'volume': 4));
					_snake_shoot_laser(@player, @snake['loc'][], @snake['dir'], @game);
					@snake['ability-count'][@slot] = 0;
					set_timeout(7000, closure(){
						@snake['ability-count'][@slot] += @count;
					});
				}
			} else {
				@item = pinv(@player, @slot);
				@world = pworld(@player);
				if(@item) {
					@amount = @item['qty'];
					@inv = associative_array();
					@inv[@slot] = null;
					set_pinv(@player, @inv);
					@snake['laser'] = time() + (@amount * 500);
					play_named_sound(@snake['loc'], array('sound': 'entity.guardian.death', 'volume': 4, 'pitch': 2));
					play_named_sound(@snake['loc'], array('sound': 'entity.guardian.attack', 'volume': 4));
					_snake_shoot_laser(@player, @snake['loc'][], @snake['dir'], @game);
					set_timeout(7000, closure(){
						if(@snake['alive'] && pworld(@player) == @world) {
							@item = pinv(@player, @slot);
							@inv = associative_array();
							if(@item) {
								@amount += @item['qty'];
							}
							@inv[@slot] = associative_array(
								'name': 'STAINED_GLASS',
								'data': 14,
								'qty': @amount,
								'meta': associative_array('display': 'Laser'),
							);
							set_pinv(@player, @inv);
						}
					});
				}
			}
		case 'boost':
			if(@snake['bot']) {
				if(@snake['ability-count'][@slot]) {
					play_sound(@snake['loc'], associative_array('sound': 'GHAST_FIREBALL', 'volume': 4));
					@count = @snake['ability-count'][@slot];
					@snake['boost'] = @count;
					@snake['ability-count'][@slot] = 0;
					set_timeout(5000, closure(){
						@snake['boost'] = 0;
						set_timeout(2000, closure(){
							@snake['ability-count'][@slot] += @count;
						});
					});
				}
			} else {
				@item = pinv(@player, @slot);
				@world = pworld(@player);
				if(@item) {
					play_sound(@snake['loc'], associative_array('sound': 'GHAST_FIREBALL', 'volume': 4));
					@amount = @item['qty'];
					@inv = associative_array();
					@inv[@slot] = null;
					set_pinv(@player, @inv);
					@snake['boost'] = @amount;
					set_timeout(5000, closure(){
						@snake['boost'] = 0;
						set_timeout(2000, closure(){
							if(@snake['alive'] && pworld(@player) == @world) {
								@item = pinv(@player, @slot);
								if(@item) {
									@amount += @item['qty'];
								}
								@inv = associative_array();
								@inv[@slot] = associative_array(
									'name': 'EMERALD_BLOCK',
									'qty': @amount,
									'meta': associative_array('display': 'Speed Boost'),
								);
								set_pinv(@player, @inv);
							}
						});
					});
				}
			}
		case 'nuke':
			if(@snake['bot']) {
				if(@snake['ability-count'][@slot]) {
					@snake['ability-count'][@slot]--;
					_snake_drop_nuke(@snake, @game);
				}
			} else {
				@item = pinv(@player, @slot);
				if(@item) {
					@item['qty']--;
					@inv = associative_array();
					if(@item['qty']) {
						@inv[@slot] = @item;
					} else {
						@inv[@slot] = null;
					}
					set_pinv(@player, @inv);
					_snake_drop_nuke(@snake, @game);
				}
			}
	}
}

proc _snake_drop_nuke(@snake, @game) {
	// get center of region for targeting
	@region = @snake['region'];
	@game['nukes'][] = @region;
	@coords = sk_region_info(@region, 'custom', 0);
	@x = floor(@coords[0][0] - (@coords[0][0] - @coords[1][0]) / 2) + 0.5;
	@y = floor(@coords[0][1] - (@coords[0][1] - @coords[1][1]) / 2) + 0.5;
	@z = floor(@coords[0][2] - (@coords[0][2] - @coords[1][2]) / 2) + 0.5;
	@target = array(@x, @y, @z, 'custom');
	
	// determine sides of blast plane (coord to side, direction from target to side, coord of side)
	@sides = array(array(0, 1, 2), array(2, 1, 0), array(0, -1, 2), array(2, -1, 0));
	if(@coords[0][0] == @coords[1][0]) {
		@sides = array(array(2, 1, 1), array(1, 1, 2), array(2, -1, 1), array(1, -1, 2));
	} else if(@coords[0][2] == @coords[1][2]) {
		@sides = array(array(0, 1, 1), array(1, 1, 0), array(0, -1, 1), array(1, -1, 0));
	}
	
	// get max radius of region
	@maxradius = ceil(max(@coords[0][0] - @coords[1][0], @coords[0][1] - @coords[1][1], @coords[0][2] - @coords[1][2]) / 2);
	
	// create nuke marker
	@loc = @snake['loc'][];
	@loc[0] += 0.5;
	@loc[1] -= 0.5;
	@loc[2] += 0.5;
	@marker = spawn_entity('ARMOR_STAND', 1, @loc)[0];
	set_entity_spec(@marker, array('marker': true, 'visible': false, 'gravity': false, 'small': true));
	set_mob_equipment(@marker, array('helmet': array('name': 'BEACON')));
	
	// now move it to the target location over time
	play_sound(@loc, array('sound': 'ZOMBIE_UNFECT', 'volume': 4));
	set_interval(50, closure(){
		if(_distance(@loc, @target) > 0.3) {
			@newLoc = location_shift(@loc, @target, 0.25);
			@loc[0] = @newLoc[0];
			@loc[1] = @newLoc[1];
			@loc[2] = @newLoc[2];
			set_entity_loc(@marker, @loc);
		} else {
			clear_task();
			entity_remove(@marker);
			
			// trigger nuke
			@state = array('radius': 1, 'side': 0);
			set_block_at(@target, 51, false);
			play_sound(@target, array('sound': 'EXPLODE', 'pitch': 0.5, 'volume': 3));
			set_interval(50, closure(){
				@side = @state['side'];
				@radius = @state['radius'];
				
				// set new wall
				@coord = @sides[@side][0];
				@dir = @sides[@side][1];
				@loc = @target[];
				@loc[@coord] += @radius * @dir;
				if(@loc[@coord] > @coords[1][@coord]
				&& @loc[@coord] < @coords[0][@coord] + 1) {
					@coord = @sides[@side][2];
					for(@i = 0 - @radius, @i <= @radius, @i++) {
						@loc[@coord] = @target[@coord] + @i;
						if(@loc[@coord] > @coords[1][@coord]
						&& @loc[@coord] < @coords[0][@coord] + 1) {
							@block = get_block_at(@loc);
							if(@block != '0:0') {
								set_block_at(@loc, 51, false);
								if(_is_snake_tail(@block)) {
									foreach(@player: @snake in @game['snakes']) {
										if(@snake['head'] == @block) {
											_snake_kill(@player, @game);
											break();
										}
									}
								}
							}
							play_effect(@loc, 'EXPLOSION_LARGE', array('radius': 48));
						}
					}
				}
				
				// go to the new side
				if(++@state['side'] > 3) {
					@state['radius']++;
					@state['side'] = 0;
					if(@state['radius'] > @maxradius) {
						clear_task();
						_snake_check_powerups(@game);
						array_remove_values(@game['nukes'], @region);
					}
				}
			});
		}
	});
}

proc _snake_drop_tnt(@loc, @dir) {
	play_sound(@loc, associative_array('sound': 'FUSE', 'volume': 4));
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
	return(@tnt);
}

proc _snake_launch_missile(@loc, @dir, @game) {
	@missile = associative_array('dir': @dir, 'loc': @loc, 'skip': true);
	@key = time();
	@game['missiles'][@key] = @missile;
	play_named_sound(@loc, associative_array('sound': 'entity.shulker.shoot', 'volume': 4, 'pitch': 2));
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
				@dir = _snake_dir_of_surface(@missile['loc'], _snake_opposite_dir(@missile['dir']));
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
					play_sound(@missile['loc'], associative_array('sound': 'IRONGOLEM_HIT', 'pitch': 1.5, 'volume': 4));
				}
			} else {
				array_remove(@game['missiles'], @key);
				if(@clear) {
					clear_task();
				}
				play_named_sound(@missile['loc'], associative_array('sound': 'entity.shulker_bullet.hit', 'volume': 4, 'pitch': 1.5));
				if(_is_snake_tail(@block)) {
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
				} else {
					play_sound(@missile['loc'], associative_array('sound': 'FIZZ', 'volume': 4));
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
	if(array_index_exists(@game['missiles'], @key)) {
		set_interval(50, @move);
	}
}

proc _snake_shoot_laser(@player, @loc, @dir, @game) {
	@originalDir = @dir;
	@blocks = array();
	while(true){
		@loc = _relative(@loc, @dir);
		@block = get_block_at(@loc);
		if(@block == '0:0') {
			set_block_at(@loc, '95:14', false);
			@blocks[] = @loc;
		} else if(@block == '169:0' || @block == '152:0') {
			@newDir = _snake_dir_of_surface(@loc, _snake_opposite_dir(@dir));
			if(@newDir) {
				@dir = @newDir;
			} else {
				break();
			}
		} else if(@block == '95:14') {
			break();
		} else if(@block == '46:0') {
			_snake_remove_powerup(@loc, @game);
			set_block_at(@loc, '95:14', false);
			@blocks[] = @loc;
			_snake_drop_tnt(@loc);
		} else {
			if(_is_snake_tail(@block)) {
				foreach(@p: @snake in @game['snakes']) {
					if(@snake['loc'][0] == @loc[0] && @snake['loc'][1] == @loc[1] && @snake['loc'][2] == @loc[2]) {
						_snake_kill(@p, @game);
					}
				}
			}
			break();
		}
	}
	@loc[0] += 0.5;
	@loc[1] += 0.5;
	@loc[2] += 0.5;
	@blocks[] = @loc;
	@game['snakes'][@player]['laser-blocks'] = @blocks;
}

proc _snake_update_laser(@player, @game) {
	@snake = @game['snakes'][@player];
	play_effect(@snake['laser-blocks'][-1], 'LAVA_POP', array(
		'speed': 0,
		'particleCount': 8,
		'offsetX': 0.5,
		'offsetY': 0.5,
		'offsetZ': 0.5,
		'radius': 40
	));
	if(@snake['turned']) {
		_snake_clear_laser(@player, @game);
		_snake_shoot_laser(@player, @snake['loc'], @snake['dir'], @game);
	} else if(time() > @snake['laser']) {
		_snake_clear_laser(@player, @game);
		@snake['laser'] = 0;
		@snake['laser-blocks'] = null;
	}
}

proc _snake_clear_laser(@player, @game) {
	@snake = @game['snakes'][@player];
	foreach(@l in @snake['laser-blocks']) {
		if(get_block_at(@l) == '95:14') {
			set_block_at(@l, 0, false);
		}
	}
}
