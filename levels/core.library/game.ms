include('player.ms');

proc _level_prepare(@name, @arena, @region, @world) {
	@level = array(
		'name': @name,
		'wave': 0,
		'players': array(),
		'spectators': array(),
		'title': '',
		'subtitle': '',
		'music': '',
		'mobs': array(),
		'mobCount': 1,
		'spawns': array(),
		'world': @world,
		'arena': @arena,
		'region': @region,
		'config': yml_decode(read('../scripts/'.@name.'.yml')),
		'trigger': null,
		'coins': 20,
		'boss': false,
		'teamDamage': true,
	);
	if(array_index_exists(@level['config'], 'coins')) {
		@level['coins'] = @level['config']['coins'];
	}
	_add_activity('level'.@region, to_upper(@region).': '.@level['config']['title']);
	set_world_time(@level['world'], 'sunset');
	set_gamerule(@level['world'], 'DODAYLIGHTCYCLE', false);
	_remove_region_entities(@level['region']);

	create_scoreboard('level'.@region);
	create_objective('health', 'HEALTH', 'level'.@region);
	set_objective_display('health', array('slot': 'BELOW_NAME'), 'level'.@region);

	create_bar('level'.@region, array('percent': 0.0, 'style': 'SEGMENTED_6', 'visible': false));

	if(array_index_exists(@level['config'], 'shop')) {
		@shop = associative_array();
		@items = associative_array();
		foreach(@index: @item in @level['config']['shop']) {
			@meta = associative_array();
			if(array_index_exists(@item, 'meta')) {
				@meta = @item['meta'];
			}
			@meta['lore'] = array('Buy for '.@item['cost'].' level'.if(@item['cost'] > 1, 's'));
			@shop[@index] = array('name': @item['name'], 'qty': @item['cost'], 'meta': @meta);
			@items[@item['name']] = @item['cost'];
		}
		@level['shop'] = @items;
		create_virtual_inventory('level'.@region, 54, 'BUY OR SELL', @shop);
	}

	if(array_index_exists(@level['arena'], 'startblock')) {
		set_block(@level['arena']['startblock']['loc'], @level['arena']['startblock']['type']);
	}

	foreach(@p in all_players(@level['world'])) {
		if(array_contains(sk_current_regions(@p), @level['region'])) {
			_level_add_player(@p, @level);
		}
	}
	return(@level);
}

proc _level_start(@level) {
	@entities = array();
	sk_region_flag(@level['world'], @level['region'], 'mob-spawning', 'allow');

	bind('player_death', array('id': 'death'.@level['region']), null, @event, @level) {
		if(array_contains(@level['players'], player())) {
			@level['coins'] /= 2;
			_level_remove_player(player(), @level);
			_level_add_spectator(player(), @level);
			@loc = ploc();
			if(@loc['y'] < 0) {
				@loc['y'] = 0;
			}
			export(player().'spawn', @loc);
		}
	}

	bind('player_spawn', array('id': 'spawn'.@level['region']), null, @event, @level) {
		if(array_contains(@level['spectators'], player())) {
			consume();
			@loc = import(player().'spawn');
			if(@loc) {
				modify_event('location', @loc);
				export(player().'spawn', null);
			}
		}
	}

	bind('player_quit', array('id': 'quit'.@level['region']), null, @event, @level) {
		if(array_contains(@level['players'], player())) {
			set_ploc(@level['arena']['lobby']);
			_level_remove_player(player(), @level);
		} else if(array_contains(@level['spectators'], player())) {
			_level_remove_spectator(player(), @level);
		}
	}

	bind('player_teleport', array('id': 'teleport'.@level['region']), null, @event, @level) {
		if(@event['type'] == 'PLUGIN' || @event['type'] == 'SPECTATE') {
			@from = array_contains(sk_regions_at(@event['from']), @level['region']);
			@to = array_contains(sk_regions_at(@event['to']), @level['region']);
			if(@from && !@to) {
				if(array_contains(@level['spectators'], player())) {
					cancel();
					_level_remove_spectator(player(), @level);
				} else if(array_contains(@level['players'], player())) {
					_level_remove_player(player(), @level);
				}
			} else if(@to && !@from) {
				if(@level['wave'] < 2) {
					set_timeout(50, closure() {
						if(pworld() == @level['world']) {
							_level_add_player(player(), @level);
						}
					});
				} else {
					_level_add_spectator(player(), @level);
				}
			}
		}
	}

	bind('creature_spawn', array('id': 'mobspawn'.@level['region']), null, @event, @level, @entities) {
		if(@event['type'] != 'ARMOR_STAND' && @event['location']['world'] == @level['world'] && array_contains(sk_regions_at(@event['location']), @level['region'])) {
			@entities[] = @event['id'];
			@level['mobCount']++;
		}
	}

	bind('entity_damage', array('id': 'mobdamage'.@level['region']), null, @event, @entities, @level) {
		if(array_contains(@entities, @event['id'])) {
			if(!@level['teamDamage'] && array_index_exists(@event, 'damager') && array_contains(@entities, @event['damager'])) {
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
					@health /= @level['mobCount'];
					@health /= 100;
					try(update_bar('level'.@level['region'], double(@health)));
				});
			}
		}
	}

	bind('entity_death', array('id': 'mobdeath'.@level['region']), null, @event, @entities) {
		array_remove_values(@entities, @event['id']);
	}

	bind('player_interact_entity', array('id': 'interact'.@level['region']), array('clicked': 'WOLF'), @event, @entities) {
		if(get_mob_owner(@event['id'])) {
			array_remove_values(@entities, @event['id']);
		}
	}

	if(array_index_exists(@level['config'], 'mobs')) {
		foreach(@mob in @level['config']['mobs']) {
			include('../mobs.library/'.to_lower(@mob).'.ms');
			_load_mob(@level);
		}
	}

	bind('player_interact_at_entity', array('id': 'interactstand'.@level['region'], 'priority': 'HIGHEST'),
			array('clicked': 'ARMOR_STAND'), @event, @region = @level['region']) {

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

	if(array_index_exists(@level['config'], 'shop')) {
		bind('player_interact', array('id': 'openshop'.@level['region']), array('button': 'right', 'itemname': 'EMERALD'), @event, @level) {
			if(array_contains(@level['players'], player()) && pworld() == @level['world']) {
				popen_inventory('level'.@level['region']);
			}
		}

		bind('player_interact', array('id': 'resurrect'.@level['region']), array('button': 'right', 'itemname': 'NETHER_STAR'), @event, @level) {
			foreach(@p in players_in_radius(ploc(), 16)) {
				if(pmode(@p) == 'SPECTATOR') {
					set_pmode(@p, 'ADVENTURE');
					_level_add_player(@p, @level);
					set_ploc(@p, ploc());
					ptake_item(array('name': 'NETHER_STAR'));
					die();
				}
			}
			msg('Ghost player must be within 16 meters to resurrect!')
		}

		bind('item_pickup', array('id': 'pickup'.@level['region']), null, @event, @level) {
			if(array_contains(@level['players'], player())) {
				@item = @event['item'];
				if(!@item['meta'] || !@item['meta']['lore']) {
					if(!@item['meta']) {
						@item['meta'] = associative_array();
					}
					if(array_index_exists(@level['shop'], @item['name'])) {
						@refund = @level['shop'][@item['name']] / 2;
					} else {
						@refund = round(1 / min(16, material_info(@item['name'])['maxStacksize']), 2);
					}
					@item['meta']['lore'] = array('Sell each for '.@refund.' levels');
					modify_event('item', @item);
				}
			}
		}

		bind('inventory_click', array('id': 'shop'.@level['region']), array('action': 'PICKUP_ALL', 'virtual': true), @event, @level) {
			if(pinventory_holder() == 'level'.@level['region']) {
				@item = @event['slotitem'];
				if(@item && @item['meta'] && @item['meta']['lore']) {
					@parts = parse_args(@item['meta']['lore'][0]);
					if(array_size(@parts) > 2 && @parts[0] == 'Buy' && is_integral(@parts[2])) {
						@cost = integer(@parts[2]);
						if(plevel() >= @cost) {
							@meta = @item['meta'];
							@meta['lore'] = array('Sell each for '.@level['shop'][@item['name']] / 2.' levels');
							@item['qty'] = 1;
							pgive_item(@item);
							set_plevel(plevel() - @cost);
							play_sound(ploc(), array('sound': 'BLOCK_ANVIL_LAND', 'pitch': 2, 'volume': 0.5), player());
						}
						die();
					}
				}
				if(@item) {
					@refund = 0.5
					if(array_index_exists(@level['shop'], @item['name'])) {
						@refund = @level['shop'][@item['name']] / 2;
					} else {
						@refund /= min(16, material_info(@item['name'])['maxStacksize']);
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
					play_sound(ploc(), array('sound': 'ENTITY_PLAYER_LEVELUP', 'pitch': 2, 'volume': 0.5), player());
				}
			}
		}
	}

	@sleep = mutable_primitive(3);
	@level['task'] = set_interval(1000, closure(){
		try {
			// Check if players are still in play
			if(!@level['players']) {
				_level_end(@level, false);
				die();
			}
			foreach(@p in @level['spectators']) {
				if(!array_contains(sk_current_regions(@p), @level['region'])) {
					_level_remove_spectator(@p, @level);
				}
			}

			if(!@entities && array_index_exists(@level['config'], 'shop') && (@viewers = get_inventory_viewers('level'.@level['region']))) {
				update_bar('level'.@level['region'], array('color': 'YELLOW', 'title': array_implode(@viewers, ', ').' viewing shop'));

			} else if(@sleep > 0) {
				@sleep--;
				if(!@entities) {
					update_bar('level'.@level['region'], array('color': 'WHITE', 'title': '', 'percent': (6 - @sleep[0]) / 6));
				}

				if(@sleep == 5) {
					if(@level['title']) {
						foreach(@p in @level['players']) {
							if(ponline(@p)) {
								title(@p, @level['title'], null, 10, 70, 20);
							}
						}
						if(!@level['subtitle']) {
							@level['title'] = '';
						}
					} else if(@level['subtitle']) {
						foreach(@p in @level['players']) {
							if(ponline(@p)) {
								title(@p, '', @level['subtitle'], 10, 70, 20);
							}
						}
					}
				} else if(@sleep == 3 && @level['title'] && @level['subtitle']) {
					foreach(@i: @p in @level['players']) {
						if(ponline(@p)) {
							title(@p, @level['title'], @level['subtitle'], 0, 40, 20);
						}
					}
					@level['title'] = '';
					@level['subtitle'] = '';
				}

			} else if(@level['trigger']) {
				set_block(@level['trigger'], 'AIR');
				@level['trigger'] = null;

			} else if(@level['mobs'] && !@level['spawns']) {
				update_bar('level'.@level['region'], array('visible': false));
				@spawnGroups = associative_array();
				foreach(@mob in @level['mobs']) {
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
					@spawns[@spawnGroup] = array_rand(@level['arena'][@spawnGroup], min(@level['duplicate'] * @count, array_size(@level['arena'][@spawnGroup])), false);
				}
				foreach(@spawnGroup in @spawns) {
					foreach(@spawn in @spawnGroup) {
						spawn_entity('AREA_EFFECT_CLOUD', 1, @spawn, closure(@cloud) {
							set_entity_spec(@cloud, array('radius': 0.1, 'particle': 'LAVA', 'duration': 20));
						});
					}
				}
				@level['spawns'] = @spawns;
				@sleep[] = 1;
			} else if(@level['mobs']) {
				update_bar('level'.@level['region'], array(
					'percent': 1.0,
					'visible': true,
					'title': if(@level['boss'], color('red').color('bold').'BOSS', ''),
					'color': 'RED',
					'style': 'SOLID',
				));
				foreach(@p in @level['players']) {
					if(ponline(@p)) {
						play_sound(ploc(@p), array('sound': 'ENTITY_EVOKER_PREPARE_SUMMON', 'volume': 0.4), @p);
					}
				}
				@level['mobCount'] = 0;
				@spawns = @level['spawns'];
				do {
					foreach(@i: @mob in @level['mobs']) {
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
								@loc = @spawns[@spawnGroup][(@level['duplicate'] * (@i + 1) * @count) % array_size(@spawns[@spawnGroup])];
								_spawn_entity(@mob, @loc, player(), @level['spectators']);
							} while(--@count > 0);
						} else {
							@loc = @spawns['spawns'][(@level['duplicate'] * (@i + 1)) % array_size(@spawns['spawns'])];
							spawn_entity(@mob, 1, @loc);
						}
					}
				} while(--@level['duplicate']);
				@level['mobs'] = array();
				@sleep[] = 5;

			} else if(!@entities) {
				foreach(@p in @level['players']) {
					if(ponline(@p)) {
						play_sound(ploc(@p), array('sound': 'BLOCK_ENCHANTMENT_TABLE_USE', 'pitch': 0.5), @p);
					}
				}
				@level['wave']++;
				try {
					@wave = @level['config']['waves'][@level['wave']];
					if(array_index_exists(@wave, 'title')) {
						@level['title'] = @wave['title'];
					}
					if(array_index_exists(@wave, 'music')) {
						if(@level['music']) {
							foreach(@p in @level['players']) {
								if(ponline(@p)) {
									stop_named_sound(@p, @level['music'], 'RECORDS');
								}
							}
						}
						@level['music'] = @wave['music'];
						play_named_sound(ploc(@p), array('sound': @level['music'], 'volume': 3, 'category': 'RECORDS'));
					}
					if(array_index_exists(@wave, 'items')) {
						foreach(@p in @level['players']) {
							if(ponline(@p)) {
								foreach(@item in @wave['items']) {
									drop_item(@p, @item);
								}
							}
						}
					}
					if(array_index_exists(@wave, 'subtitle')) {
						@level['subtitle'] = @wave['subtitle'];
					}
					if(array_index_exists(@wave, 'duplicate')) {
						@level['duplicate'] = @wave['duplicate'];
					} else {
						@level['duplicate'] = 1;
					}
					if(array_index_exists(@wave, 'trigger')
					&& array_index_exists(@level['arena']['triggers'], @wave['trigger'])) {
						@trigger = @level['arena']['triggers'][@wave['trigger']];
						set_block(@trigger, 'REDSTONE_BLOCK');
						@level['trigger'] = @trigger;
					}
					if(array_index_exists(@wave, 'boss')) {
						@level['boss'] = true;
					} else {
						@level['boss'] = false;
					}

					@level['mobs'] = @wave['mobs'];
					@level['spawns'] = null;

					@sleep[] = 6;
					update_bar('level'.@level['region'], 0.0);
					update_bar('level'.@level['region'], array(
						'visible': true,
						'title': '',
						'style': 'SEGMENTED_6',
					));
				} catch(IndexOverflowException @ex) {
					_level_end(@level, true);
				}
			} else {
				// Check random entity if it's still in region
				@r = array_rand(@entities)[0];
				if(!entity_exists(@entities[@r]) || !array_contains(sk_regions_at(entity_loc(@entities[@r])), @level['region'])) {
					array_remove(@entities, @r);
				}
			}
		} catch(Exception @ex) {
			console(@ex);
			_level_end(@level, false);
		}
	});
}

proc _level_end(@level, @win) {
	clear_task(@level['task']);
	if(array_contains(get_virtual_inventories(), 'level'.@level['region'])) {
		delete_virtual_inventory('level'.@level['region']);
	}
	sk_region_flag(@level['world'], @level['region'], 'mob-spawning', 'deny');
	set_world_time(@level['world'], 'noon');
	_remove_region_entities(@level['region']);
	unbind('death'.@level['region']);
	unbind('spawn'.@level['region']);
	unbind('quit'.@level['region']);
	unbind('teleport'.@level['region']);
	unbind('mobspawn'.@level['region']);
	unbind('mobdamage'.@level['region']);
	unbind('mobdeath'.@level['region']);
	unbind('interact'.@level['region']);
	unbind('interactstand'.@level['region']);
	unbind('resurrect'.@level['region']);
	unbind('openshop'.@level['region']);
	unbind('pickup'.@level['region']);
	unbind('shop'.@level['region']);
	if(array_index_exists(@level['config'], 'mobs')) {
		foreach(@mob in @level['config']['mobs']) {
			include('../mobs.library/'.to_lower(@mob).'.ms');
			_unload_mob(@level);
		}
	}
	if(!_remove_activity('level'.@level['region'])){
		die(); // just in case this fires twice
	}
	remove_scoreboard('level'.@level['region']);
	remove_bar('level'.@level['region']);
	if(array_index_exists(@level['arena'], 'startblock')) {
		set_block(@level['arena']['startblock']['loc'], 'AIR');
	}
	if(array_index_exists(@level['arena'], 'schematic')) {
		skcb_load(@level['arena']['schematic']);
		skcb_paste(array(0, 0, 0, @level['world']), array('origin': true, 'entities': true));
	}
	@coins = ceil(@level['coins']);
	foreach(@p in @level['players']) {
		if(ponline(@p)) {
			if(@win) {
				title(@p, color('green').'Success!', color('gold').'+ '.@coins.' Coins');
				_acc_add(@p, @coins);
			}
			stop_named_sound(@p, @level['music'], 'RECORDS');
			_level_remove_player(@p, @level);
		}
	}
	foreach(@p in @level['spectators']) {
		if(ponline(@p)) {
			if(@win) {
				title(@p, color('green').'Success!', '');
			}
			stop_named_sound(@p, @level['music'], 'RECORDS');
			_level_remove_spectator(@p, @level);
		}
	}
}
