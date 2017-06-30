include('player.ms');
proc _level_start(@level) {
	// Setup exception handler to clean-up game
	set_uncaught_exception_handler(closure(@ex){
		console(@ex['classType'].': '.@ex['message'], false);
		foreach(@trace in @ex['stackTrace']) {
			console(split('LocalPackages', @trace['file'])[-1].':'.@trace['line'].' '.@trace['id'], false);
		}
		msg(color('red').@ex['message']);
		msg(color('yellow').'Cleaning up game...');
		_level_end(@level, false);
		return(true);
	});
	
	@entities = array();
	sk_region_flag(@level['world'], @level['region'], 'mob-spawning', 'allow');
	
	bind(player_death, array('id': 'death'.@level['region']), null, @event, @level) {
		if(array_contains(@level['players'], player())) {
			_level_remove_player(player(), @level);
			_level_add_spectator(player(), @level);
			@loc = ploc();
			if(@loc['y'] < 0) {
				@loc['y'] = 0;
			}
			export(player().'spawn', @loc);
		}
	}
	
	bind(player_spawn, array('id': 'spawn'.@level['region']), null, @event, @level) {
		if(array_contains(@level['spectators'], player())) {
			consume();
			@loc = import(player().'spawn');
			if(@loc) {
				modify_event('location', @loc);
				export(player().'spawn', null);
			}
		}
	}
	
	bind(player_quit, array('id': 'quit'.@level['region']), null, @event, @level) {
		if(array_contains(@level['players'], player())) {
			set_ploc(@level['arena']['lobby']);
			_level_remove_player(player(), @level);
		} else if(array_contains(@level['spectators'], player())) {
			_level_remove_spectator(player(), @level);
		}
	}
	
	bind(player_teleport, array('id': 'teleport'.@level['region']), null, @event, @level) {
		if(@event['type'] == 'PLUGIN' || @event['type'] == 'SPECTATE') {
			@from = array_contains(sk_regions_at(@event['from']), @level['region']);
			@to = array_contains(sk_regions_at(@event['to']), @level['region']);
			if(@from && !@to) {
				if(array_contains(@level['spectators'], player())) {
					cancel();
					_level_remove_spectator(player(), @level);
				} else if(array_contains(@level['players'], player())) {
					_level_remove_player(player(), @level);
					if(!@level['players']) {
						_level_end(@level, false);
					}
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
	
	bind(creature_spawn, array('id': 'mobspawn'.@level['region']), null, @event, @world = @level['world'], @region = @level['region'], @entities) {
		if(@event['location']['world'] == @world && array_contains(sk_regions_at(@event['location']), @region)) {
			@entities[] = @event['id'];
		}
	}
	
	bind(entity_death, array('id': 'mobdeath'.@level['region']), null, @event, @entities) {
		array_remove_values(@entities, @event['id']);
	}
	
	bind(player_interact_entity, array('id': 'interact'.@level['region']), array('clicked': 'WOLF'), @event, @entities) {
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
	
	if(array_index_exists(@level['config'], 'shop')) {
		bind(player_interact, array('id': 'openshop'.@level['region']), array('button': 'right', 'item': 388), @event, @level) {
			if(array_contains(@level['players'], player()) && pworld() == @level['world']) {
				popen_virtualchest('level'.@level['region']);
			}
		}
		
		bind(player_interact, array('id': 'resurrect'.@level['region']), array('button': 'right', 'item': 399), @event, @level) {
			foreach(@p in players_in_radius(ploc(), 16)) {
				if(array_contains(@level['spectators'], @p)) {
					set_pmode(@p, 'ADVENTURE');
					_level_add_player(@p, @level);
					set_ploc(@p, ploc());
					ptake_item(399, 1);
					die();
				}
			}
			msg('Ghost player must be within 16 meters to resurrect!')
		}
		
		bind(item_pickup, array('id': 'pickup'.@level['region']), null, @event, @level) {
			if(array_contains(@level['players'], player())) {
				@item = @event['item'];
				if(!@item['meta'] || !@item['meta']['lore']) {
					if(!@item['meta']) {
						@item['meta'] = associative_array();
					}
					if(array_index_exists(@level['shop'], @item['name'])) {
						@refund = @level['shop'][@item['name']] / 2;
					} else {
						@refund = round(1 / min(16, material_info(@item['type'])['maxStacksize']), 2);
					}
					@item['meta']['lore'] = array('Sell each for '.@refund.' levels');
					modify_event('item', @item);
				}
			}
		}
		
		bind(inventory_click, array('id': 'shop'.@level['region']), array('action': 'PICKUP_ALL'), @event, @level) {
			if(pget_virtualchest() == 'level'.@level['region']) {
				@item = @event['slotitem'];
				if(@item && @item['meta'] && @item['meta']['lore']) {
					@parts = parse_args(@item['meta']['lore'][0]);
					if(array_size(@parts) > 2 && @parts[0] == 'Buy' && is_integral(@parts[2])) {
						@cost = integer(@parts[2]);
						if(plevel() >= @cost) {
							@meta = @item['meta'];
							@meta['lore'] = array('Sell each for '.@level['shop'][@item['name']] / 2.' levels');
							pgive_item(@item['type'], 1, @meta);
							set_plevel(plevel() - @cost);
							play_sound(ploc(), array('sound': 'ANVIL_LAND', 'pitch': 2, 'volume': 0.5), player());
						}
						die();
					}
				}
				if(@item) {
					@refund = 0.5
					if(array_index_exists(@level['shop'], @item['name'])) {
						@refund = @level['shop'][@item['name']] / 2;
					} else {
						@refund /= min(16, material_info(@item['type'])['maxStacksize']);
					}
					@totalRefund = @item['qty'] * @refund;
					@xp = (pexp() / 100) + @totalRefund;
					@levels = floor(@xp);
					if(@levels) {
						set_plevel(plevel() + @levels);
					}
					@xp -= @levels;
					set_pexp(integer(@xp * 100));
					@inv = associative_array();
					@inv[@event['slot']] = null;
					set_pinv(@inv);
					play_sound(ploc(), array('sound': 'LEVEL_UP', 'pitch': 2, 'volume': 0.5), player());
				}
			}
		}
	}

	@sleep = array(3);
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
			
			if(array_index_exists(@level['config'], 'shop') && pviewing_virtualchest('level'.@level['region'])) {
				die();
			
			} else if(@sleep[0] > 0) {
				@sleep[0]--;
				
			} else if(@level['title']) {
				foreach(@p in @level['players']) {
					if(ponline(@p)) {
						title_msg(@p, @level['title'], null, 20, 40, 20);
					}
				}
				@sleep[0] = 3;
				@level['title'] = '';

			} else if(@level['subtitle']) {
				foreach(@i: @p in @level['players']) {
					if(ponline(@p)) {
						title_msg(@p, '', @level['subtitle'], 20, 40, 20);
					}
				}
				@sleep[0] = 3;
				@level['subtitle'] = '';
				
			} else if(@level['mobs']) {
				foreach(@p in @level['players']) {
					if(ponline(@p)) {
						play_named_sound(ploc(@p), array('sound': 'entity.evocation_illager.prepare_summon', 'volume': 0.4), @p);
					}
				}
				foreach(@mob in @level['mobs']) {
					@locs = @level['arena']['spawns'];
					if(is_array(@mob)) {
						if(array_index_exists(@mob, 'pos')) {
							@locs = @level['arena'][@mob['pos']];
						}
						@loc = @locs[rand(array_size(@locs))];
						_spawn_mob(@mob, @loc, player(), @level['spectators']);
					} else {
						@loc = @locs[rand(array_size(@locs))];
						spawn_mob(@mob, 1, @loc);
					}
				}
				@level['mobs'] = array();
				@sleep[0] = 10;
				
			} else if(!@entities) {
				foreach(@p in @level['players']) {
					if(ponline(@p)) {
						play_sound(ploc(@p), array('sound': 'LEVEL_UP', 'pitch': 0.7), @p);
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
					@level['mobs'] = @wave['mobs'];
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
			_level_end(@level, false);
		}
	});
}

proc _level_end(@level, @win) {
	clear_task(@level['task']);
	_remove_activity('level'.@level['region']);
	if(array_contains(all_virtualchests(), 'level'.@level['region'])) {
		del_virtualchest('level'.@level['region']);
	}
	remove_scoreboard('level'.@level['region']);
	sk_region_flag(@level['world'], @level['region'], 'mob-spawning', 'deny');
	set_gamerule(@level['world'], 'doDaylightCycle', true);
	_remove_region_entities(@level['region']);
	unbind('death'.@level['region']);
	unbind('spawn'.@level['region']);
	unbind('quit'.@level['region']);
	unbind('teleport'.@level['region']);
	unbind('mobspawn'.@level['region']);
	unbind('mobdeath'.@level['region']);
	unbind('interact'.@level['region']);
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
	foreach(@p in @level['players']) {
		if(ponline(@p)) {
			if(@win) {
				title_msg(@p, 'You win!', '');
			}
			stop_named_sound(@p, @level['music'], 'RECORDS');
			_level_remove_player(@p, @level);
		}
	}
	foreach(@p in @level['spectators']) {
		if(ponline(@p)) {
			if(@win) {
				title_msg(@p, 'They win!', '');
			}
			stop_named_sound(@p, @level['music'], 'RECORDS');
			_level_remove_spectator(@p, @level);
		}
	}
	if(array_index_exists(@level['arena'], 'schematic')) {
		skcb_load(@level['arena']['schematic']);
		skcb_paste(array(0, 0, 0, @level['world']), array('origin': true));
	}
}
