register_command('7', array(
	'description': 'Starts and manages "Seven Seconds to Live" minigame.',
	'usage': '/7 [start|list|create|edit|save|delete|reset|setspawn|resetspawns] [map_id]',
	'aliases': array('seven'),
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		if(array_size(@args) == 1) {
			return(_strings_start_with_ic(array('start', 'list', 'create', 'edit', 'save', 'delete',
					'reset', 'setspawn', 'resetspawns'), @args[-1]));
		}
		return(array());
	},
	'executor': closure(@alias, @sender, @args, @info) {
		@schematic = '';
		if(array_size(@args) > 1) {
			@schematic = @args[1];
		}
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

			@7 = import('7')
			if(!@7) {
				@7 = array('players': associative_array(), 'state': 0)
				export('7', @7)
			}

			_worldmsg('custom', colorize('&6&l7 Seconds to Live&r has been queued up by '.player().' /warp 7'))

			@timer = array(7);
			@7['state'] = 1;
			@7['lobby'] = get_value('warp.7');
			_add_activity('7', '7 Seconds to Live');
			create_scoreboard('7');
			create_objective('time', 'DUMMY', '7');
			set_objective_display('time', array('displayname': color(6).'SECONDS TO LIVE', 'slot': 'SIDEBAR'), '7');
			@startblock = sk_region_info('7_schematic', 'custom')[0][0];
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
					skcb_load(@7['arena']);
					skcb_paste(array(0, 0, 0, 'custom'), array('origin': true));
					@7['state'] = 3;

				} else if(@7['state'] == 3) {
					if(get_block_at(@startblock) !== '0:0') {
						@7['state'] = 4;
						set_block_at(@startblock, 0);
						_worldmsg('custom', colorize('&6&l7 Seconds to Live&r... /warp 7'));
					}

				} else if(@7['state'] == 4) {
					@timer[0] -= 1;

					if(@num != array_size(@7['players'])) {
						if(@num < 2) {
							_worldmsg('custom', colorize('&67 Seconds to Live&r game canceled.'))
							clear_task()
							@7['state'] = 0
							@7['players'] = associative_array()
							remove_scoreboard('7')
							_remove_activity('7');
							die()
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
						include('../includes.library/main.ms');
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
					@arenas[@schematic] = array('spawns': array())
					@startblock = sk_region_info('7_schematic', 'custom')[0][0];
					set_block_at(@startblock, 169);
					sudo('/awe toggle off');
					sudo('/rg select 7_schematic')
					sudo('//copy')
					sudo('//schematic save '.@schematic)
					sudo('//sel')
					sudo('/awe toggle on');
					set_block_at(@startblock, 0);
					store_value('seven', @arenas)
					msg('Created arena '.@schematic)

				case 'edit':
				case 'load':
					if(!@schematic) {
						die(color('gold').'Please specify a schematic filename.')
					}
					@arenas = get_value('seven')
					if(!array_index_exists(@arenas, @schematic)) {
						die(color('gold').'No arena by that name.')
					}

					skcb_load(@schematic);
					skcb_paste(array(0, 0, 0, 'custom'), array('origin': true));
					msg('If done editing, you may use /7 save '.@schematic)
					msg('Then set the spawn points with /7 spawn '.@schematic)

				case 'save':
					if(!@schematic) {
						die(color('gold').'Please specify a schematic filename.')
					}
					@startblock = sk_region_info('7_schematic', 'custom')[0][0];
					set_block_at(@startblock, 169);
					sudo('/awe toggle off');
					sudo('/rg select 7_schematic');
					sudo('//copy');
					sudo('//schematic save '.@schematic);
					sudo('//sel');
					sudo('/awe toggle on');
					msg('Saved arena '.@schematic)
					set_block_at(@startblock, 0);

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
					@loc = array(round(@loc[0], 1), @loc[1], round(@loc[2], 1), 'custom')
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