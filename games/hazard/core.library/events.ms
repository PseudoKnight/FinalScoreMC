proc _hazard_bind(@game) {
	@game['binds'][] = bind('player_interact', array(priority: 'HIGHEST'), array(button: 'right'), @event, @game) {
		if(array_index_exists(@game['players'], player())) {
			@item = @event['item'];
			if(!@item) {
				die();
			}
			if(@game['players'][player()]['buildCount'] == @game['buildCount']) {
				cancel();
				action_msg('Reached build limit for this round.');
				die();
			}
			if(string_ends_with(@item['name'], '_SPAWN_EGG')) {
				cancel();
				consume();
				if(pmode() === 'CREATIVE' && array_index_exists(@event, 'location')) {
					@loc = @event['location'];
					if(get_block_info(@loc)['solid']) {
						@loc = location_shift(@loc, @event['facing']);
					}
					@loc['x'] += 0.5;
					@loc['z'] += 0.5;
					@type = reg_match('(.*)_SPAWN_EGG', @item['name'])[1];
					if(@type == 'MOOSHROOM') {
						@type = 'MUSHROOM_COW';
					} else if(@type == 'SNOW_GOLEM') {
						@type = 'SNOWMAN';
					} else if(@type == 'ENDER_DRAGON') {
						die(); // potentially too destructive
					}
					_hazard_create_entity(@game, @type, @loc, player());
				}
			} else if(string_ends_with(@item['name'], 'MINECART')) {
				cancel();
				consume();
				if(pmode() === 'CREATIVE' && array_index_exists(@event, 'location')) {
					@loc = @event['location'];
					if(get_block_info(@loc)['solid']) {
						@loc = location_shift(@loc, @event['facing']);
					}
					@loc['x'] += 0.5;
					@loc['z'] += 0.5;
					@type = split('_', @item['name'], 1)[0];
					_hazard_create_entity(@game, 'MINECART'.if(@type != 'MINECART', '_'.@type), @loc);
				}
			} else if(pmode() === 'CREATIVE' && @event['action'] === 'right_click_air'
			 && material_info(@item['name'], 'isBlock')) {
				@loc = ploc();
				@loc['y'] += 2.5;
				@v = get_vector(@loc);
				@loc['y'] += @v['y'] * 4;
				@loc['x'] += @v['x'] * 4;
				@loc['z'] += @v['z'] * 4;
				if(sk_can_build(@loc)) {
					try(set_block(@loc, @item['name']))
					play_sound(@loc, array(sound: 'BLOCK_STONE_PLACE'));
				}
			}
			if(pmode() === 'CREATIVE') {
				@game['players'][player()]['buildCount']++;
				update_bar('hazard'.player(), double(@game['players'][player()]['buildCount'] / @game['buildCount']));
			}
		}
	}

	@game['binds'][] = bind('entity_damage', null, array(cause: 'ENTITY_ATTACK', world: @game['world']), @event, @game) {
		if(array_index_exists(@game['players'], @event['damager']) && pmode(@event['damager']) === 'CREATIVE') {
			_hazard_remove_entity(@game, @event['id']);
		}
	}

	@game['binds'][] = bind('vehicle_destroy', null, null, @event, @game) {
		if(array_index_exists(@event, 'damager')
		&& array_index_exists(@game['players'], @event['damager'])
		&& pmode(@event['damager']) === 'CREATIVE') {
			_hazard_remove_entity(@game, @event['vehicle'], false);
		}
	}

	@game['binds'][] = bind('player_death', null, null, @event, @game) {
		if(array_index_exists(@game['players'], player())) {
			if(array_index_exists(@event['cause'], 'damager') && @event['cause']['damagertype'] !== 'PLAYER') {
				// damaged by an entity, see if it was spawned by another player
				@spawner = _hazard_entity_spawner(@game, @event['cause']['damager']);
				if(@spawner && @spawner != player() && array_index_exists(@game['players'], @spawner)) {
					@data = @game['players'][@spawner];
					@data['score']++;
					set_pscore('score', @spawner, @data['score'], 'hazard');
					play_sound(ploc(@spawner), array(sound: 'ENTITY_ARROW_HIT_PLAYER'), @spawner);
				}
			}
			play_sound(ploc(), array(sound: 'ENTITY_EVOKER_DEATH'));
			modify_event('drops', null);
			modify_event('xp', null);
			modify_event('keep_inventory', true);
			export(player().'spawn', location_shift(ploc(), 'up', 2));
			set_timeout(1000, closure() {
				pforce_respawn();
			});
		}
	}

	@game['binds'][] = bind('player_spawn', array(priority: 'HIGHEST'), null, @event, @game) {
		if(array_index_exists(@game['players'], player())) {
			set_pmode(player(), 'SPECTATOR');
			@loc = import(player().'spawn');
			if(@loc) {
				modify_event('location', @loc);
				export(player().'spawn', null);
			}
			consume();
		}
	}
	
	@game['binds'][] = bind('creature_spawn', null, null, @event, @game) {
		if(@event['reason'] != 'CUSTOM' && sk_region_contains(@game['world'], 'hazard', @event['location'])) {
			_hazard_add_entity(@game, @event['id']);
		}
	}

	@game['binds'][] = bind('item_pickup', null, null, @event, @game) {
		if(!array_index_exists(@game['players'], player()) && array_contains(sk_current_regions(), 'hazard')) {
			cancel();
		}
	}

	@game['binds'][] = bind('item_spawn', null, null, @event, @game) {
		if(@game['state'] == 'RUN' && sk_region_contains(@game['world'], 'hazard', @event['location'])) {
			cancel();
		}
	}

	@game['binds'][] = bind('item_drop', null, null, @event, @game) {
		if(@game['state'] === 'BUILD' && @game['world'] == pworld() && array_contains(sk_current_regions(), 'hazard')) {
			bind('item_spawn', array(priority: 'HIGHEST'), null, @event, @game, @player = player()) {
				if(sk_region_contains('hazard', @event['location'])) {
					consume();
					unbind();
					// delay to get accurate drop location
					set_timeout(1000, closure() {
						try {
							_hazard_add_entity(@game, @event['id'], 'DROPPED_ITEM', entity_loc(@event['id']), @player, @event['item']);
						} catch (BadEntityException @ex) {
							// possibly picked up already
						}
					});
				}
			}
		}
	}

	@game['binds'][] = bind('region_change', null, null, @event, @game) {
		if(array_index_exists(@game['players'], player())) {
			if(pmode() === 'ADVENTURE' && array_contains(@event['toRegions'], 'hazard_end')) {
				@data = @game['players'][player()];
				@data['score'] += 10;
				@data['finished'] = true;
				set_pscore('score', player(), @data['score'], 'hazard');
				set_pmode('SPECTATOR');
				play_sound(ploc(), array(sound: 'ENTITY_VINDICATOR_CELEBRATE', pitch: 1.5));
			} else if(array_contains(@event['fromRegions'], 'hazard')) {
				_hazard_remove_player(player(), @game);
			}
		} else if(array_contains(@event['toRegions'], 'hazard')) {
			_hazard_add_player(player(), @game);
		}
	}

	@game['binds'][] = bind('player_quit', null, null, @event, @game) {
		if(array_index_exists(@game['players'], player())) {
			_hazard_remove_player(player(), @game);
		}
	}

	@game['binds'][] = bind('block_from_to', null, array(world: @game['world']), @event, @game) {
		if(sk_region_contains('hazard', @event['location'])) {
			cancel();
		}
	}

	@game['binds'][] = bind('entity_explode', null, null, @event, @game) {
		if(sk_region_contains(@game['world'], 'hazard', @event['location'])) {
			@modified = false;
			foreach(@index: @block in @event['blocks']) {
				@regions = sk_regions_at(@block);
				if(!array_contains(@regions, 'hazard')
				|| array_contains(@regions, 'hazard_start')) {
					array_remove(@event['blocks'], @index);
					@modified = true;
				} else {
					_hazard_add_block(@game, @block);
				}
			}
			if(@modified) {
				modify_event('blocks', @event['blocks']);
			}
		}
	}
}

proc _hazard_unbind(@game) {
	foreach(@bind in @game['binds']) {
		unbind(@bind);
	}
}
