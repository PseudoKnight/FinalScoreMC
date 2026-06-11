proc _waves_create(@name, @arena, @region, @world) {
	@config = yml_decode(read('../scripts/'.@name.'.yml'));
	@waves = array(
		name: @name,
		wave: 0,
		players: array(),
		title: '',
		subtitle: '',
		bossbar: '',
		music: '',
		mobs: array(),
		mobCount: 0,
		entities: array(),
		bounty: null,
		spawns: array(),
		world: @world,
		arena: @arena,
		region: @region,
		config: @config,
		mobPool: if(@name === 'random', @config['mobPool'][], null),
		modifierPool: if(@name === 'random', @config['modifierPool'][], null),
		shopTier: 0,
		trigger: null,
		binds: array(),
		task: null,
		allplayers: associative_array(),
		originalTime: get_world_time(@world),
		originalTimeAdvance: get_gamerule(@world, 'advance_time'),
	);
	return(@waves);
}

proc _waves_start(@waves) {
	@region = @waves['region'];
	@world = @waves['world'];
	if(array_index_exists(@waves['config'], 'title')) {
		_add_activity('waves'.@region, _to_upper_camel_case(@region).': '.@waves['config']['title'], @region, @world);
	} else {
		_add_activity('waves'.@region, _to_upper_camel_case(@region), @region, @world);
	}
	if(array_index_exists(@waves['config'], 'time')) {
		set_world_time(@world, @waves['config']['time']);
		set_gamerule(@world, 'advance_time', false);
	}
	_remove_region_entities(@region);

	create_scoreboard('waves'.@region);
	create_objective('health', 'HEALTH', 'waves'.@region);
	set_objective_display('health', array(slot: 'BELOW_NAME'), 'waves'.@region);

	create_bar('waves'.@region, array(visible: false));

	if(array_index_exists(@waves['arena'], 'startblock')) {
		set_block(@waves['arena']['startblock']['loc'], @waves['arena']['startblock']['type']);
	}

	foreach(@p in all_players(@world)) {
		if(array_contains(sk_current_regions(@p), @region)) {
			_waves_add_player(@p, @waves);
		}
	}

	sk_region_flag(@world, @region, 'mob-spawning', 'allow');

	_bind_events(@waves);

	if(array_index_exists(@waves['config'], 'shop')) {
		_prepare_shops(@waves);
		_bind_shop_events(@waves);
	}

	if(array_index_exists(@waves['config'], 'mobs')) {
		foreach(@mob in @waves['config']['mobs']) {
			include('../mobs.library/'.to_lower(@mob).'.ms');
			_load_mob(@waves);
		}
	}

	@entities = @waves['entities'];
	@sleep = mutable_primitive(3);
	@countdown = mutable_primitive(3);
	@waves['task'] = set_interval(1000, closure(){
		try {
			// Check if players are still in play
			@playerCount = 0;
			foreach(@p in @waves['players']) {
				if(!sk_region_contains(@region, location_shift(ploc(@p), 'up'))) {
					set_entity_loc(puuid(@p), array_get_rand(@waves['arena']['center']));
				}
				if(pmode(@p) !== 'SPECTATOR') {
					@playerCount++;
				}
			}
			if(!@playerCount) {
				_waves_end(@waves, false);
				die();
			}

			if(@countdown > 0) {
				@holdCountdown = false;
				foreach(@p in @waves['players']) {
					if(pinventory_holder(@p) !== puuid(@p)) {
						@holdCountdown = true;
						update_bar('waves'.@region.@p, array(visible: true, title: @p.' paused countdown ('.plevel(@p).' levels)'));
					} else {
						update_bar('waves'.@region.@p, array(visible: false));
					}
				}
				if(@holdCountdown) {
					die();
				}

				@countdown--;
				if(@waves['bossbar']) {
					update_bar('waves'.@region, array(
						color: 'WHITE',
						title: @waves['bossbar'],
						percent: (6 - @countdown) / 6));
				}
				if(@countdown == 5) {
					if(@waves['title']) {
						foreach(@p in @waves['players']) {
							title(@p, @waves['title'], null, 10, 70, 20);
						}
						if(!@waves['subtitle']) {
							@waves['title'] = '';
						}
					} else if(@waves['subtitle']) {
						foreach(@p in @waves['players']) {
							title(@p, '', @waves['subtitle'], 10, 70, 20);
						}
					}
				} else if(@countdown == 3 && @waves['title'] && @waves['subtitle']) {
					foreach(@i: @p in @waves['players']) {
						title(@p, @waves['title'], @waves['subtitle'], 0, 40, 20);
					}
					@waves['title'] = '';
					@waves['subtitle'] = '';
				}
			} if(@countdown == 0) {
				@countdown--;
				if(@waves['bossbar']) {
					update_bar('waves'.@waves['region'], array(
						percent: 1.0,
						visible: true,
						title: @waves['bossbar'],
						color: if(@waves['name'] === 'random' && @waves['wave'] % 5 == 0, 'PURPLE', 'RED'),
						style: 'SOLID'));
				}
				if(array_index_exists(@waves['config'], 'sounds', 'wave_start')) {
					foreach(@p in @waves['players']) {
						play_sound(ploc(@p), @waves['config']['sounds']['wave_start'], @p);
					}
				}
				_waves_activate_mobs(@waves);
			}

			if(@sleep > 0) {
				@sleep--;

			} else if(@waves['trigger']) {
				set_block(@waves['trigger'], 'AIR');
				@waves['trigger'] = null;

			} else if(@waves['mobs'] && !@waves['spawns']) {
				_waves_prepare_spawns(@waves, @countdown);

			} else if(@waves['mobs']) {
				_waves_spawn_mobs(@waves);

			} else if(!@entities) {
				@waves['wave']++;
				if(array_index_exists(@waves['config'], 'maxWaves') && @waves['wave'] > @waves['config']['maxWaves']
						|| array_index_exists(@waves['config'], 'waves') && !array_index_exists(@waves['config']['waves'], @waves['wave'])) {
					_waves_end(@waves, true);
					die();
				}
				_waves_prepare_next(@waves);
				@countdown[] = 6;
				@sleep[] = 1;

			} else {
				_waves_tick_mobs(@waves);
			}
		} catch(Exception @ex) {
			console(@ex);
			_waves_end(@waves, false);
		}
	});
}

proc _waves_end(@waves, @win) {
	@world = @waves['world'];
	@region = @waves['region'];
	@name = @waves['name'];

	if(@waves['task']) {
		clear_task(@waves['task']);
	}
	if(has_inventory('waves'.@region)) {
		delete_virtual_inventory('waves'.@region);
	}
	sk_region_flag(@world, @region, 'mob-spawning', 'deny');
	if(array_index_exists(@waves['config'], 'time')) {
		set_world_time(@world, @waves['originalTime']);
		set_gamerule(@world, 'advance_time', @waves['originalTimeAdvance']);
	}
	_remove_region_entities(@region);
	foreach(@bind in @waves['binds']) {
		unbind(@bind);
	}

	if(array_index_exists(@waves['config'], 'mobs')) {
		foreach(@mob in @waves['config']['mobs']) {
			include('../mobs.library/'.to_lower(@mob).'.ms');
			_unload_mob(@waves);
		}
	}
	if(!_remove_activity('waves'.@region)) {
		die(); // just in case this fires twice
	}
	remove_scoreboard('waves'.@region);
	remove_bar('waves'.@region);
	if(array_index_exists(@waves['arena'], 'startblock')) {
		set_block(@waves['arena']['startblock']['loc'], 'AIR');
	}
	if(array_index_exists(@waves['arena'], 'schematic')) {
		skcb_load(@waves['arena']['schematic']);
		skcb_paste(array(0, 0, 0, @world), array(origin: true, entities: true));
	}
	@coins = 0;
	if(array_index_exists(@waves['config'], 'coins')) {
		@coins = ceil(@waves['config']['coins']);
	}
	foreach(@p in @waves['players']) {
		if(@win) {
			title(@p, color('green').'Success!', if(@coins, color('gold').'+ '.@coins.' Coins', ''));
			if(@coins) {
				_acc_add(@p, @coins);
			}
		}
		stop_named_sound(@p, @waves['music'], 'RECORDS');
		_waves_remove_player(@p, @waves);
	}

	// calculate records
	foreach(@p: @data in @waves['allplayers']) {
		if(!ponline(@p) || !sk_region_contains(@world, @region, location_shift(ploc(@p), 'up'))) {
			array_remove(@waves['allplayers'], @p);
		}
	}
	@playerCount = array_size(@waves['allplayers']);
	@playerIndex = @playerCount - 1;
	foreach(@p: @data in @waves['allplayers']) {
		@puuid = puuid(@p, true);
		@entry = get_value('waves', @region, @name, @puuid);
		if(!@entry) {
			@entry = array_resize(array(), @playerCount, 0);
		} else if(!array_index_exists(@entry, @playerIndex)) {
			array_resize(@entry, @playerCount, 0);
		}
		@record = @entry[@playerIndex];
		@waveNum = @data['wave'];
		if(@waveNum > @record) {
			// Update personal best
			@entry[@playerIndex] = @waveNum;
			store_value('waves', @region, @name, @puuid, @entry);
			if(@record) {
				try(tmsg(@p, colorize("Survived &a@waveNum waves&f to beat your previous best of &e@record&f"
						.if(@playerCount > 1, " with @playerCount players.", "."))))
			}
			@reward = @waveNum - @record;
			try(tmsg(@p, color('gold').'+ '.@reward.' Coins'.color('white').' for new personal best'))
			_acc_add(@p, @reward);
			if(function_exists('discord_broadcast')) {
				discord_broadcast('chat', array(embed: array(title: 
					@p.' survived '.@waveNum.' / '.@waves['config']['maxWaves'].' waves in '._to_upper_camel_case(@region))));
			}

			// Update top records
			@records = get_value('waves', @region, @name, 'top');
			if(!array_index_exists(@records, @playerIndex)) {
				@records[@playerIndex] = array();
			}
			@newEntry = array(uuid: @puuid, waves: @waveNum);
			@inserted = false;
			foreach(@index: @entry in @records[@playerIndex]) {
				if(@inserted) {
					if(@entry['uuid'] === @puuid) {
						array_remove(@records[@playerIndex], @index);
						break();
					}
				} else if(@waveNum > @entry['waves']) {
					@inserted = true;
					if(@entry['uuid'] === @puuid) {
						@records[@playerIndex][@index] = @newEntry;
						break();
					} else {
						array_insert(@records[@playerIndex], @newEntry, @index);
					}
				}
			}
			if(!@inserted) {
				@records[@playerIndex][] = @newEntry;
			}
			store_value('waves', @region, @name, 'top', @records);
		}
	}
}
