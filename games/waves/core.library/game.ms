include('player.ms');
include_dir('../mobs.library');

proc _waves_prepare(@name, @arena, @region, @world) {
	@waves = array(
		name: @name,
		wave: 0,
		players: array(),
		spectators: array(),
		title: '',
		subtitle: '',
		music: '',
		mobs: array(),
		mobCount: 1,
		spawns: array(),
		world: @world,
		arena: @arena,
		region: @region,
		config: yml_decode(read('../scripts/'.@name.'.yml')),
		trigger: null,
		coins: 20,
		boss: false,
		teamDamage: true,
	);
	if(array_index_exists(@waves['config'], 'coins')) {
		@waves['coins'] = @waves['config']['coins'];
	}
	_add_activity('waves'.@region, _to_upper_camel_case(@region).': '.@waves['config']['title'], @region, @world);
	set_world_time(@waves['world'], 'sunset');
	set_gamerule(@waves['world'], 'DODAYLIGHTCYCLE', false);
	_remove_region_entities(@waves['region']);

	create_scoreboard('waves'.@region);
	create_objective('health', 'HEALTH', 'waves'.@region);
	set_objective_display('health', array(slot: 'BELOW_NAME'), 'waves'.@region);

	create_bar('waves'.@region, array(percent: 0.0, style: 'SEGMENTED_6', visible: false));

	if(array_index_exists(@waves['config'], 'shop')) {
		@shop = associative_array();
		@items = associative_array();
		foreach(@index: @item in @waves['config']['shop']) {
			@name = @item['name'];
			@meta = associative_array();
			if(array_index_exists(@item, 'meta')) {
				@meta = @item['meta'];
			}
			@meta['lore'] = array('Buy for '.@item['cost'].' level'.if(@item['cost'] > 1, 's'));
			@shop[@index] = array(name: @name, qty: @item['cost'], meta: @meta);
			@items[@name] = @item['cost'];
		}
		@waves['shop'] = @items;
		create_virtual_inventory('waves'.@region, 54, 'BUY OR SELL', @shop);
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

	bind('player_death', array(id: 'death'.@waves['region']), null, @event, @waves) {
		if(array_contains(@waves['players'], player())) {
			@waves['coins'] /= 2;
			_waves_remove_player(player(), @waves);
			_waves_add_spectator(player(), @waves);
			@loc = ploc();
			if(@loc['y'] < 0) {
				@loc['y'] = 0;
			}
			export(player().'spawn', @loc);
		}
	}

	bind('player_spawn', array(id: 'spawn'.@waves['region']), null, @event, @waves) {
		if(array_contains(@waves['spectators'], player())) {
			consume();
			@loc = import(player().'spawn');
			if(@loc) {
				modify_event('location', @loc);
				export(player().'spawn', null);
			}
		}
	}

	bind('player_quit', array(id: 'quit'.@waves['region']), null, @event, @waves) {
		if(array_contains(@waves['players'], player())) {
			set_ploc(@waves['arena']['lobby']);
			_waves_remove_player(player(), @waves);
		} else if(array_contains(@waves['spectators'], player())) {
			_waves_remove_spectator(player(), @waves);
		}
	}

	bind('player_teleport', array(id: 'teleport'.@waves['region']), null, @event, @waves) {
		if(@event['type'] == 'PLUGIN' || @event['type'] == 'SPECTATE') {
			@from = array_contains(sk_regions_at(@event['from']), @waves['region']);
			@to = array_contains(sk_regions_at(@event['to']), @waves['region']);
			if(@from && !@to) {
				if(array_contains(@waves['spectators'], player())) {
					cancel();
					_waves_remove_spectator(player(), @waves);
				} else if(array_contains(@waves['players'], player())) {
					_waves_remove_player(player(), @waves);
				}
			} else if(@to && !@from) {
				if(@waves['wave'] < 2) {
					set_timeout(50, closure() {
						if(pworld() == @waves['world']) {
							_waves_add_player(player(), @waves);
						}
					});
				} else {
					_waves_add_spectator(player(), @waves);
				}
			}
		}
	}

	bind('creature_spawn', array(id: 'mobspawn'.@waves['region']), null, @event, @waves, @entities) {
		if(@event['type'] != 'ARMOR_STAND' && @event['location']['world'] == @waves['world'] && array_contains(sk_regions_at(@event['location']), @waves['region'])) {
			@entities[] = @event['id'];
			@waves['mobCount']++;
		}
	}

	bind('entity_damage', array(id: 'mobdamage'.@waves['region']), null, @event, @entities, @waves) {
		if(array_contains(@entities, @event['id'])) {
			if(!@waves['teamDamage'] && array_index_exists(@event, 'damager') && array_contains(@entities, @event['damager'])) {
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

	bind('entity_death', array(id: 'mobdeath'.@waves['region']), null, @event, @entities) {
		array_remove_values(@entities, @event['id']);
	}

	bind('player_interact_entity', array(id: 'interact'.@waves['region']), array(clicked: 'WOLF'), @event, @entities) {
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

	bind('player_interact_at_entity', array(id: 'interactstand'.@waves['region'], priority: 'HIGHEST'),
			array(clicked: 'ARMOR_STAND'), @event, @region = @waves['region']) {

		if(array_contains(sk_regions_at(entity_loc(@event['id'])), @region)) {
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

	if(array_index_exists(@waves['config'], 'shop')) {
		bind('player_interact', array(id: 'openshop'.@waves['region']), array(button: 'right', itemname: 'EMERALD'), @event, @waves) {
			if(array_contains(@waves['players'], player()) && pworld() == @waves['world']) {
				popen_inventory('waves'.@waves['region']);
			}
		}

		bind('player_interact', array(id: 'resurrect'.@waves['region']), array(button: 'right', itemname: 'NETHER_STAR'), @event, @waves) {
			foreach(@p in players_in_radius(ploc(), 16)) {
				if(pmode(@p) == 'SPECTATOR') {
					set_pmode(@p, 'ADVENTURE');
					_waves_add_player(@p, @waves);
					set_ploc(@p, ploc());
					ptake_item(array(name: 'NETHER_STAR'));
					die();
				}
			}
			msg('Ghost player must be within 16 meters to resurrect!')
		}

		bind('item_pickup', array(id: 'pickup'.@waves['region']), null, @event, @waves) {
			if(array_contains(@waves['players'], player())) {
				@item = @event['item'];
				if(!@item['meta'] || !@item['meta']['lore']) {
					@name = @item['name'];
					if(!@item['meta']) {
						@item['meta'] = associative_array();
					}
					@refund = null;
					if(array_index_exists(@waves['shop'], @name)) {
						@refund = @waves['shop'][@name] / 2;
					} else {
						@refund = round(1 / min(16, material_info(@name)['maxStacksize']), 2);
					}
					@item['meta']['lore'] = array('Sell each for '.@refund.' levels');
					modify_event('item', @item);
				}
			}
		}

		bind('inventory_click', array(id: 'shop'.@waves['region']), array(action: 'PICKUP_ALL', virtual: true), @event, @waves) {
			if(pinventory_holder() == 'waves'.@waves['region']) {
				@item = @event['slotitem'];
				if(@item && @item['meta'] && @item['meta']['lore']) {
					@parts = parse_args(@item['meta']['lore'][0]);
					if(array_size(@parts) > 2 && @parts[0] == 'Buy' && is_integral(@parts[2])) {
						@cost = integer(@parts[2]);
						if(plevel() >= @cost) {
							@name = @item['name'];
							@meta = @item['meta'];
							@meta['lore'] = array('Sell each for '.@waves['shop'][@name] / 2.' levels');
							@item['qty'] = 1;
							pgive_item(@item);
							set_plevel(plevel() - @cost);
							play_sound(ploc(), array(sound: 'BLOCK_ANVIL_LAND', pitch: 2, volume: 0.5), player());
						}
						die();
					}
				}
				if(@item) {
					@refund = 0.5
					@name = @item['name'];
					if(array_index_exists(@waves['shop'], @name)) {
						@refund = @waves['shop'][@name] / 2;
					} else {
						@refund /= min(16, material_info(@name)['maxStacksize']);
					}
					@totalRefund = @item['qty'] * @refund;
					@xp = (pexp() / 100) + @totalRefund;
					@levels = floor(@xp);
					if(@levels) {
						set_plevel(plevel() + @levels);
					}
					@xp -= @levels;
					set_pexp(integer(@xp * 100));
					set_pinv(player(), @event['slot'], null);
					play_sound(ploc(), array(sound: 'ENTITY_PLAYER_LEVELUP', pitch: 2, volume: 0.5), player());
				}
			}
		}
	}

	@sleep = mutable_primitive(3);
	@waves['task'] = set_interval(1000, closure(){
		try {
			// Check if players are still in play
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
			if(!@entities && array_index_exists(@waves['config'], 'shop') && (@viewers = get_inventory_viewers('waves'.@waves['region']))) {
				update_bar('waves'.@waves['region'], array(color: 'YELLOW', title: array_implode(@viewers, ', ').' viewing shop'));

			} else if(@sleep > 0) {
				@sleep--;
				if(!@entities) {
					update_bar('waves'.@waves['region'], array(color: 'WHITE', title: '', percent: (6 - @sleep[0]) / 6));
				}

				if(@sleep == 5) {
					if(@waves['title']) {
						foreach(@p in @waves['players']) {
							if(ponline(@p)) {
								title(@p, @waves['title'], null, 10, 70, 20);
							}
						}
						if(!@waves['subtitle']) {
							@waves['title'] = '';
						}
					} else if(@waves['subtitle']) {
						foreach(@p in @waves['players']) {
							if(ponline(@p)) {
								title(@p, '', @waves['subtitle'], 10, 70, 20);
							}
						}
					}
				} else if(@sleep == 3 && @waves['title'] && @waves['subtitle']) {
					foreach(@i: @p in @waves['players']) {
						if(ponline(@p)) {
							title(@p, @waves['title'], @waves['subtitle'], 0, 40, 20);
						}
					}
					@waves['title'] = '';
					@waves['subtitle'] = '';
				}

			} else if(@waves['trigger']) {
				set_block(@waves['trigger'], 'AIR');
				@waves['trigger'] = null;

			} else if(@waves['mobs'] && !@waves['spawns']) {
				update_bar('waves'.@waves['region'], array(visible: false));
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
							set_entity_spec(@cloud, array(radius: 0.1, particle: 'LAVA', duration: 20));
						});
					}
				}
				@waves['spawns'] = @spawns;
				@sleep[] = 1;
			} else if(@waves['mobs']) {
				update_bar('waves'.@waves['region'], array(
					percent: 1.0,
					visible: true,
					title: if(@waves['boss'], color('red').color('bold').'BOSS', ''),
					color: 'RED',
					style: 'SOLID',
				));
				foreach(@p in @waves['players']) {
					if(ponline(@p)) {
						play_sound(ploc(@p), array(sound: 'ENTITY_EVOKER_PREPARE_SUMMON', volume: 0.4), @p);
					}
				}
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
								_spawn_entity(@mob, @loc, array(ignore: @waves['spectators']));
							} while(--@count > 0);
						} else {
							@loc = @spawns['spawns'][(@waves['duplicate'] * (@i + 1)) % array_size(@spawns['spawns'])];
							spawn_entity(@mob, 1, @loc);
						}
					}
				} while(--@waves['duplicate']);
				@waves['mobs'] = array();
				@sleep[] = 5;

			} else if(!@entities) {
				@p = null;
				foreach(@p in @waves['players']) {
					if(ponline(@p)) {
						play_sound(ploc(@p), array(sound: 'BLOCK_ENCHANTMENT_TABLE_USE', pitch: 0.5), @p);
					}
				}
				@waves['wave']++;
				@waveNum = @waves['wave'];
				try {
					@wave = @waves['config']['waves'][@waveNum];
					if(array_index_exists(@wave, 'title')) {
						@waves['title'] = @wave['title'];
					}
					if(array_index_exists(@wave, 'music')) {
						if(@waves['music']) {
							foreach(@p in @waves['players']) {
								if(ponline(@p)) {
									stop_named_sound(@p, @waves['music'], 'RECORDS');
								}
							}
						}
						@waves['music'] = @wave['music'];
						play_named_sound(ploc(@p), array(sound: @waves['music'], volume: 3, category: 'RECORDS'));
					}
					if(array_index_exists(@wave, 'items')) {
						foreach(@p in @waves['players']) {
							if(ponline(@p)) {
								foreach(@item in @wave['items']) {
									drop_item(@p, @item);
								}
							}
						}
					}
					if(array_index_exists(@wave, 'subtitle')) {
						@waves['subtitle'] = @wave['subtitle'];
					}
					if(array_index_exists(@wave, 'duplicate')) {
						@waves['duplicate'] = @wave['duplicate'];
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
					if(array_index_exists(@wave, 'boss')) {
						@waves['boss'] = true;
					} else {
						@waves['boss'] = false;
					}

					@waves['mobs'] = @wave['mobs'];
					@waves['spawns'] = null;

					@sleep[] = 6;
					update_bar('waves'.@waves['region'], 0.0);
					update_bar('waves'.@waves['region'], array(
						visible: true,
						title: '',
						style: 'SEGMENTED_6',
					));
				} catch(IndexOverflowException @ex) {
					_waves_end(@waves, true);
				}
			} else {
				// Check random entity if it's still in region
				@r = array_rand(@entities)[0];
				if(!entity_exists(@entities[@r]) || !array_contains(sk_regions_at(entity_loc(@entities[@r])), @waves['region'])) {
					array_remove(@entities, @r);
				}
			}
		} catch(Exception @ex) {
			console(@ex);
			_waves_end(@waves, false);
		}
	});
}

proc _waves_end(@waves, @win) {
	clear_task(@waves['task']);
	if(array_contains(get_virtual_inventories(), 'waves'.@waves['region'])) {
		delete_virtual_inventory('waves'.@waves['region']);
	}
	sk_region_flag(@waves['world'], @waves['region'], 'mob-spawning', 'deny');
	set_world_time(@waves['world'], 'noon');
	_remove_region_entities(@waves['region']);
	unbind('death'.@waves['region']);
	unbind('spawn'.@waves['region']);
	unbind('quit'.@waves['region']);
	unbind('teleport'.@waves['region']);
	unbind('mobspawn'.@waves['region']);
	unbind('mobdamage'.@waves['region']);
	unbind('mobdeath'.@waves['region']);
	unbind('interact'.@waves['region']);
	unbind('interactstand'.@waves['region']);
	unbind('resurrect'.@waves['region']);
	unbind('openshop'.@waves['region']);
	unbind('pickup'.@waves['region']);
	unbind('shop'.@waves['region']);
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
	@coins = ceil(@waves['coins']);
	foreach(@p in @waves['players']) {
		if(ponline(@p)) {
			if(@win) {
				title(@p, color('green').'Success!', color('gold').'+ '.@coins.' Coins');
				_acc_add(@p, @coins);
			}
			stop_named_sound(@p, @waves['music'], 'RECORDS');
			_waves_remove_player(@p, @waves);
		}
	}
	foreach(@p in @waves['spectators']) {
		if(ponline(@p)) {
			if(@win) {
				title(@p, color('green').'Success!', '');
			}
			stop_named_sound(@p, @waves['music'], 'RECORDS');
			_waves_remove_spectator(@p, @waves);
		}
	}
}
