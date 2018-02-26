/*
	Seven Seconds to Live is a game where players are given seven seconds on a clock before they blow up.
	Players can get additional time added to their clock by running on ores -- the higher value the ores, the more
	time is added to their clock. The last player to have not blown up or fallen out of the map wins.
	The command features several subcommands to create and edit multiple arenas for players to play on.
	
	DEPENDENCIES:
	- WorldGuard plugin and SKCompat extension for regions and arena schematics.
	- _add_activity() and _remove_activity() procedures to keep a list of all current activities on server.
	- _regionmsg() proc to broadcast to players only within a region.
*/
register_command('7', array(
	'description': 'Starts and manages "Seven Seconds to Live" minigame.',
	'usage': '/7 [start|list|create|edit|save|delete|reset|setspawn|resetspawns] [map_id]',
	'permission': 'command.7',
	'aliases': array('seven'),
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		if(array_size(@args) == 1) {
			@chars = @args[-1];
			return(array_filter(array('start', 'list', 'create', 'edit', 'save', 'delete', 'reset', 'setspawn', 'resetspawns'),
				closure(@index, @string) {
					return(length(@chars) <= length(@string) && equals_ic(@chars, substr(@string, 0, length(@chars))));
				}
			));
		}
		return(array());
	},
	'executor': closure(@alias, @sender, @args, @info) {
		@schematic = '';
		if(array_size(@args) > 1) {
			@schematic = @args[1];
		}
		@world = pworld(@sender);
		if(!@args || @args[0] == 'start') {
			@arenas = get_value('seven')
			if(!@arenas || array_size(@arenas) < 1) {
				die(color('gold').'No schematics/arenas defined.')
			}

			if(@schematic && !array_contains(array_keys(@arenas), @schematic)) {
				die(color('gold').'Unknown arena. Use /7 list.');
			}

			if(array_contains(get_scoreboards(), '7')) {
				die(colorize('&67 Seconds to Live&r is in a running state already.'))
			}
			
			proc _7_start(@7) {
				@i = 0
				foreach(@player in array_keys(@7['players'])) {
					if(@i == array_size(@7['spawns'])) {
						@i = 0
					}
					set_ploc(@player, @7['spawns'][@i])
					set_pexp(@player, 99)
					set_pbed_location(@player, @7['lobby'])
					@i++
				}
			
				@countdown = array(3)
				@7['task'] = set_interval(1000, closure(){
					if(@countdown[0] > 0) {
						foreach(@player in array_keys(@7['players'])) {
							if(ponline(@player)) {
								play_sound(ploc(@player), array('sound': 'NOTE_PIANO', 'pitch': 1, 'volume': 2), @player)
								play_sound(ploc(@player), array('sound': 'NOTE_PIANO', 'pitch': 1.1, 'volume': 2), @player)
							}
						}
						@countdown[0] -= 1
					} else {
						foreach(@player in array_keys(@7['players'])) {
							if(ponline(@player)) {
								play_sound(ploc(@player), array('sound': 'NOTE_PIANO', 'pitch': 1, 'volume': 2), @player);
								play_sound(ploc(@player), array('sound': 'NOTE_PIANO', 'pitch': 1.5, 'volume': 2), @player);
								play_sound(ploc(@player), array('sound': 'NOTE_PIANO', 'pitch': 2, 'volume': 2), @player);
								set_pwalkspeed(@player, 0.2);
								set_peffect(@player, 8, 0, 0);
							}
						}
						clear_task()
			
						@7['task'] = set_interval(100, closure(){
							foreach(@player: @p in @7['players']) {
								if(!ponline(@player)
								|| !array_contains(sk_current_regions(@player), '7_schematic')
								|| phealth(@player) <= 0) {
									_7_remove_player(@player, @7);
								} else {
									@p['time'] -= 0.10;
			
									@loc = ploc(@player);
									@loc['x'] = floor(@loc['x']);
									@loc['y'] = floor(@loc['y']);
									@loc['z'] = floor(@loc['z']);
			
									if(!is_null(@p['block'])
									&& (@p['block'][0] != @loc['x']
									|| @p['block'][2] != @loc['z']
									|| @p['block'][1] != @loc['y'])) {
										@pitch = 0;
										switch(get_block_at(@p['block'])) {
											case '173:0':
												@p['time'] -= 0.20;
												title(@player, '', color('red').'\u2639');
												play_sound(@p['block'], array('sound': 'VILLAGER_NO'), @player);
											case '16:0':
												@p['time'] -= 0.10;
												title(@player, '', color('red').'\u2639');
												play_sound(@p['block'], array('sound': 'VILLAGER_NO'), @player);
											case '15:0':
												@p['time'] += 0.20;
												@pitch = 0.5;
											case '42:0':
												@p['time'] += 0.25;
												@pitch = 0.561231;
											case '21:0':
											case '73:0':
											case '74:0':
												@p['time'] += 0.30;
												@pitch = 0.629961;
											case '22:0':
											case '152:0':
												@p['time'] += 0.35;
												@pitch = 0.749154;
											case '14:0':
												@p['time'] += 0.40;
												@pitch = 0.840896;
											case '41:0':
												@p['time'] += 0.45;
												@pitch = 1.0;
											case '56:0':
												@p['time'] += 0.50;
												@pitch = 1.22462;
											case '57:0':
												@p['time'] += 0.55;
												@pitch = 1.259921;
											case '129:0':
												@p['time'] += 0.60;
												@pitch = 1.498307;
											case '133:0':
												@p['time'] += 0.65;
												@pitch = 1.681793;
										}
										set_block_at(@p['block'], '0:0', false);
										if(@pitch) {
											play_sound(@p['block'], array('sound': 'ORB_PICKUP', 'pitch': @pitch), @player);
											@note = @p['block'][];
											@note[0] += 0.5;
											@note[1] += 0.5;
											@note[2] += 0.5;
											play_effect(@note, 'NOTE');
										}
										@p['block'] = null;
									}
			
									if(is_null(@p['block']) && entity_grounded(puuid(@player))) {
										@p['block'] = array(@loc['x'], @loc['y'], @loc['z'], @7['world']);
									}
			
									@int = ceil(@p['time'])
									set_pscore('time', @player, @int, '7')
									set_pexp(@player, integer(clamp(100 * (@p['time'] / 7), 0, 99)));
									set_plevel(@player, @int)
			
									if(@p['time'] <= 0) {
										_7_remove_player(@player, @7);
									} else if(@p['time'] < 2) {
										play_sound(@loc, array('sound': 'NOTE_PIANO', 'pitch': 1.9), @player)
										play_sound(@loc, array('sound': 'NOTE_PIANO', 'pitch': 2))
									}
								}
							}
							if(array_size(@7['players']) <= 1) {
								if(array_size(@7['players']) == 1) {
									@winner = array_implode(array_keys(@7['players']));
									@time = round(@7['players'][@winner]['time'], 1);
									broadcast(@winner.' wins with '.color('gold').@time.' Seconds to Live', all_players(@7['world']));
									set_timeout(3000, closure(){
										if(ponline(@winner)) {
											set_ploc(@winner, @7['lobby']);
										}
									})
								} else {
									broadcast(color(6).'Everybody dies.', all_players(@7['world']));
								}
								set_timeout(7000, closure(){
									remove_scoreboard('7');
									_remove_activity('7');
								});
								@7['players'] = associative_array();
								@7['state'] = 0;
								clear_task();
							}
						})
					}
				})
			}
			
			proc _7_remove_player(@player, @7) {
				if(ponline(@player)) {
					if(pworld(@player) === @7['world']) {
						if(array_contains(sk_current_regions(@player), '7')) {
							if(phealth(@player) > 0) {
								pkill(@player);
								@ploc = ploc(@player);
								@ploc['y'] += 1.0;
								explosion(@ploc, 4);
							}
							@timeleft = round(@7['players'][@player]['time'], 1);
							if(@timeleft <= 0) {
								_regionmsg('7', @player.' ran out of time.');
							} else {
								_regionmsg('7', @player.' blew up with '.color('gold').@timeleft.' seconds'.color('r').' left.');
								set_pscore('time', @player, get_pscore('time', @player, '7') * -1, '7')
							}
						} else {
							_regionmsg('7', @player.' left the game.');
						}
			
					} else {
						_regionmsg('7', @player.' left the game.');
						set_pscoreboard(@player);
					}
				}
				array_remove(@7['players'], @player);
			}

			@7 = import('7')
			if(!@7) {
				@7 = array('players': associative_array(), 'state': 0);
				export('7', @7);
			}
			
			broadcast(colorize('&6&l7 Seconds to Live&r has been queued up by '.player().' /warp 7'), all_players(@world));

			@timer = array(7);
			@7['state'] = 1;
			@7['lobby'] = get_value('warp.7');
			@7['world'] = @world;
			_add_activity('7', '7 Seconds to Live');
			create_scoreboard('7');
			create_objective('time', 'DUMMY', '7');
			set_objective_display('time', array('displayname': color(6).'SECONDS TO LIVE', 'slot': 'SIDEBAR'), '7');
			@startblock = sk_region_info('7_schematic', @world)[0][0];
			set_interval(1000, closure(){
				@num = 0
				foreach(@player in all_players()) {
					if(ponline(@player) && pmode(@player) === 'ADVENTURE' && array_contains(sk_current_regions(@player), '7')) {
						@num++
						if(!array_index_exists(@7['players'], @player)) {
							@7['players'][@player] = associative_array('time': 7.0, 'block': null);
							set_pscoreboard(@player, '7')
							set_pscore('time', @player, 7, '7')
						}
					}
				}
				if(@7['state'] == 1) {
					if(@num >= 2) {
						@7['state'] = 2;
					} else if(@num == 0) {
						clear_task()
						@7['state'] = 0
						@7['players'] = associative_array()
						remove_scoreboard('7')
						_remove_activity('7');
						die()
					}

				} else if(@7['state'] == 2) {
					_regionmsg('7', colorize('&6GENERATING ARENA...'));
					if(!@schematic) {
						@7['arena'] = array_rand(@arenas)[0];
					} else {
						@7['arena'] = @schematic;
					}
					@7['spawns'] = @arenas[@7['arena']]['spawns'];
					@skplayer = array_keys(@7['players'])[0];
					set_block_at(@startblock, 0);
					if(array_index_exists(@arenas[@7['arena']], 'author')) {
						skcb_load(@arenas[@7['arena']]['author'][0].'/'.@7['arena']);
					} else {
						skcb_load(@7['arena']);
					}
					skcb_paste(array(0, 0, 0, @world), array('origin': true));
					@7['state'] = 3;

				} else if(@7['state'] == 3) {
					if(get_block_at(@startblock) !== '0:0') {
						@7['state'] = 4;
						set_block_at(@startblock, 0);
						broadcast(colorize('&6&l7 Seconds to Live&r... /warp 7'), all_players(@world));
					}

				} else if(@7['state'] == 4) {
					@timer[0] -= 1;

					if(@num != array_size(@7['players'])) {
						if(@num < 2) {
							broadcast(colorize('&67 Seconds to Live&r game canceled.'), all_players(@world));
							clear_task();
							@7['state'] = 0;
							@7['players'] = associative_array();
							remove_scoreboard('7');
							_remove_activity('7');
							die();
						}

						foreach(@player in array_keys(@7['players'])) {
							if(!ponline(@player) || !array_contains(sk_current_regions(@player), '7')) {
								array_remove(@7['players'], @player);
								if(ponline(@player)) {
									set_pwalkspeed(@player, 0.2);
								}
							}
						}
					}

					if(@timer[0] == 1) {
						foreach(@player in array_keys(@7['players'])) {
							set_pvelocity(@player, array(0, 0, 0));
							set_pwalkspeed(@player, 0);
							set_peffect(@player, 8, -10, 10);
						}
					} else if(@timer[0] == 0) {
						clear_task();
						_7_start(@7);
					}
				}
			})

		} else {
			if(!has_permission('group.builder')) {
				die(color('gold').'No permission.');
			}
			switch(@args[0]) {
				case 'create':
				case 'define':
					if(!@schematic) {
						die(color('gold').'Please specify a schematic filename.')
					}
					@arenas = get_value('seven')
					if(!@arenas) {
						@arenas = associative_array()
					} else if(array_index_exists(@arenas, @schematic)) {
						die(color('gold').'Arena already exists by that name.')
					}
					@arenas[@schematic] = array('spawns': array(), 'author': array(puuid(), player()));
					store_value('seven', @arenas);
					@startblock = sk_region_info('7_schematic', @world)[0][0];
					set_block_at(@startblock, 169);
					sudo('/rg select 7_schematic');
					queue_push(closure(){sudo('//copy')}, '7');
					queue_push(closure(){sudo('//schematic save '.@schematic)}, '7');

				case 'edit':
				case 'load':
					if(!@schematic) {
						die(color('gold').'Please specify a schematic filename.')
					}
					@arenas = get_value('seven')
					if(!array_index_exists(@arenas, @schematic)) {
						die(color('gold').'No arena by that name.')
					}
					if(array_index_exists(@arenas[@schematic], 'author')) {
						skcb_load(@arenas[@schematic]['author'][0].'/'.@schematic);
					} else {
						skcb_load(@schematic);
					}
					skcb_paste(array(0, 0, 0, @world), array('origin': true));
					msg('If done editing, you may use /7 save '.@schematic)
					msg('Then set the spawn points with /7 spawn '.@schematic)

				case 'save':
					if(!@schematic) {
						die(color('gold').'Please specify a schematic filename.')
					}
					
					@arenas = get_value('seven');
					if(!array_index_exists(@arenas, @schematic)) {
						die(color('gold').'Arena doesn\'t exist by that name.');
					}
					if(!array_index_exists(@arenas[@schematic], 'author')) {
						@arenas[@schematic]['author'] = array(puuid(), player());
						store_value('seven', @arenas);
					} else if(@arenas[@schematic]['author'][0] != puuid()) {
						die(color('gold').'You are not the author');
					}
					
					@startblock = sk_region_info('7_schematic', @world)[0][0];
					set_block_at(@startblock, 169);
					sudo('/rg select 7_schematic');
					queue_push(closure(){sudo('//copy')}, '7');
					queue_push(closure(){sudo('//schematic save '.@schematic)}, '7');

				case 'setspawn':
				case 'spawn':
				case 'set':
					if(!@schematic) {
						die(color('gold').'Please specify an arena.')
					}
					@arenas = get_value('seven')
					if(!array_index_exists(@arenas, @schematic)) {
						die(color('gold').'Arena doesn\'t exist by that name.')
					}
					@loc = ploc()
					@loc = array(round(@loc[0], 1), @loc[1], round(@loc[2], 1), @world)
					@arenas[@schematic]['spawns'][] = @loc
					msg(color('green').'Set spawn '.array_size(@arenas[@schematic]['spawns']).' here.')
					store_value('seven', @arenas)

				case 'resetspawns':
					if(!@schematic) {
						die(color('gold').'Please specify an arena.')
					}
					@arenas = get_value('seven');
					if(!array_index_exists(@arenas, @schematic)) {
						die(color('gold').'Arena doesn\'t exist by that name.');
					}
					@arenas[@schematic] = array('spawns': array());
					store_value('seven', @arenas);
					msg(color('green').'Reset all spawns for '.@schematic);

				case 'delete':
				case 'remove':
					if(!@schematic) {
						die(color('gold').'Please specify an arena.')
					}
					@arenas = get_value('seven')
					if(array_index_exists(@arenas, @schematic)) {
						array_remove(@arenas, @schematic)
						msg(color('green').'Deleted the arena '.@schematic.'.')
					} else {
						die(color('gold').'No arena by that name.')
					}
					store_value('seven', @arenas)

				case 'list':
					@arenas = get_value('seven')
					msg(array_implode(array_keys(@arenas)))

				case 'reset':
					clear_task(@7['task']);
					export('7', null);
					remove_scoreboard('7');
					msg('Reset 7 Seconds to Live.');

				default:
					msg(color('bold').'GENERAL COMMANDS -------');
					msg('/7 [start] '.color('gray').'Queues up a game');
					msg(color('bold').'BUILDER COMMANDS -------');
					msg('/7 create <arena> '.color('gray').'Creates a new arena');
					msg('/7 edit <arena> '.color('gray').'Loads up arena for editing');
					msg('/7 save <arena> '.color('gray').'Saves edited arena');
					msg('/7 setspawn <arena> '.color('gray').'Creates a spawnpoint on arena');
					msg('/7 delete <arena> '.color('gray').'Deletes arena');
					msg('/7 list '.color('gray').'Lists all arenas');
					msg('/7 reset '.color('gray').'Resets game if it\'s stuck');

			}
		}
	}
));
