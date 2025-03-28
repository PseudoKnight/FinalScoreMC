<!
	description: A game of hockey where two teams fight to knock a slime into the opponent's goal.;

	requiredExtensions: SKCompat;
	requiredProcs: _add_activity() and _remove_activity() procedures to keep a list of all current activities on server.
>
register_command('hockey', array(
	description: 'Starts a hockey game in hockey region.',
	usage: '/hockey',
	tabcompleter: closure(return(array())),
	executor: closure(@alias, @sender, @args, @info) {
		if(array_contains(get_scoreboards(), 'hockey')) {
			die(color('gold').'Hockey already running.');
		}

		@players = array();
		@invitations = array();
		foreach(@p in all_players(pworld())) {
			if(array_contains(sk_current_regions(@p), 'hockey')) {
				@players[] = @p;
			} else {
				@invitations[] = @p;
			}
		}
		if(array_size(@players) < 1) {
			die(color('gold').'Not enough players.');
		} else if(array_size(@players) % 2 == 1) {
			//die('Teams are not even.');
		}

		_click_tell(@invitations, array('&7[Hockey]&r Starting... ', array('&b[Click to Warp]', '/warp hockey')));

		proc _queue_game(@players) {
			_add_activity('hockey', 'Ice Hockey');
			@red = array(name: 'RED_STAINED_GLASS_PANE');
			@blue = array(name: 'BLUE_STAINED_GLASS_PANE');
			@hockey = array(
				players: @players,
				puck: '',
				velocity: null,
				holder: '',
				distance: 0,
				last: '',
				seconds: 180,
				red: '',
				blue: '',
				loc: null,
				lastloc: null,
				axis: 'z',
				redgear: array(
					4: @red, 5: @red, 6: @red, 7: @red, 8: @red,
					100: array(name: 'LEATHER_BOOTS', meta: array(color: array(255, 0, 0))),
					101: array(name: 'LEATHER_LEGGINGS', meta: array(color: array(255, 0, 0))),
					102: array(name: 'LEATHER_CHESTPLATE', meta: array(color: array(255, 0, 0))),
					103: array(name: 'LEATHER_HELMET', meta: array(color:array(255, 0, 0))),
				),
				bluegear: array(
					4: @blue, 5: @blue, 6: @blue, 7: @blue, 8: @blue,
					100: array(name: 'LEATHER_BOOTS', meta: array(color: array(0, 0, 255))),
					101: array(name: 'LEATHER_LEGGINGS', meta: array(color: array(0, 0, 255))),
					102: array(name: 'LEATHER_CHESTPLATE', meta: array(color: array(0, 0, 255))),
					103: array(name: 'LEATHER_HELMET', meta: array(color: array(0, 0, 255))),
				),
			);
			@hockey['players'] = @players;

			// create scoreboard
			create_scoreboard('hockey');
			create_objective('score', 'dummy', 'hockey');
			set_objective_display('score', array(slot: 'SIDEBAR', displayname: color('bold').'Score'), 'hockey');

			@hockey['red'] = color('red').array_get_rand(array('StoneRiver Toads', 'Utah Waffles', 'Jaksonville Slashers', 'Oakdale Furies'));
			create_team('red', 'hockey');
			set_team_display('red', array(displayname: @hockey['red'], color: 'RED'), 'hockey');
			set_pscore('score', @hockey['red'], 0, 'hockey');

			@hockey['blue'] = color('blue').array_get_rand(array('Gothem Knights', 'Stirling Kings', 'PantsCo Pixies', 'Canada Wizards'));
			create_team('blue', 'hockey');
			set_team_display('blue', array(displayname: @hockey['blue'], color: 'BLUE'), 'hockey');
			set_pscore('score', @hockey['blue'], 0, 'hockey');

			@t = 0;
			@world = '';
			foreach(@p in array_rand(@players, array_size(@players), false)) {
				@world = pworld(@p);
				set_pscoreboard(@p, 'hockey');
				if(@t) {
					team_add_player('red', @p, 'hockey');
					@t = 0;
					set_pinv(@p, @hockey['redgear']);
				} else {
					team_add_player('blue', @p, 'hockey');
					@t = 1;
					set_pinv(@p, @hockey['bluegear']);
				}
				set_pheld_slot(@p, 0);
			}

			// get puck spawn point
			@region = sk_region_info('hockey', @world, 0);
			@hockey['loc'] = array(
				x: (@region[0][0] + @region[1][0]) / 2 + 0.5,
				y: @region[1][1] + 0.078,
				z: (@region[0][2] + @region[1][2]) / 2 + 0.5,
				world: @world
			);
			if(@region[0][0] - @region[1][0] < @region[0][2] - @region[1][2]) {
				@hockey['axis'] = 'x';
			}

			@countdown = array(5);
			set_interval(1000, closure(){
				play_sound(@hockey['loc'], array(sound: 'BLOCK_NOTE_BLOCK_PLING', volume: 2, pitch: @countdown[0]));
				if(@countdown[0] > 0) {
					@countdown[0]--;
				} else {
					clear_task();
					_start_game(@hockey);
				}
			});
		}

		proc _start_game(@hockey) {
			_place_puck(@hockey);

			// bind events
			bind('entity_damage', array(id: 'hockey-damage'), array(id: @hockey['puck']), @event, @hockey) {
				if(!array_index_exists(@event, 'damager')) {
					@hockey['holder'] = '';
					set_entity_loc(@hockey['puck'], @hockey['lastloc']);
					die();
				}
				cancel();
				@xp = 30;
				if(@event['damager'] == @hockey['holder']) {
					@xp = max(1, (pexp(@event['damager']) / 2) ** 1.25);
				}
				@player = @event['damager'];
				play_sound(entity_loc(@event['id']), array(sound: 'BLOCK_WOODEN_BUTTON_CLICK_ON', pitch: 2 - (1.3 / @xp)));
				@ploc = entity_loc(puuid(@player));
				@eloc = entity_loc(@hockey['puck']);
				@dist = distance(@ploc, @eloc);
				@x = ((@eloc['x'] - @ploc['x']) / @dist) * (@xp / 50);
				@z = ((@eloc['z'] - @ploc['z']) / @dist) * (@xp / 50);
				@hockey['velocity'] = array(x: @x, y: 0, z: @z);
				set_entity_velocity(@hockey['puck'], @hockey['velocity']);
				@hockey['last'] = @player;
				@hockey['holder'] = '';
			}
			bind('player_interact_entity', array(id: 'hockey-interact'), null, @event, @hockey) {
				if(@event['id'] != @hockey['puck']) {
					die();
				}
				@ploc = ploc();
				@eloc = entity_loc(@hockey['puck']);
				@ploc['y'] += 1;
				@dist = distance(@ploc, @eloc);
				if(@dist < 3.5) {
					@hockey['holder'] = player();
					@hockey['last'] = player();
					@hockey['distance'] = @dist;
					@hockey['velocity'] = array(x: 0, y: 0, z: 0);
					@hockey['lastloc'] = entity_loc(@hockey['puck']);
					set_pexp(0);
					play_sound(@eloc, array(sound: 'BLOCK_WOODEN_BUTTON_CLICK_ON', pitch: 0.6));
				}
			}
			bind('entity_damage_player', array(id: 'hockey-damage-player'), array(damager: 'PLAYER'), @event, @hockey) {
				if(@hockey['holder'] == player()) {
					set_pexp(@hockey['holder'], 0);
					@hockey['holder'] = '';
				}
			}
			bind('player_quit', array(id: 'hockey-quit'), null, @event, @hockey) {
				if(array_contains(@hockey['players'], player())) {
					array_remove_values(@hockey['players'], player());
					@team = get_pteam(player(), 'hockey');
					team_remove_player(@team['name'], player(), 'hockey');
					if(array_size(@team['players']) < 2) {
						_end_game(@hockey);
					}
					if(@hockey['holder'] == player()) {
						_place_puck(@hockey);
					}
				}
			}
			bind('target_player', array(id: 'hockey-target'), array(mobtype: 'SLIME'), @event, @hockey) {
				if(@event['id'] == @hockey['puck']) {
					modify_event('player', null);
				}
			}

			// core game loop
			@count = array(20);
			@bounciness = 0.85;
			@world = @hockey['loc']['world'];
			set_interval(50, 0, closure(){
				if(--@count[0] == 0) {
					@count[0] = 20;
					@hockey['seconds']--;
					@time = simple_date('m:ss', @hockey['seconds'] * 1000);
					foreach(@p in all_players(@world)) {
						if(array_contains(sk_current_regions(@p), 'hockey')) {
							if(!array_contains(@hockey['players'], @p)) {
								@hockey['players'][] = @p;
								@teams = get_teams('hockey');
								if(array_size(@teams['red']['players']) > array_size(@teams['blue']['players'])) {
									team_add_player('blue', @p, 'hockey');
									set_pinv(@p, @hockey['bluegear']);
								} else {
									team_add_player('red', @p, 'hockey');
									set_pinv(@p, @hockey['redgear']);
								}
								set_pheld_slot(@p, 0);
								set_pscoreboard(@p, 'hockey');
							}
							action_msg(@p, @time);
							set_peffect(@p, 'JUMP_BOOST', -6, 2, false, false);
						} else if(array_contains(@hockey['players'], @p)) {
							array_remove_values(@hockey['players'], @p);
							@team = get_pteam(@p, 'hockey');
							team_remove_player(@team['name'], @p, 'hockey');
							if(array_size(@team['players']) < 2) {
								_end_game(@hockey);
								die();
							}
						}
					}
					if(@hockey['seconds'] < 1) {
						_end_game(@hockey);
						die();
					}
				}

				if(!entity_exists(@hockey['puck'])) {
					_end_game(@hockey);
					die();
				}

				@l = entity_loc(@hockey['puck']);
				@block = get_block(location_shift(@l, 'down'));

				if(@block == 'RED_WOOL' || @block == 'BLUE_WOOL') {
					@team = if(@block == 'BLUE_WOOL', @hockey['red'], @hockey['blue']);
					set_pscore('score', @team, get_pscore('score', @team, 'hockey') + 1, 'hockey');
					launch_firework(@l, array(strength: 0));
					_place_puck(@hockey);

				} else if(@block == 'STONE_SLAB') {
					@hockey['holder'] = '';
					set_entity_loc(@hockey['puck'], @hockey['lastloc']);

				} else if(@hockey['holder'] && (@block == 'ICE' || @block == 'PACKED_ICE')) {
					@newloc = ploc(@hockey['holder']);
					if(@newloc['world'] != @world) {
						_place_puck(@hockey);
					} else {
						if(@hockey['distance'] > 2.22) {
							@hockey['distance'] -= 0.03;
							set_pexp(@hockey['holder'], pexp(@hockey['holder']) + 1);
						} else if(@hockey['distance'] < 2.18) {
							@hockey['distance'] += 0.03;
							set_pexp(@hockey['holder'], pexp(@hockey['holder']) + 1);
						} else {
							set_pexp(@hockey['holder'], min(99, pexp(@hockey['holder']) + 2));
						}
						@vector = get_vector(ploc(@hockey['holder']), @hockey['distance']);
						@newloc['x'] += @vector['x'];
						@newloc['y'] += 1;
						@newloc['z'] += @vector['z'];
						set_entity_loc(@hockey['puck'], @newloc);
						@hockey['lastloc'] = @l;
					}

				} else if(!sk_region_contains('hockey', @l) || @l['y'] > @hockey['loc']['y']) {
						_place_puck(@hockey);

				} else {
					@v = entity_velocity(@hockey['puck']);
					@ricochetPitch = 0;

					@forceX = 0;
					if(@v['x'] == 0) {
						@forceX = abs(@hockey['velocity']['x']);
						@v['magnitude'] = 1;
						if(@forceX > 0.002) {
							@v['x'] = 0 - @hockey['velocity']['x'] * @bounciness;
							if(@forceX > 0.05) {
								@ricochetPitch = 1 + @forceX / 2;
							}
						}
					}

					if(@v['z'] == 0) {
						@forceZ = abs(@hockey['velocity']['z']);
						@v['magnitude'] = 1;
						if(@forceZ > 0.002) {
							@v['z'] = 0 - @hockey['velocity']['z'] * @bounciness;
							if(@forceZ > 0.06 && @forceZ > @forceX) {
								@ricochetPitch = 1 + @forceZ / 2;
							}
						}
					}

					if(@v['magnitude'] < 0.875 && @v['magnitude'] > 0.125) {
						@v['x'] = (@v['x'] / @v['magnitude']) * (1.08 * @v['magnitude']);
						@v['z'] = (@v['z'] / @v['magnitude']) * (1.08 * @v['magnitude']);
					}

					if(@ricochetPitch > 1) {
						play_sound(@l, array(sound: 'BLOCK_WOODEN_BUTTON_CLICK_ON', pitch: min(2, @ricochetPitch)));
					}

					@v['y'] = 0;
					@hockey['velocity'] = @v;
					set_entity_velocity(@hockey['puck'], @hockey['velocity']);
				}

			});
		}

		proc _place_puck(@hockey){
			@loc = @hockey['loc'][];
			@loc[@hockey['axis']] += rand(5) - 2;
			if(!@hockey['puck']) {
				@hockey['puck'] = spawn_entity('SLIME', 1, @loc, closure(@e) {
					set_entity_saves_on_unload(@e, false);
					set_entity_spec(@e, array(size: 1));
				})[0];
				set_timeout(1, closure(){
					set_mob_effect(@hockey['puck'], 'resistance', 4, 99999, true, false);
					set_mob_effect(@hockey['puck'], 'levitation', -1, 99999, true, false);
					set_mob_effect(@hockey['puck'], 'slowness', 10, 99999, true, false);
				});
			} else {
				set_entity_loc(@hockey['puck'], @loc);
			}
			@hockey['holder'] = '';
			@hockey['last'] = '';
			@hockey['velocity'] = array(x: 0, y: 0, z: 0);
			set_entity_velocity(@hockey['puck'], @hockey['velocity']);
		}

		proc _end_game(@hockey){
			clear_task();
			unbind('hockey-damage');
			unbind('hockey-damage-player');
			unbind('hockey-interact');
			unbind('hockey-quit');
			unbind('hockey-target');
			@winner = null;
			@redscore = get_pscore('score', @hockey['red'], 'hockey');
			@bluescore = get_pscore('score', @hockey['blue'], 'hockey');
			@score = '';
			if(@redscore > @bluescore) {
				@winner = 'red';
				@score = @redscore.':'.@bluescore;
			} else if(@bluescore > @redscore) {
				@winner = 'blue';
				@score = @bluescore.':'.@redscore;
			} else {
				@score = @redscore.':'.@bluescore;
			}
			@msg = 'Tied game!';
			if(@winner) {
				@teams = get_teams('hockey');
				@msg = @teams[@winner]['displayname'].' won! '.color('bold').@score;
			}
			broadcast(@msg, @hockey['players']);
			foreach(@p in @hockey['players']) {
				_equip_kit(@p);
			}
			remove_scoreboard('hockey');
			_remove_activity('hockey');
			entity_remove(@hockey['puck']);
		}

		_queue_game(@players);
	}
));
