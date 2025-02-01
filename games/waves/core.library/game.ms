proc _waves_prepare(@name, @arena, @region, @world) {
	@waves = array(
		name: @name,
		wave: 0,
		players: array(),
		spectators: array(),
		title: '',
		subtitle: '',
		bossbar: '',
		music: '',
		mobs: array(),
		mobCount: 1,
		spawns: array(),
		world: @world,
		arena: @arena,
		region: @region,
		config: yml_decode(read('../scripts/'.@name.'.yml')),
		trigger: null,
		binds: array(),
		task:  null,
		allplayers: associative_array(),
	);
	if(array_index_exists(@waves['config'], 'title')) {
		_add_activity('waves'.@region, _to_upper_camel_case(@region).': '.@waves['config']['title'], @region, @world);
	} else {
		_add_activity('waves'.@region, _to_upper_camel_case(@region), @region, @world);
	}
	set_world_time(@waves['world'], 'sunset');
	set_gamerule(@waves['world'], 'DODAYLIGHTCYCLE', false);
	_remove_region_entities(@waves['region']);

	create_scoreboard('waves'.@region);
	create_objective('health', 'HEALTH', 'waves'.@region);
	set_objective_display('health', array(slot: 'BELOW_NAME'), 'waves'.@region);

	create_bar('waves'.@region, array(percent: 0.0, style: 'SEGMENTED_6', visible: false));

	if(array_index_exists(@waves['config'], 'shop')) {
		_prepare_shops(@waves);
	}

	if(array_index_exists(@waves['arena'], 'startblock')) {
		set_block(@waves['arena']['startblock']['loc'], @waves['arena']['startblock']['type']);
	}

	foreach(@p in all_players(@waves['world'])) {
		if(array_contains(sk_current_regions(@p), @waves['region'])) {
			_waves_add_player(@p, @waves);
		}
	}
	return(@waves);
}

proc _waves_start(@waves) {
	@entities = array();
	sk_region_flag(@waves['world'], @waves['region'], 'mob-spawning', 'allow');

	@waves['binds'][] = bind('player_death', null, null, @event, @waves) {
		if(array_contains(@waves['players'], player())) {
			if(array_index_exists(@waves['config'], 'coins')) {
				@waves['config']['coins'] /= 2;
			}
			_waves_remove_player(player(), @waves);
			_waves_add_spectator(player(), @waves);
			@loc = ploc();
			if(@loc['y'] < 0) {
				@loc['y'] = 0;
			}
			export(player().'spawn', @loc);
		}
	}

	@waves['binds'][] = bind('player_spawn', null, null, @event, @waves) {
		if(array_contains(@waves['spectators'], player())) {
			consume();
			@loc = import(player().'spawn');
			if(@loc) {
				modify_event('location', @loc);
				export(player().'spawn', null);
			}
		}
	}

	@waves['binds'][] = bind('player_quit', null, null, @event, @waves) {
		if(array_contains(@waves['players'], player())) {
			set_ploc(@waves['arena']['lobby']);
			_waves_remove_player(player(), @waves);
		} else if(array_contains(@waves['spectators'], player())) {
			_waves_remove_spectator(player(), @waves);
		}
	}

	@waves['binds'][] = bind('player_teleport', null, null, @event, @waves) {
		if((@event['type'] === 'PLUGIN' || @event['type'] === 'SPECTATE')
		&& (@waves['world'] === @event['to']['world'] || @waves['world'] === @event['from']['world'])) {
			@from = sk_region_contains(@waves['region'], @event['from']);
			@to = sk_region_contains(@waves['region'], @event['to']);
			if(@from && !@to) {
				if(array_contains(@waves['spectators'], player())) {
					cancel();
					_waves_remove_spectator(player(), @waves);
				} else if(array_contains(@waves['players'], player())) {
					_waves_remove_player(player(), @waves);
				}
			} else if(@to) {
				if(@waves['wave'] < 2) {
					set_timeout(50, closure() {
						if(pworld() === @waves['world']) {
							if(!_waves_add_player(player(), @waves)) {
								_waves_add_spectator(player(), @waves);
							}
						}
					});
				} else {
					_waves_add_spectator(player(), @waves);
				}
			}
		}
	}

	@waves['binds'][] = bind('creature_spawn', null, null, @event, @waves, @entities) {
		if(@event['type'] != 'ARMOR_STAND' && sk_region_contains(@waves['world'], @waves['region'], @event['location'])) {
			@entities[] = @event['id'];
			@waves['mobCount']++;
		}
	}

	@waves['binds'][] = bind('entity_damage', null, null, @event, @entities, @waves) {
		if(array_contains(@entities, @event['id'])) {
			if(array_index_exists(@event, 'damager') && array_contains(@entities, @event['damager'])
			&& (array_index_exists(@waves['config'], 'teamDamage') && !@waves['config']['teamDamage'])) {
				modify_event('amount', 0.0);
			} else {
				set_timeout(0, closure(){
					@health = 0.0;
					foreach(@i: @e in @entities) {
						try {
							@health += get_entity_health(@e);
						} catch (BadEntityException @ex) {
							array_remove(@entities, @i);
						}
					}
					@health /= @waves['mobCount'];
					@health /= 100;
					try(update_bar('waves'.@waves['region'], double(@health)))
				});
			}
		}
	}

	@waves['binds'][] = bind('entity_death', null, null, @event, @entities) {
		array_remove_values(@entities, @event['id']);
	}

	@waves['binds'][] = bind('player_interact_entity', null, array(clicked: 'WOLF'), @event, @entities) {
		if(get_mob_owner(@event['id'])) {
			array_remove_values(@entities, @event['id']);
		}
	}

	if(array_index_exists(@waves['config'], 'mobs')) {
		foreach(@mob in @waves['config']['mobs']) {
			include('../mobs.library/'.to_lower(@mob).'.ms');
			_load_mob(@waves);
		}
	}

	@waves['binds'][] = bind('player_interact_at_entity', array(priority: 'HIGHEST'), array(clicked: 'ARMOR_STAND'), @event, @waves) {
		if(sk_region_contains(@waves['world'], @waves['region'], entity_loc(@event['id']))) {
			if(entity_spec(@event['id'])['visible']) {
				cancel();
				@equipment = get_mob_equipment(@event['id']);
				@loc = location_shift(entity_loc(@event['id']), 'up');
				entity_remove(@event['id']);
				foreach(@item in @equipment) {
					drop_item(@loc, @item);
				}
			}
		}
	}

	@waves['binds'][] = bind('player_interact', null, array(button: 'right', itemname: 'NETHER_STAR'), @event, @waves) {
		if(sk_region_contains(@waves['world'], @waves['region'], ploc())) {
			foreach(@p in players_in_radius(ploc(), 16)) {
				if(pmode(@p) == 'SPECTATOR') {
					set_ploc(@p, ploc());
					if(_waves_add_player(@p, @waves)) {
						set_pmode(@p, 'ADVENTURE');
						ptake_item(array(name: 'NETHER_STAR'));
						die();
					}
				}
			}
			msg('Ghost player must be within 16 meters to resurrect!');
		}
	}

	if(array_index_exists(@waves['config'], 'shop')) {
		_bind_shop_events(@waves);
	}

	@sleep = mutable_primitive(3);
	@countdown = mutable_primitive(3);
	@waves['task'] = set_interval(1000, closure(){
		try {
			// Check if players are still in play
			foreach(@p in @waves['players']) {
				if(!array_contains(sk_current_regions(@p), @waves['region'])) {
					_waves_remove_player(@p, @waves);
				}
			}
			if(!@waves['players']) {
				_waves_end(@waves, false);
				die();
			}
			foreach(@p in @waves['spectators']) {
				if(!array_contains(sk_current_regions(@p), @waves['region'])) {
					_waves_remove_spectator(@p, @waves);
				}
			}

			@viewers = null;
			if(@countdown > 0) {
				if(array_index_exists(@waves['config'], 'shop') && (@viewers = get_inventory_viewers('waves'.@waves['region']))) {
					foreach(@viewer in @viewers) {
						update_bar('waves'.@waves['region'].@viewer, array(visible: true, title: @viewer.' viewing shop ('.plevel(@viewer).' levels)'));
					}
					die();
				}
				foreach(@p in @waves['players']) {
					update_bar('waves'.@waves['region'].@p, array(visible: false));
				}
				@countdown--;
				update_bar('waves'.@waves['region'], array(color: 'WHITE', title: @waves['bossbar'], percent: (6 - @countdown[0]) / 6));
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
				foreach(@e in @entities) {
					try {
						@vehicle = get_entity_vehicle(@e);
						if(!@vehicle || is_entity_living(@vehicle)) {
							set_entity_ai(@e, true);
						}
						set_mob_effect(@e, 'glowing', 0, 0);
						set_entity_invulnerable(@e, false);
						try(set_mob_target(@e, puuid(array_get_rand(@waves['players']))));
					} catch(BadEntityException @ex){
						console('Mob dead on round start.');
					}
				}
				update_bar('waves'.@waves['region'], array(
					percent: 1.0,
					visible: true,
					title: @waves['bossbar'],
					color: 'RED',
					style: 'SOLID',
				));
				foreach(@p in @waves['players']) {
					play_sound(ploc(@p), array(sound: 'ENTITY_EVOKER_PREPARE_SUMMON', volume: 0.4), @p);
				}
			}
			if(@sleep > 0) {
				@sleep--;
			} else if(@waves['trigger']) {
				set_block(@waves['trigger'], 'AIR');
				@waves['trigger'] = null;

			} else if(@waves['mobs'] && !@waves['spawns']) {
				@spawnGroups = associative_array();
				foreach(@mob in @waves['mobs']) {
					@spawnGroup = 'spawns';
					if(is_array(@mob) && array_index_exists(@mob, 'pos')) {
						@spawnGroup = @mob['pos'];
					}
					if(!array_index_exists(@spawnGroups, @spawnGroup)) {
						@spawnGroups[@spawnGroup] = 0;
					}
					if(is_array(@mob) && array_index_exists(@mob, 'count')) {
						@spawnGroups[@spawnGroup] += @mob['count'];
					} else {
						@spawnGroups[@spawnGroup]++;
					}
				}
				@spawns = associative_array();
				foreach(@spawnGroup: @count in @spawnGroups) {
					@spawns[@spawnGroup] = array_rand(@waves['arena'][@spawnGroup], min(@waves['duplicate'] * @count, array_size(@waves['arena'][@spawnGroup])), false);
				}
				foreach(@spawnGroup in @spawns) {
					foreach(@spawn in @spawnGroup) {
						spawn_entity('AREA_EFFECT_CLOUD', 1, @spawn, closure(@cloud) {
							set_entity_spec(@cloud, array(radius: 0.1, particle: 'LAVA', duration: (@countdown - 1) * 20));
						});
					}
				}
				@waves['spawns'] = @spawns;
			} else if(@waves['mobs']) {
				@waves['mobCount'] = 0;
				@spawns = @waves['spawns'];
				do {
					foreach(@i: @mob in @waves['mobs']) {
						if(is_array(@mob)) {
							@spawnGroup = 'spawns';
							if(array_index_exists(@mob, 'pos')) {
								@spawnGroup = @mob['pos'];
							}
							@count = 1;
							if(array_index_exists(@mob, 'count')) {
								@count = @mob['count'];
							}
							do {
								@loc = @spawns[@spawnGroup][(@waves['duplicate'] * (@i + 1) * @count) % array_size(@spawns[@spawnGroup])];
								if(array_index_exists(@mob, 'custom')) {
									include('../../../entities/custom.library/'.@mob['custom'].'.ms');
									@temp = call_proc('_'.@mob['custom'].'_spawn', @loc, array(pauseTicks: 60));
									if(entity_type(@temp) === 'ARMOR_STAND') {
										set_entity_invulnerable(@temp, true);
										@entities[] = @temp;
										@waves['mobCount']++;
									}
								} else {
									_spawn_entity(@mob, @loc, null, closure(@e) {
										set_entity_saves_on_unload(@e, false);
										set_entity_ai(@e, false);
										set_mob_effect(@e, 'glowing', 0, 999, true, false);
										set_entity_invulnerable(@e, true);
									});
								}
							} while(--@count > 0)
						} else {
							@loc = @spawns['spawns'][(@waves['duplicate'] * (@i + 1)) % array_size(@spawns['spawns'])];
							spawn_entity(@mob, 1, @loc, closure(@e) {
								set_entity_saves_on_unload(@e, false);
								set_entity_ai(@e, false);
								set_mob_effect(@e, 'glowing', 0, 999, true, false);
								set_entity_invulnerable(@e, true);
							});
						}
					}
				} while(--@waves['duplicate'])
				@waves['mobs'] = array();

			} else if(array_index_exists(@waves['config'], 'maxWaves') && @waves['wave'] == @waves['config']['maxWaves']) {
				_waves_end(@waves, true);
			} else if(!@entities) {
				@waves['wave']++;
				@waveNum = @waves['wave'];
				@p = null;
				foreach(@p in @waves['players']) {
					if(@waveNum > 1 && array_index_exists(@waves['config'], 'shop')) {
						set_plevel(@p, plevel(@p) + 1);
						action_msg(@p, colorize('&e+1 level'));
					}
					play_sound(ploc(@p), array(sound: 'BLOCK_ENCHANTMENT_TABLE_USE', pitch: 0.5), @p);
					@waves['allplayers'][@p]['wave'] = @waveNum;
				}
				try {
					@wave = if(@waves['name'] == 'random', _get_random_wave(null, @waveNum), @waves['config']['waves'][@waveNum]);
					if(array_index_exists(@wave, 'title')) {
						@waves['title'] = @wave['title'];
					}
					if(array_index_exists(@wave, 'music')) {
						if(@waves['music']) {
							foreach(@p in @waves['players']) {
								stop_named_sound(@p, @waves['music'], 'RECORDS');
							}
						}
						@waves['music'] = @wave['music'];
						play_named_sound(ploc(@p), array(sound: @waves['music'], volume: 3, category: 'RECORDS'));
					}
					if(array_index_exists(@wave, 'items')) {
						foreach(@p in @waves['players']) {
							foreach(@item in @wave['items']) {
								drop_item(@p, @item);
							}
						}
					}
					if(array_index_exists(@wave, 'effects')) {
						foreach(@p in @waves['players']) {
							foreach(@effect in @wave['effects']) {
								set_peffect(@p, @effect['id'], @effect['strength'], @effect['seconds'],
									array_get(@effect, 'ambient', true),
									array_get(@effect, 'particles', true),
									array_get(@effect, 'icon', true));
							}
						}
					}
					if(array_index_exists(@wave, 'subtitle')) {
						@waves['subtitle'] = @wave['subtitle'];
					}
					if(array_index_exists(@wave, 'duplicate')) {
						@waves['duplicate'] = @wave['duplicate'];
					} else if(@waves['name'] == 'random') {
						@waves['duplicate'] = array_size(@waves['players']);
					} else {
						@waves['duplicate'] = 1;
					}
					if(array_index_exists(@wave, 'trigger')
					&& array_index_exists(@waves['arena']['triggers'], @wave['trigger'])) {
						@triggerId = @wave['trigger'];
						@trigger = @waves['arena']['triggers'][@triggerId];
						set_block(@trigger, 'REDSTONE_BLOCK');
						@waves['trigger'] = @trigger;
					}
					if(array_index_exists(@wave, 'bossbar')) {
						@waves['bossbar'] = @wave['bossbar'];
					} else {
						@waves['bossbar'] = '';
					}

					@waves['mobs'] = @wave['mobs'];
					@waves['spawns'] = null;

					@countdown[] = 6;
					@sleep[] = 1;
					update_bar('waves'.@waves['region'], 0.0);
					update_bar('waves'.@waves['region'], array(
						visible: true,
						title: @waves['bossbar'],
						style: 'SEGMENTED_6',
					));
				} catch(IndexOverflowException @ex) {
					_waves_end(@waves, true);
				}
			} else {
				// Check random entity if it is still in region
				@r = array_rand(@entities)[0];
				if(!entity_exists(@entities[@r]) || !sk_region_contains(@waves['region'], entity_loc(@entities[@r]))) {
					array_remove(@entities, @r);
				} else {
					if(entity_type(@entities[@r]) !== 'ARMOR_STAND' && is_entity_living(@entities[@r])) {
						@target = get_mob_target(@entities[@r]);
						if(!@target) {
							set_mob_target(@entities[@r], puuid(array_get_rand(@waves['players'])));
						}
					}
				}
			}
		} catch(Exception @ex) {
			console(@ex);
			_waves_end(@waves, false);
		}
	});
}

proc _waves_end(@waves, @win) {
	if(@waves['task']) {
		clear_task(@waves['task']);
	}
	if(has_inventory('waves'.@waves['region'])) {
		delete_virtual_inventory('waves'.@waves['region']);
	}
	sk_region_flag(@waves['world'], @waves['region'], 'mob-spawning', 'deny');
	set_world_time(@waves['world'], 'noon');
	_remove_region_entities(@waves['region']);
	foreach(@bind in @waves['binds']) {
		unbind(@bind);
	}

	if(array_index_exists(@waves['config'], 'mobs')) {
		foreach(@mob in @waves['config']['mobs']) {
			include('../mobs.library/'.to_lower(@mob).'.ms');
			_unload_mob(@waves);
		}
	}
	if(!_remove_activity('waves'.@waves['region'])){
		die(); // just in case this fires twice
	}
	remove_scoreboard('waves'.@waves['region']);
	remove_bar('waves'.@waves['region']);
	if(array_index_exists(@waves['arena'], 'startblock')) {
		set_block(@waves['arena']['startblock']['loc'], 'AIR');
	}
	if(array_index_exists(@waves['arena'], 'schematic')) {
		skcb_load(@waves['arena']['schematic']);
		skcb_paste(array(0, 0, 0, @waves['world']), array(origin: true, entities: true));
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
	foreach(@p in @waves['spectators']) {
		if(@win) {
			title(@p, color('green').'Success!', '');
		}
		stop_named_sound(@p, @waves['music'], 'RECORDS');
		_waves_remove_spectator(@p, @waves);
	}
	foreach(@p: @data in @waves['allplayers']) {
		@record = get_value('waves', @waves['region'], @waves['name'], puuid(@p, true));
		if(!@record) {
			@record = 0;
		}
		@waveNum = @data['wave'];
		if(@waveNum > @record) {
			store_value('waves', @waves['region'], @waves['name'], puuid(@p, true), @waveNum);
			tmsg(@p, colorize("Made it to &aWave @waveNum&f to beat your previous best of &eWave @record&f."));
			@reward = @waveNum - @record;
			tmsg(@p, color('gold').'+ '.@reward.' Coins'.color('white').' for new personal best');
			_acc_add(@p, @reward);
			if(function_exists('discord_broadcast')) {
				discord_broadcast('minecraft_chat', array(embed: array(title: 
					@p.' made it to Wave '.@waveNum.' in '._to_upper_camel_case(@waves['region']))));
			}
		}
	}
}
