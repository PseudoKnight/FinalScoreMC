include('course.ms');
include('player.ms');
include('ball.ms');

proc _start_game(@course, @loc, @hole = 1) {
	@golf = array(
		'name': @course,
		'world': @loc['world'],
		'par': 0,
		'players': associative_array(),
		'spectators': array(),
		'lowestHole': @hole,
		'highestHole': if(@hole == 1, 9, @hole)
	);

	_create_scoreboards(@golf);
	foreach(@player in all_players(@loc['world'])) {
		if(ponline(@player) && array_contains(sk_current_regions(@player), @course)
		&& _add_player(@player, @golf)
		&& array_size(@golf['players']) >= 4) {
			break();
		}
	}

	_add_activity(@course, _to_upper_camel_case(@course));

	broadcast(colorize(
		'&a&lSLIMEY&6&lGOLF &a\u2308\u2328 \uFE52\u2328\u2309&r\n'
		.'&6&l[ How to Play ]&r\n'
		.'- Place slime ball on starting location.\n'
		.'- Right-click slime ball to start swing.\n'
		.'- Wait for desired strength and then hit slime into the hole.'
	), array_keys(@golf['players']));

	# Place ball
	bind('player_interact', array('id': @course), array(itemname: 'SLIME_BALL', button: 'right', block: 'WHITE_CONCRETE'), @event, @golf) {
		if(array_index_exists(@golf['players'], player())
		&& @event['facing'] === 'up'
		&& is_sign_at(location_shift(@event['location'], 'down'))) {

			@ball = @golf['players'][player()];
			@hole = @ball['hole'];

			# get hole data from sign
			@sign = get_sign_text(location_shift(@event['location'], 'down'));
			if(@sign[0] != @hole) {
				die();
			}

			set_pinv(player(), null, null);
			set_pexp(player(), 0);

			if(_ball_exists(@ball['id'])) {
				_remove_ball(@ball, @golf['name']);
				unbind('golf_swing1_'.player());
				unbind('golf_swing2_'.player());
				unbind('golf_hit_'.player());
			} else {
				set_plevel(player(), 0);
			}

			@mobtype = 'MAGMA_CUBE';
			if(@ball['type'] == 0 || @ball['type'] == 2) {
				@mobtype = 'SLIME';
			}

			@ballLoc = array(
				x: @event['location']['x'] + @event['position']['x'],
				y: @event['location']['y'] + @event['position']['y'],
				z: @event['location']['z'] + @event['position']['z'],
				world: @event['location']['world'],
			)

			_place_ball(@mobtype, @ballLoc, @ball, @golf['name']);

			if(!array_index_exists(@golf, @hole)) {
				@par = 3;
				if(is_integral(@sign[1])) {
					@par = integer(@sign[1]);
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
				if(array_contains(@sign[2], 'M')) {
					@golf[@hole]['minecart'] = true;
				}
				set_pscore('strokes', '--Par-------', @golf[@hole]['par'], @golf['name'].@hole);
				set_block(@golf[@hole]['loc'], 'REDSTONE_BLOCK');
			}

			if(!array_index_exists(@golf[@hole]['strokes'], player())) {
				@golf[@hole]['strokes'][player()] = 0;
				set_pscore('strokes', player(), 0, @golf['name'].@hole);
			}

			proc _charge_swing(@ball) {
				if(!@ball['swing']) {
					@loc = entity_loc(@ball['id']);
					@ball['origin'] = ploc();
					@ball['origin']['y'] = @loc['y'];
					@dist = distance(@ball['origin'], @loc);
					@v = associative_array(
						'x': (@loc['x'] - @ball['origin']['x']) / (@dist * 6),
						'z': (@loc['z'] - @ball['origin']['z']) / (@dist * 6),
					);
					set_pexp(0);
					@ball['swing'] = true;
					@tracer = array('particle': 'END_ROD');
					set_interval(50, closure(){
						@xp = pexp();
						if(@xp < 99 && @ball['swing']) {
							set_pexp(min(99, pexp() + 4));
						} else {
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

			bind('player_interact_at_entity', array(id: 'golf_swing1_'.player()), array('clicked': @mobtype), @event,
					@player = player(), @golf) {

				if(@player != player(), die());
				@ball = @golf['players'][player()];
				if(@event['id'] == @ball['slime']){
					cancel();
					_charge_swing(@ball);
				}
			}

			bind('player_interact_at_entity', array(id: 'golf_swing2_'.player()), array('clicked': 'ARMOR_STAND'), @event,
					@player = player(), @golf) {

				if(@player != player(), die());
				@ball = @golf['players'][player()];
				if(@event['id'] == @ball['id']){
					cancel();
					_charge_swing(@ball);
				}
			}

			bind('entity_damage', array(id: 'golf_hit_'.player()), array('id': '/('.@ball['id'].'|'.@ball['slime'].')/', 'cause': 'ENTITY_ATTACK'), @event, @golf) {
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
					set_plevel(@player, plevel(@player) + 1);
					set_pexp(@player, @xp);
					@golf[@hole]['strokes'][@player] += 1;
					set_pscore('strokes', @player, @golf[@hole]['strokes'][@player], @golf['name'].@hole);
					play_sound(entity_loc(@event['id']), array('sound': 'BLOCK_WOODEN_BUTTON_CLICK_ON', 'pitch': 2 - (1.3 / @xp)));
					@ploc = entity_loc(puuid(@player));
					@eloc = entity_loc(@ball['id']);
					@dist = distance(@ploc, @eloc);
					@x = ((@eloc['x'] - @ploc['x']) / @dist) * (@xp / 90);
					@z = ((@eloc['z'] - @ploc['z']) / @dist) * (@xp / 90);
					@ball['velocity'] = array('x': @x, 'y': 0, 'z': @z);
					set_entity_velocity(@ball['id'], @ball['velocity']);
					set_timeout(1, closure(){
						@ball['velocity'] = array('x': @x, 'y': 0, 'z': @z);
						try(set_entity_velocity(@ball['id'], @ball['velocity']))
					})
					set_pinv(@player, 0, array('name': 'SLIME_BALL'));
				}
			}
		}
	}

	set_interval(50, closure(){
		# Physics defaults
		@bounciness = 0.8;
		@friction = 1.07;

		@count = 0;
		foreach(@player in all_players()) {
			if(!array_index_exists(@golf['players'], @player)) {
				if(pworld(@player) == @golf['world'] && array_contains(sk_current_regions(@player), @course)) {
					if(@golf['lowestHole'] == 1 && array_size(@golf['players']) < 4 && _add_player(@player, @golf)) {
						@count++;
					} else if(!array_contains(@golf['spectators'], @player)) {
						@golf['spectators'][] = @player;
					}
				} else if(array_contains(@golf['spectators'], @player)) {
					array_remove_values(@golf['spectators'], @player);
				}
				continue();
			} else if(pworld(@player) != @golf['world'] || !array_contains(sk_current_regions(@player), @course)) {
				_remove_player(@player, @golf);
				continue();
			} else {
				@count++;
			}
			@ball = @golf['players'][@player];
			if(_ball_exists(@ball['id'])) {
				@loc = entity_loc(@ball['id']);
				try(set_entity_loc(@ball['slime'], @loc))
				if(get_entity_vehicle(@ball['id'])) {
					continue();
				}
				@v = entity_velocity(@ball['id']);
				@block = _get_block_below(location_shift(@loc, 'down', 0.01), @v);
				@hole = @ball['hole'];
				if(@block === 'POWERED_RAIL') {
					// do nothing
				} else if(@block === 'BLACK_WOOL') { # if ball dropped into the hole
					# check for birdie/eagle
					@hits = plevel(@player);
					@par = @golf[@hole]['par'];
					@type = 'Par';
					if(@hits == @par - 1) {
						@type = 'Birdie';
						launch_firework(@loc,
							array('strength': 0, 'type': 'BURST'));
						play_sound(ploc(@player), array('sound': 'ENTITY_VILLAGER_YES'));
					} else if(@hits == @par - 2) {
						@type = 'Eagle!';
						launch_firework(@loc,
							array(strength: 0, type: 'BALL_LARGE'));
						play_sound(ploc(@player), array(sound: 'ENTITY_VILLAGER_YES'));
					} else if(@hits == @par - 3) {
						@type = 'Albatross!!';
						launch_firework(@loc,
							array(strength: 0, type: 'BALL_LARGE'));
						launch_firework(@loc,
							array(strength: 1, type: 'BALL_LARGE'));
						play_sound(ploc(@player), array(sound: 'ENTITY_VILLAGER_YES'));
					} else if(@hits == @par - 4) {
						@type = 'Condor!!!';
						launch_firework(@loc,
							array(strength: 0, type: 'BALL_LARGE'));
						launch_firework(@loc,
							array(strength: 1, type: 'BALL_LARGE'));
						launch_firework(@loc,
							array(strength: 2, type: 'BALL_LARGE'));
						play_sound(ploc(@player), array(sound: 'ENTITY_VILLAGER_YES'));
					} else if(@hits > @par) {
						play_sound(ploc(@player), array(sound: 'ENTITY_VILLAGER_NO'));
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

					if(@hits == 1) {
						title(@player, 'Hole in One!', null);
					} else if(@type) {
						title(@player, null, @type);
					}

					# clean up the hole for this player
					_remove_ball(@ball, @course);
					unbind('golf_swing1_'.@player)
					unbind('golf_swing2_'.@player);
					unbind('golf_hit_'.@player);

					if(@hole > 1 && @golf['lowestHole'] != @golf['highestHole']) {
						@golf[@hole]['total'][@player] = @golf[@hole - 1]['total'][@player] + @golf[@hole]['strokes'][@player];
					} else {
						@golf[@hole]['total'][@player] = @golf[@hole]['strokes'][@player];
					}

					# check if last player to leave hole
					@lastplayer = true;
					foreach(@p: @b in @golf['players']) {
						if(@p != @player
						&& @b['hole'] <= @hole) {
							@lastplayer = false;
							break();
						}
					}
					if(@lastplayer) {
						set_block(@golf[@hole]['loc'], 'AIR');
						@golf['lowestHole'] = min(9, @hole + 1);
						@golf['par'] += @golf[@hole]['par'];

						# update sidebars and score output for players
						@score = 0;
						if(array_size(@golf['players']) > 1) {
							@header = color(7).'Hole\''.color('r').@hole.color(8).'*';
							@scores = color(7).'Score'.color(8).'*';
							foreach(@p: @b in @golf['players']) {
								set_pscoreboard(@p, @golf['name'].@golf['lowestHole']);
								@score = @golf[@hole]['total'][@p] - @golf['par'];
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
							set_pscoreboard(@player, @golf['name'].@golf['lowestHole']);
							@score = @golf[@hole]['total'][@player] - @golf['par'];
							tmsg(@player, colorize('&7&l[ &a&lHOLE &6&l'.@hole.' &7&l] &r'
									.if(@type, @type, @golf[@hole]['strokes'][@player])
									.'&7 (Course: &r'.if(@score < 0, '&a', if(@score > 0, '&6+')).@score.'&7)'));
						}

						# check if last hole
						if(@hole == @golf['highestHole']) {
							@loweststrokes = 999;
							@winner = '';
							foreach(@p: @b in @golf['players']) {
								if(ponline(@p)) {
									@strokes = @golf[@hole]['total'][@p];
									if(@strokes < @loweststrokes) {
										@winner = @p;
										@loweststrokes = @strokes;
									}
								}
							}

							if(array_size(@golf['players']) > 1) {
								_regionmsg(@course, colorize(
									'&a&lSLIMEY&6&lGOLF &a\u2308\u2328 \uFE52\u2328\u2309&r\n'
									._colorname(@winner).'&l'.@winner.'&r&l is the winner!'
								));
							} else if(@score <= -9) {
								_regionmsg(@course, colorize(
									'&a&lSLIMEY&6&lGOLF &a\u2308\u2328 \uFE52\u2328\u2309&r\n'
									.'&lFantastic!'
								));
							} else if(@score < 0) {
								_regionmsg(@course, colorize(
									'&a&lSLIMEY&6&lGOLF &a\u2308\u2328 \uFE52\u2328\u2309&r\n'
									.'&lGood Job!'
								));
							}

							if(array_size(@golf['players']) > 1) {
								_acc_add(@winner, 1);
							}

							set_timeout(10000, closure(){
								_golf_cleanup(@golf);
							});
							clear_task();
							break();
						}
					}

					# prepare player for next hole
					@ball['hole'] += 1;
					@ball['id'] = 0;
					continue();
				} else {
					@v['y'] = 0;
				}

				if(@golf[@hole]['minecart']) {
					@carts = entities_in_radius(@loc, 1, 'MINECART');
					if(@carts) {
						set_entity_rider(@carts[0], @ball['id']);
						continue();
					}
				}

				@ricochetPitch = 0;
				@forceX = 0;
				if(@v['x'] == 0) {
					@forceX = abs(@ball['velocity']['x']);
					@v['magnitude'] = 1;
					if(@forceX < 0.002) {
						@v['x'] = 0;
					} else {
						@v['x'] = 0 - @ball['velocity']['x'] * @bounciness;
						if(@forceX > 0.05) {
							@ricochetPitch = 1 + @forceX / 2;
						}
					}
				}

				@forceZ = 0;
				if(@v['z'] == 0) {
					@forceZ = abs(@ball['velocity']['z']);
					@v['magnitude'] = 1;
					if(@forceZ < 0.002) {
						@v['z'] = 0;
					} else {
						@v['z'] = 0 - @ball['velocity']['z'] * @bounciness;
						if(@forceZ > 0.06 && @forceZ > @forceX) {
							@ricochetPitch = 1 + @forceZ / 2;
						}
					}
				}

				if(@v['magnitude'] < 0.875 && @v['magnitude'] > 0.125) {
					@v['x'] = (@v['x'] / @v['magnitude']) * (@friction * @v['magnitude']);
					@v['z'] = (@v['z'] / @v['magnitude']) * (@friction * @v['magnitude']);
					spawn_particle(@loc, 'SLIME');
				}

				if(@ricochetPitch > 1) {
					play_sound(@loc, array('sound': 'BLOCK_WOODEN_BUTTON_CLICK_ON', 'pitch': min(2, @ricochetPitch)));
				}

				@ball['velocity'] = array('x': @v['x'], 'y': @v['y'], 'z': @v['z']);
				set_entity_velocity(@ball['id'], @ball['velocity']);
				if(@ball['type'] >= 2) {
					play_entity_effect(@ball['id'], 'HURT');
				}
			}
		}
		if(@count == 0) {
			_golf_cleanup(@golf);
		}
	});
}

proc _golf_cleanup(@golf) {
	foreach(@player in array_keys(@golf['players'])) {
		_remove_player(@player, @golf);
	}
	unbind(@golf['name']);
	_remove_activity(@golf['name']);
	clear_task();
	try {
		for(@i = 1, @i < 10, @i++) {
			remove_scoreboard(@golf['name'].@i);
		}
	} catch(ScoreboardException @ex) {
		// Never finished the game, so nothing left to cleanup
	}
}

proc _create_scoreboards(@golf) {
	for(@i = 1, @i < 10, @i++) {
		create_scoreboard(@golf['name'].@i);
		create_objective('strokes', 'DUMMY', @golf['name'].@i);
		set_objective_display('strokes', array('displayname': colorize('&7&l[ &a&lHole &6&l'.@i.'&7&l ]'), 'slot': 'SIDEBAR'), @golf['name'].@i);
	}
}
