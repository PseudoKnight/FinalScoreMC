proc _snake_get_powerup_from(@id) {
	switch(@id) {
		case 1:
		case 'EMERALD_BLOCK':
			return('boost');
		case 2:
		case 'REDSTONE_BLOCK':
			return('missile');
		case 3:
		case 'TNT':
			return('tnt');
		case 4:
		case 'RED_STAINED_GLASS':
			return('laser');
		case 5:
		case 'STRUCTURE_BLOCK':
			return('nuke');
	}
	return(null);
}

proc _snake_get_block_from(@powerup) {
	switch(@powerup) {
		case 1:
		case 'boost':
			return('EMERALD_BLOCK');
		case 2:
		case 'missile':
			return('REDSTONE_BLOCK');
		case 3:
		case 'tnt':
			return('TNT');
		case 4:
		case 'laser':
			return('RED_STAINED_GLASS');
		case 5:
		case 'nuke':
			return('STRUCTURE_BLOCK');
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
	@region = @game['region'].rand(1, @game['surfaces'] + 1);
	@loc = _snake_valid_location(@region);
	if(@loc) {
		@maxIndex = if(@game['mode'] == 'capture', 4, if(@game['mode'] == 'gluttony', 2, 5));
		@r = rand(@maxIndex) + 1;
		@block = _snake_get_block_from(@r);
		@type = _snake_get_powerup_from(@r);
		set_block(@loc, @block, false);
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
		set_block(@pu['loc'], 'AIR', false);
	}
	@game['powerups'] = array();
}

proc _snake_check_powerups(@game) {
	foreach(@key: @pu in @game['powerups']) {
		if(!_snake_get_powerup_from(get_block(@pu['loc']))) {
			set_block(@pu['loc'], 'AIR', false);
			array_remove(@game['powerups'], @key);
		}
	}
}

proc _snake_powerup(@player, @powerup, @game) {
	if(!@powerup) {
		return(false);
	}
	@snake = @game['snakes'][@player];
	if(@game['mode'] == 'gluttony') {
		if(@snake['max'] < 100) {
			@snake['max'] += 10;
		} else if(@snake['max'] < 200) {
			@snake['max'] += 20;
		} else if(@snake['max'] < 500) {
			@snake['max'] += 50;
		} else {
			@snake['max'] += 100;
		}
		set_pscore('score', @player, @snake['max'], 'snake');
	} else {
		@slot = _snake_get_slot_from(@powerup);
		@snake['ability-count'][@slot] += 1;
		if(!@snake['bot']) {
			@item = pinv(@player, @slot);
			@inv = associative_array();
			if(@item && @item['name'] == _snake_get_block_from(@powerup)) {
				@item['qty'] += 1;
				@inv[@slot] = @item;
			} else {
				@inv[@slot] = array(
					name: _snake_get_block_from(@powerup),
					meta: associative_array(display: _snake_get_name_from(@powerup)),
				);
			}
			set_pinv(@player, @inv);
			title(@player, '', color('dark_gray').'+'.@powerup, 2, 0, 40);
		}
	}
	play_sound(@snake['loc'], associative_array(sound: 'ENTITY_ENDERMAN_TELEPORT', pitch: 2, volume: 4));
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
					@item['qty']--;
					set_pinv(@player, @slot, @item);
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
					@item['qty']--;
					set_pinv(@player, @slot, @item);
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
				if(!@snake['laser'] && @snake['ability-count'][@slot]) {
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
			} else if(!@snake['laser']) {
				@item = pinv(@player, @slot);
				@world = pworld(@player);
				if(@item && pcooldown(@player, 'RED_STAINED_GLASS') == 0) {
					@snake['laser'] = time() + (@item['qty'] * 500);
					set_pcooldown(@player, 'RED_STAINED_GLASS', 7000 / 50);
					play_named_sound(@snake['loc'], array('sound': 'entity.guardian.death', 'volume': 4, 'pitch': 2));
					play_named_sound(@snake['loc'], array('sound': 'entity.guardian.attack', 'volume': 4));
					_snake_shoot_laser(@player, @snake['loc'][], @snake['dir'], @game);
				}
			}
		case 'boost':
			if(@snake['bot']) {
				if(@snake['ability-count'][@slot]) {
					play_sound(@snake['loc'], associative_array('sound': 'ENTITY_GHAST_SHOOT', 'volume': 4));
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
				if(@item && pcooldown(@player, 'EMERALD_BLOCK') == 0) {
					play_sound(@snake['loc'], associative_array('sound': 'ENTITY_GHAST_SHOOT', 'volume': 4));
					@snake['boost'] = @item['qty'];
					set_pcooldown(@player, 'EMERALD_BLOCK', 7000 / 50);
					set_timeout(5000, closure(){
						@snake['boost'] = 0;
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
					set_pinv(@player, @slot, @item);
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
	@marker = spawn_entity('ARMOR_STAND', 1, @loc, closure(@entity) {
		add_scoreboard_tag(@entity, 'remove');
		set_entity_spec(@entity, array('marker': true, 'visible': false, 'gravity': false, 'small': true));
		set_mob_equipment(@entity, array('helmet': array('name': 'DIAMOND_BLOCK')));
	})[0];

	// now move it to the target location over time
	play_sound(@loc, array('sound': 'ENTITY_ZOMBIE_VILLAGER_CONVERTED', 'volume': 4));
	set_interval(50, closure(){
		if(distance(@loc, @target) > 0.3) {
			@newLoc = location_shift(@loc, @target, 0.25);
			@loc[0] = @newLoc[0];
			@loc[1] = @newLoc[1];
			@loc[2] = @newLoc[2];
			try {
				set_entity_loc(@marker, @loc);
			} catch(BadEntityException @ex) {
				clear_task();
				// load chunk just in case players left
				get_block(@loc);
				try(entity_remove(@marker))
			}
		} else {
			clear_task();
			entity_remove(@marker);

			// trigger nuke
			@state = array('radius': 1, 'side': 0);
			set_block(@target, 'FIRE', false);
			@game['fire'][] = @target[];
			play_sound(@target, array('sound': 'ENTITY_GENERIC_EXPLODE', 'pitch': 0.5, 'volume': 3));
			set_interval(50, closure(){
				if(!array_contains(@game['nukes'], @region)) {
					clear_task()
					die();
				}
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
							@block = get_block(@loc);
							if(@block != 'AIR') {
								set_block(@loc, 'FIRE', false);
								@game['fire'][] = @loc[];
								if(_is_snake_tail(@block)) {
									foreach(@player: @snake in @game['snakes']) {
										if(@snake['head'] == @block) {
											_snake_kill(@player, @game);
											break();
										}
									}
								}
							}
							if(!rand(3)) {
								spawn_particle(@loc, 'EXPLOSION_LARGE');
							}
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
	play_sound(@loc, associative_array('sound': 'ENTITY_TNT_PRIMED', 'volume': 4));
	if(@dir) {
		@loc = _snake_shift(@loc, @dir);
	}
	@loc[0] += 0.5;
	@loc[1] += 0.5;
	@loc[2] += 0.5;
	@tnt = spawn_entity('PRIMED_TNT', 1, @loc, closure(@tnt) {
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
	})[0];
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
				set_block(@missile['loc'], 'AIR', false);
			}
			if(array_size(@game['snakes']) < 2) {
				array_remove(@game['missiles'], @key);
				if(@clear) {
					clear_task();
				}
				die();
			}
			@missile['loc'] = location_shift(@missile['loc'], @missile['dir']);
			@block = get_block(@missile['loc']);
			if(@block == 'AIR') {
				if(!@missile['skip']) {
					set_block(@missile['loc'], 'REDSTONE_BLOCK', false);
				} else {
					@missile['skip'] = false;
				}
			} else if(@block == 'SEA_LANTERN') {
				@dir = _snake_dir_of_surface(@missile['loc'], _snake_opposite_dir(@missile['dir']));
				if(@dir) {
					@missile['dir'] = @dir;
					@missile['loc'] = location_shift(@missile['loc'], @dir);
					if(!@missile['skip']) {
						set_block(@missile['loc'], 'REDSTONE_BLOCK', false);
					} else {
						@missile['skip'] = false;
					}
				} else if(@clear){
					array_remove(@game['missiles'], @key);
					clear_task();
				}
			} else if(@block == 'REDSTONE_BLOCK') {
				_snake_remove_powerup(@missile['loc'], @game);
				@dir = _snake_direction_of(@missile['loc'], 'AIR', @missile['dir']);
				if(@dir) {
					@missile['dir'] = @dir;
					play_sound(@missile['loc'], associative_array('sound': 'ENTITY_IRON_GOLEM_HURT', 'pitch': 1.5, 'volume': 4));
				}
			} else {
				array_remove(@game['missiles'], @key);
				if(@clear) {
					clear_task();
				}
				play_named_sound(@missile['loc'], associative_array('sound': 'entity.shulker_bullet.hit', 'volume': 4, 'pitch': 1.5));
				if(_is_snake_tail(@block)) {
					set_block(@missile['loc'], 'AIR', false);
					foreach(@player: @snake in @game['snakes']) {
						if(@snake['loc'][0] == @missile['loc'][0] && @snake['loc'][1] == @missile['loc'][1] && @snake['loc'][2] == @missile['loc'][2]) {
							_snake_kill(@player, @game);
						}
					}
				} else if(@block == 'TNT') {
					_snake_remove_powerup(@missile['loc'], @game);
					set_block(@missile['loc'], 'AIR', false);
					_snake_drop_tnt(@missile['loc']);
				} else {
					play_sound(@missile['loc'], associative_array('sound': 'BLOCK_FIRE_EXTINGUISH', 'volume': 4));
				}
				@missile['loc']['x'] += 0.5;
				@missile['loc']['y'] += 0.5;
				@missile['loc']['z'] += 0.5;
				spawn_particle(@missile['loc'], array('particle': 'CLOUD', 'speed': 0.08, 'count': 8));
			}
		} catch(Exception @ex) {
			if(@clear) {
				clear_task();
			}
			set_block(@missile['loc'], 'AIR', false);
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
		@loc = location_shift(@loc, @dir);
		@block = get_block(@loc);
		if(@block == 'AIR') {
			set_block(@loc, 'RED_STAINED_GLASS', false);
			@blocks[] = @loc;
		} else if(@block == 'SEA_LANTERN' || @block == 'REDSTONE_BLOCK') {
			@newDir = _snake_dir_of_surface(@loc, _snake_opposite_dir(@dir));
			if(@newDir) {
				@dir = @newDir;
			} else {
				break();
			}
		} else if(@block == 'RED_STAINED_GLASS') {
			break();
		} else if(@block == 'TNT') {
			_snake_remove_powerup(@loc, @game);
			set_block(@loc, 'RED_STAINED_GLASS', false);
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
	@loc['x'] += 0.5;
	@loc['y'] += 0.5;
	@loc['z'] += 0.5;
	@blocks[] = @loc;
	@game['snakes'][@player]['laser-blocks'] = @blocks;
}

proc _snake_update_laser(@player, @game) {
	@snake = @game['snakes'][@player];
	spawn_particle(@snake['laser-blocks'][-1], array(
		'particle': 'LAVA',
		'count': 8,
		'xoffset': 0.5,
		'yoffset': 0.5,
		'zoffset': 0.5,
	));
	if(time() > @snake['laser']) {
		_snake_clear_laser(@player, @game);
		@snake['laser'] = 0;
	} else if(@snake['turned']) {
		_snake_clear_laser(@player, @game);
		_snake_shoot_laser(@player, @snake['loc'], @snake['dir'], @game);
	}
}

proc _snake_clear_laser(@player, @game) {
	@snake = @game['snakes'][@player];
	foreach(@l in @snake['laser-blocks']) {
		if(get_block(@l) == 'RED_STAINED_GLASS') {
			set_block(@l, 'AIR', false);
		}
	}
	@snake['laser-blocks'] = null;
}
