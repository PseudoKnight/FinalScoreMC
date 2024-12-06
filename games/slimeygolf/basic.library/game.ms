include('course.ms');
include('player.ms');
include('ball.ms');

proc _start_game(@course, @world, @test) {
	@golf = array(
		name: @course,
		world: @world,
		par: 0,
		players: associative_array(),
		lowestHole: 1,
		test: @test,
		// populated with hole indexes
	);

	create_scoreboard(@golf['name']);
	create_objective('strokes', 'DUMMY', @golf['name']);
	set_objective_display('strokes', array(displayname: colorize('&7&l[ &a&lSlimey &6&lGolf&7&l ]'), slot: 'SIDEBAR'), @golf['name']);
	_add_activity(@course, _to_upper_camel_case(@course));

	bind('player_interact', array(id: @course.'color'), array(button: 'right', hand: 'main_hand'), @event, @golf,
	@dyes = array('WHITE', 'LIGHT_GRAY', 'GRAY', 'BLACK', 'RED', 'ORANGE', 'MAGENTA', 'LIGHT_BLUE', 'YELLOW', 'LIME', 'GREEN', 'CYAN', 'BLUE', 'PURPLE', 'PINK', 'BROWN')) {
		if(array_index_exists(@golf['players'], player())) {
			@item = @event['item'];
			if(@item && string_ends_with(@item['name'], 'DYE')) {
				cancel();
				@dye = replace(@item['name'], '_DYE', '');
				@index = array_index(@dyes, @dye);
				@index++;
				@dye = @dyes[@index % 16];
				set_pinv(player(), null, array(name: @dye.'_DYE'));
				@golf['players'][player()]['dyecolor'] = @dye;
				if(@golf['players'][player()]['color'] && entity_exists(@golf['players'][player()]['color'])) {
					set_entity_spec(@golf['players'][player()]['color'], array(blockdata: @dye.'_STAINED_GLASS'));
					set_display_entity(@golf['players'][player()]['color'], array(glowcolor: _dye_to_rgb(@dye)));
				}
			}
		}
	}

	# Place ball
	bind('player_interact', array('id': @course), array(itemname: 'SLIME_BALL', button: 'right', block: 'WHITE_CONCRETE', hand: 'main_hand'), @event, @golf) {
		if(array_index_exists(@golf['players'], player())
		&& @event['facing'] === 'up'
		&& is_sign_at(location_shift(@event['location'], 'down'))) {

			@ball = @golf['players'][player()];
			@hole = @ball['hole'];
			@down = location_shift(@event['location'], 'down');

			# get hole data from sign
			@signText = get_sign_text(@down);
			if(@signText[0] != @hole) {
				if(@golf['test']) {
					@ball['hole'] = @hole;
				} else {
					die();
				}
			}

			@signBlock = get_blockdata(@down);
			if(!string_ends_with(@signBlock['block'], 'wall_hanging_sign')) {
				// fix sign type
				if(array_index_exists(@signBlock, 'rotation')) {
					switch(integer(@signBlock['rotation'] / 4) * 4) {
						case 0:
							set_blockdata(@down, 'oak_wall_hanging_sign[facing=south]');
						case 4:
							set_blockdata(@down, 'oak_wall_hanging_sign[facing=west]');
						case 8: 
							set_blockdata(@down, 'oak_wall_hanging_sign[facing=north]');
						case 12:
							set_blockdata(@down, 'oak_wall_hanging_sign[facing=east]');
					}
				} else {
					set_blockdata(@down, array(block: 'oak_wall_hanging_sign', facing: @signBlock['facing']));
				}
				set_sign_text(@down, @signText);
			}

			@options = associative_array();
			foreach(@option in split(',', @signText[2])) {
				@split = split('=', @option);
				@key = @split[0];
				@options[@key] = array_get(@split, 1, null);
			}

			@ball['size'] = 0.5;
			if(array_index_exists(@options, 'S') && @options['S']) {
				try(@ball['size'] = clamp(double(@options['S']), 0.0625, 0.9375))
			}

			@ballLoc = array(
				x: @event['location']['x'] + @event['position']['x'],
				y: @event['location']['y'] + @event['position']['y'],
				z: @event['location']['z'] + @event['position']['z'],
				world: @event['location']['world'],
			)

			foreach(@d in array('east', 'west', 'north', 'south')) {
				if(get_block(location_shift(@ballLoc, @d, @ball['size'] / 2)) !== 'AIR') {
					die();
				}
			}

			set_pinv(player(), null, null);
			set_pexp(player(), 0);

			if(_ball_exists(@ball['id'])) {
				_remove_ball(@ball['id'], @ball['slime']);
			} else {
				set_plevel(player(), 0);
			}
			unbind('golf_swing1_'.player());
			unbind('golf_swing2_'.player());
			unbind('golf_hit_'.player());

			_place_ball(@ballLoc, @ball);

			// intialize hole
			if(!array_index_exists(@golf, @hole)) {
				@par = 3;
				if(is_integral(@signText[1])) {
					@par = integer(@signText[1]);
				}
				@golf[@hole] = associative_array(
					loc: array(
						@event['location']['x'],
						@event['location']['y'] - 2,
						@event['location']['z'],
						@event['location']['world'],
					),
					par: @par,
					strokes: associative_array(),
					total: associative_array(),
					minecart: false,
				);
				if(array_index_exists(@options, 'M')) {
					@golf[@hole]['minecart'] = true;
				}
				set_block(@golf[@hole]['loc'], 'REDSTONE_BLOCK');
			}

			if(@golf['test'] || !array_index_exists(@golf[@hole]['strokes'], player())) {
				@golf[@hole]['strokes'][player()] = 0;
				set_plevel(0);
			}

			proc _charge_swing(@ball) {
				if(!@ball['swing']) {
					set_entity_glowing(@ball['slime'], true);
					@loc = entity_loc(@ball['id']);
					@ploc = ploc();
					@ploc['pitch'] = 0;
					@v = get_vector(@ploc, 1 / 8);
					set_pexp(0);
					@ball['swing'] = true;
					@tracer = array(particle: 'FALLING_DUST', block: @ball['dyecolor'].'_CONCRETE');
					set_interval(50, closure(){
						@xp = pexp();
						if(@xp < 99 && @ball['swing']) {
							set_pexp(min(99, pexp() + 4));
						} else {
							set_entity_glowing(@ball['slime'], false);
							clear_task();
							if(@ball['swing']) {
								set_pexp(0);
								@ball['swing'] = false;
							}
						}
						@v['x'] *= 1.15
						@v['z'] *= 1.15
						@loc['x'] += @v['x'];
						@loc['z'] += @v['z'];
						spawn_particle(@loc, @tracer);
					});
				}
			}

			bind('player_interact_at_entity', array(id: 'golf_swing2_'.player()), array(clicked: 'ARMOR_STAND', hand: 'main_hand'), @event, @player = player(), @golf) {
				if(@player != player(), die());
				@ball = @golf['players'][player()];
				if(@event['id'] == @ball['id']){
					cancel();
					_charge_swing(@ball);
				}
			}

			bind('entity_damage', array(id: 'golf_hit_'.player()), array(id: @ball['id'], cause: 'ENTITY_ATTACK'), @event, @golf) {
				cancel();
				if(!array_index_exists(@golf['players'], @event['damager'])) {
					die();
				}
				@xp = pexp(@event['damager']);
				@player = @event['damager'];
				@ball = @golf['players'][@player];
				@hole = @ball['hole'];
				if(@xp > 0 && @ball['swing']) {
					@ball['swing'] = false;
					@xp = max(2, @xp);
					@golf[@hole]['strokes'][@player] += 1;
					set_plevel(@player, @golf[@hole]['strokes'][@player]);
					set_pexp(@player, @xp);
					play_sound(@event['location'], array(sound: 'BLOCK_WOODEN_BUTTON_CLICK_ON', pitch: 2 - (1.3 / @xp)));
					play_sound(@event['location'], array(sound: 'ENTITY_SLIME_HURT_SMALL', volume: 0.4, pitch: 2 - (1.3 / @xp)));
					@ploc = ploc();
					@block = get_block(@event['location']);
					if(@block === 'SOUL_SAND') {
						@ploc['pitch'] = -54;
					} else {
						@ploc['pitch'] = 0;
					}
					@ball['velocity'] = get_vector(@ploc, @xp / 90);
					set_entity_velocity(@ball['id'], @ball['velocity']);
					set_pinv(@player, 0, array('name': 'SLIME_BALL'));
					spawn_particle(@event['location'], array(
						particle: 'BLOCK_CRACK',
						block: @ball['dyecolor'].'_STAINED_GLASS',
						count: integer(@xp / 2),
						xoffset: @ball['size'],
						zoffset: @ball['size']));
				}
			}
		}
	}

	@physics = array(
		slimeblock_bounciness: 1.5,
		booster_acceleration: 0.2,
		booster_dampener: 0.67,
		fan_vertical_acceleration: 0.65,
		bounciness: 0.8,
		slickness: 1.07,
	);
	export('slimeygolf.physics', @physics);

	// Main tick loop for player management, game logic, and ball physics
	set_interval(50, closure(){
		@playerCount = 0;
		foreach(@player in all_players()) {
			if(!array_index_exists(@golf['players'], @player)) {
				if(pworld(@player) === @golf['world'] && array_contains(sk_current_regions(@player), @course)) {
					if(@golf['lowestHole'] == 1 && array_size(@golf['players']) < 4 && _add_player(@player, @golf)) {
						@playerCount++;
					}
				}
				continue();
			} else if(pworld(@player) !== @golf['world'] || !array_contains(sk_current_regions(@player), @course)) {
				_remove_player(@player, @golf);
				continue();
			} 
			@ball = @golf['players'][@player];
			if(!_ball_exists(@ball['id'])) {
				if(@golf['test'] && (pmode(@player) === 'CREATIVE' || pmode(@player) === 'SPECTATOR')) {
					_remove_player(@player, @golf);
				} else {
					@playerCount++;
				}
				continue();
			}
			@playerCount++;
			@loc = entity_loc(@ball['id']);
			if(@loc['yaw'] > 0) {
				@loc['yaw'] += 10;
				set_entity_rotation(@ball['id'], @loc['yaw']);
				set_entity_rotation(@ball['color'], @loc['yaw']);
			}
			try(set_entity_loc(@ball['slime'], location_shift(@loc, 'up', 0.01)))
			if(get_entity_vehicle(@ball['id'])) {
				continue();
			}
			@v = entity_velocity(@ball['id']);
			@down = location_shift(@loc, 'down', 0.01);
			@block = _get_block_below(@down, @v, @ball['size']);

			@slickness = min(1.099, max(1.0, @physics['slickness']));
			if(@block === 'ICE') {
				// low friction
				@slickness = 1.08;
				@v['y'] = 0;
			} else if(@block === 'PACKED_ICE') {
				// lower friction
				@slickness = 1.09;
				@v['y'] = 0;
			} else if(@block === 'BLUE_ICE') {
				// lowest friction
				@slickness = 1.1;
				@v['y'] = 0;
			} else if(!@block) {
				// normal gravity, less air resistance
				@slickness = 1.1;
			} else if(material_info(@block, 'isTransparent') || @block === 'SOUL_SAND') {
				// normal gravity and friction
			} else if(@block === 'MAGENTA_GLAZED_TERRACOTTA') {
				@v['y'] = 0;
				@blockData = get_blockdata(@down);
				if(@blockData['block'] === 'magenta_glazed_terracotta') {
					play_sound(@ball['id'], array(sound: 'BLOCK_SCULK_SENSOR_CLICKING_STOP', pitch: 2, volume: 0.7));
					switch(@blockData['facing']) {
						case 'south':
							@v['x'] *= @physics['booster_dampener'];
							@v['z'] -= @physics['booster_acceleration'];
						case 'north':
							@v['x'] *= @physics['booster_dampener'];
							@v['z'] += @physics['booster_acceleration'];
						case 'west':
							@v['x'] += @physics['booster_acceleration'];
							@v['z'] *= @physics['booster_dampener'];
						case 'east':
							@v['x'] -= @physics['booster_acceleration'];
							@v['z'] *= @physics['booster_dampener'];
					}
				}
			} else if(@block === 'CHISELED_QUARTZ_BLOCK' && abs(@v['x']) + abs(@v['z']) != 0) {
				@v['y'] += @physics['fan_vertical_acceleration'];
				set_entity_rotation(@ball['id'], @loc['yaw'] + 10);
				set_entity_rotation(@ball['slime'], @loc['yaw'] + 10);
				set_entity_rotation(@ball['color'], @loc['yaw'] + 10);
				@center = _center(@loc, 0.125);
				@cloudCount = array(5);
				set_interval(100, 0, closure(){
					spawn_particle(@center, array(particle: 'CLOUD', count: 0, speed: 0.5, yoffset: 1.0));
					if(--@cloudCount[0] < 0) {
						clear_task();
					}
				});
				play_sound(@loc, array(sound: 'ENTITY_BREEZE_IDLE_GROUND', pitch: 1.5));
			} else if(@block === 'BLACK_WOOL') { 
				# check if ball dropped into hole
				@isHole = true;
				foreach(@dir in array('north', 'south', 'east', 'west')) {
					if(!material_info(get_block(location_shift(@loc, @dir)), 'isSolid')) {
						@isHole = false;
						break();
					}
				}
				if(@isHole) {
					_hole_out(@golf, @player);
					continue();
				} else {
					@v['y'] = 0;
				}
			} else {
				@v['y'] = 0;
			}

			@hole = @ball['hole'];
			if(@golf[@hole]['minecart']) {
				@ball['cooldown']--;
				if(@ball['cooldown'] <= 0) {
					@carts = entities_in_radius(@loc, 1, 'MINECART');
					if(@carts) {
						set_entity_rider(@carts[0], @ball['id']);
						@ball['cooldown'] = 10;
						continue();
					}
				}
			}

			@ricochetPitch = 0;
			@forceX = 0;
			if(@v['x'] == 0) {
				@forceX = abs(@ball['velocity']['x']);
				if(@forceX < 0.003) {
					@v['x'] = 0;
				} else {
					@v['magnitude'] = 1;
					@hitBlock = array(
						x: @loc['x'] + ((@ball['size'] / 2) + 0.01) * if(@ball['velocity']['x'] < 0, -1, 1),
						y: @loc['y'],
						z: @loc['z'],
						world: @loc['world']
					);
					if(get_block(@hitBlock) === 'SLIME_BLOCK') {
						@v['x'] = min(1.0, max(-1.0, 0 - @ball['velocity']['x'] * @physics['slimeblock_bounciness']));
						@v['y'] = @ball['velocity']['magnitude'] * 0.3;
						@v['z'] = @ball['velocity']['z'];
						spawn_particle(@hitBlock, array(
							particle: 'BLOCK_CRACK', 
							block: 'SLIME_BLOCK', 
							count: integer(@forceX * 60),
							xoffset: @ball['size'] / 2,
							zoffset: @ball['size'] / 2));
					} else {
						@v['x'] = 0 - @ball['velocity']['x'] * @physics['bounciness'];
						spawn_particle(@loc, array(
							particle: 'BLOCK_CRACK', 
							block: @ball['dyecolor'].'_STAINED_GLASS', 
							count: integer(@forceX * 30),
							xoffset: @ball['size'] / 2,
							zoffset: @ball['size'] / 2));
					}
					if(@forceX > 0.05) {
						@ricochetPitch = 1 + @forceX / 2;
					}
				}
			}

			@forceZ = 0;
			if(@v['z'] == 0) {
				@forceZ = abs(@ball['velocity']['z']);
				if(@forceZ < 0.003) {
					@v['z'] = 0;
				} else {
					@v['magnitude'] = 1;
					@hitBlock = array(
						x: @loc['x'],
						y: @loc['y'],
						z: @loc['z'] + ((@ball['size'] / 2) + 0.01) * if(@ball['velocity']['z'] < 0, -1, 1),
						world: @loc['world']
					);
					if(get_block(@hitBlock) === 'SLIME_BLOCK') {
						@v['x'] = @ball['velocity']['x'];
						@v['y'] = @ball['velocity']['magnitude'] * 0.3;
						@v['z'] = min(1.0, max(-1.0, 0 - @ball['velocity']['z'] * @physics['slimeblock_bounciness']));
						spawn_particle(@hitBlock, array(
							particle: 'BLOCK_CRACK', 
							block: 'SLIME_BLOCK', 
							count: integer(@forceZ * 60),
							xoffset: @ball['size'] / 2,
							zoffset: @ball['size'] / 2));
					} else {
						@v['z'] = 0 - @ball['velocity']['z'] * @physics['bounciness'];
						spawn_particle(@loc, array(
							particle: 'BLOCK_CRACK', 
							block: @ball['dyecolor'].'_STAINED_GLASS', 
							count: integer(@forceZ * 30),
							xoffset: @ball['size'] / 2,
							zoffset: @ball['size'] / 2));
					}
					if(@forceZ > 0.05 && @forceZ > @forceX) {
						@ricochetPitch = 1 + @forceZ / 2;
					}
				}
			}

			if(@v['magnitude'] < 0.875 && @v['magnitude'] > 0.125) {
				@v['x'] = (@v['x'] / @v['magnitude']) * (@slickness * @v['magnitude']);
				@v['z'] = (@v['z'] / @v['magnitude']) * (@slickness * @v['magnitude']);
			}

			if(@ricochetPitch > 1) {
				play_sound(@loc, array(sound: 'BLOCK_WOODEN_BUTTON_CLICK_ON', pitch: @ricochetPitch));
				play_sound(@loc, array(sound: 'ENTITY_SLIME_HURT_SMALL', volume: 0.4, pitch: @ricochetPitch));
			}

			@ball['velocity'] = @v;
			set_entity_velocity(@ball['id'], @ball['velocity']);
		}
		if(@playerCount == 0) {
			_golf_cleanup(@golf);
		}
	});
}

proc _hole_out(@golf, @player) {
	@ball = @golf['players'][@player];
	@hole = @ball['hole'];
	@loc = _center(entity_loc(@ball['id']));
	@type = 'Par';
	@par = @golf[@hole]['par'];
	@hits = @golf[@hole]['strokes'][@player];
	if(@hits == @par - 1) {
		@type = 'Birdie';
		launch_firework(@loc, array(strength: -1, type: 'BURST', colors: _dye_to_rgb(@ball['dyecolor'])));
	} else if(@hits == @par - 2) {
		@type = 'Eagle!';
		launch_firework(@loc, array(strength: -1, type: 'BURST', colors: _dye_to_rgb(@ball['dyecolor'])));
		launch_firework(@loc, array(strength: 0, type: 'BALL_LARGE', colors: _dye_to_rgb(@ball['dyecolor'])));
	} else if(@hits == @par - 3) {
		@type = 'Albatross!!';
		launch_firework(@loc, array(strength: -1, type: 'BURST', colors: _dye_to_rgb(@ball['dyecolor'])));
		launch_firework(@loc, array(strength: 0, type: 'BALL_LARGE', colors: _dye_to_rgb(@ball['dyecolor'])));
		launch_firework(@loc, array(strength: 1, type: 'BALL_LARGE', colors: _dye_to_rgb(@ball['dyecolor'])));
	} else if(@hits == @par - 4) {
		@type = 'Condor!!!';
		launch_firework(@loc, array(strength: -1, type: 'BURST', colors: _dye_to_rgb(@ball['dyecolor'])));
		launch_firework(@loc, array(strength: 0, type: 'BALL_LARGE', colors: _dye_to_rgb(@ball['dyecolor'])));
		launch_firework(@loc, array(strength: 1, type: 'BALL_LARGE', colors: _dye_to_rgb(@ball['dyecolor'])));
		launch_firework(@loc, array(strength: 2, type: 'BALL_LARGE', colors: _dye_to_rgb(@ball['dyecolor'])));
	} else if(@hits > @par) {
		switch(@hits - @par) {
			case 1:
				@type = 'Bogey';
			case 2:
				@type = 'Double Bogey';
			case 3:
				@type = 'Triple Bogey';
			default:
				@type = '';
		}
	}

	@id = @ball['id'];
	@slime = @ball['slime'];
	set_timeout(1500, closure() {
		// Hole out feedback
		play_sound(ploc(@player), array(sound: 'ENTITY_VILLAGER_WORK_CARTOGRAPHER'));
		if(@hits == 1) {
			title(@player, 'Hole in One!', @type);
		} else if(@type) {
			title(@player, null, @type);
		}
		_remove_ball(@id, @slime);
	});

	// Clean up for this hole
	unbind('golf_swing1_'.@player);
	unbind('golf_swing2_'.@player);
	unbind('golf_hit_'.@player);
	@ball['id'] = 0;

	// Add up score total for this hole
	if(array_index_exists(@golf, @hole - 1) && array_index_exists(@golf[@hole - 1]['total'], @player)) {
		@golf[@hole]['total'][@player] = @golf[@hole - 1]['total'][@player] + @hits;
	} else {
		@golf[@hole]['total'][@player] = @hits;
	}

	// Check if last player to leave hole
	@lastplayer = true;
	foreach(@p: @b in @golf['players']) {
		if(@p != @player
		&& @b['hole'] <= @hole) {
			@lastplayer = false;
			break();
		}
	}
	if(@lastplayer && !@golf['test']) {
		_end_hole(@golf, @hole);
	}

	// Prepare player for next hole
	@ball['hole'] += 1;
}

proc _end_hole(@golf, @hole) {
	set_block(@golf[@hole]['loc'], 'AIR');
	@golf['lowestHole'] = min(9, @hole + 1);
	@golf['par'] += @golf[@hole]['par'];

	// Update sidebar and score output for players
	@score = 0;
	if(array_size(@golf['players']) > 1) {
		@header = color(7).'Hole\''.color('r').@hole.color(8).'*';
		@scores = color(7).'Score'.color(8).'*';
		foreach(@p: @b in @golf['players']) {
			@score = @golf[@hole]['total'][@p] - @golf['par'];
			set_pscore('strokes', @p, @score, @golf['name']);
			@pname = @p;
			if(_string_width(@p) > 72){
				@pname = substr(@p, 0, 12);
			}
			@header .= _fill_string('*', '.', '*'.color('a').@pname.color(8).'*', 72).'*';
			@scores .= _fill_string('*', '.', '*'.color('r').@golf[@hole]['strokes'][@p]
					.' ('.if(@score < 0, color('a'), if(@score > 0, color(6).'+')).@score.color('r').')*', 72).'*';
		}
		@header = _fill_string('*', '.', @header);
		@scores = _fill_string('*', '.', @scores);
		_regionmsg(@golf['name'], @header);
		_regionmsg(@golf['name'], @scores);
	} else {
		@player = array_keys(@golf['players'])[0];
		@score = @golf[@hole]['total'][@player] - @golf['par'];
		set_pscore('strokes', @player, @score, @golf['name']);
		tmsg(@player, colorize('&7&l[ &a&lHOLE &6&l'.@hole.' &7&l] &r'
				.(@golf[@hole]['strokes'][@player] - @golf[@hole]['par'])));
	}

	// If last hole, end game
	if(@hole == 9) {
		_end_game(@golf);
	}
}

proc _end_game(@golf) {
	clear_task();
	if(array_size(@golf['players']) > 1) {
		@loweststrokes = 999;
		@winner = '';
		foreach(@p: @b in @golf['players']) {
			if(ponline(@p)) {
				@strokes = @golf[9]['total'][@p];
				if(@strokes < @loweststrokes) {
					@winner = @p;
					@loweststrokes = @strokes;
				}
			}
		}
		_regionmsg(@golf['name'], colorize(
			'&a&lSLIMEY&6&lGOLF &a\u2308\u2328 \uFE52\u2328\u2309&r\n'
			._colorname(@winner).'&l'.@winner.'&r&l is the winner!'
		));
		_acc_add(@winner, array_size(@golf['players']) - 1);
	} else {
		@player = array_keys(@golf['players'])[0];
		@score = @golf[9]['total'][@player] - @golf['par'];
		if(@score <= -9) {
			tmsg(@player, colorize(
				'&a&lSLIMEY&6&lGOLF &a\u2308\u2328 \uFE52\u2328\u2309&r &lFantastic!'
			));
		} else if(@score < 0) {
			tmsg(@player, colorize(
				'&a&lSLIMEY&6&lGOLF &a\u2308\u2328 \uFE52\u2328\u2309&r &lGood Job!'
			));
		}
	}

	set_timeout(10000, closure(){
		_golf_cleanup(@golf);
	});
}

proc _golf_cleanup(@golf) {
	foreach(@player in array_keys(@golf['players'])) {
		_remove_player(@player, @golf);
	}
	unbind(@golf['name']);
	unbind(@golf['name'].'color');
	_remove_activity(@golf['name']);
	clear_task();
	try {
		remove_scoreboard(@golf['name']);
	} catch(ScoreboardException @ex) {}
}
