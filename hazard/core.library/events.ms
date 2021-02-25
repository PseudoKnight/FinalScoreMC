proc _hazard_bind(@game) {
	@game['binds'][] = bind('player_interact', array(priority: 'HIGHEST'), array(button: 'right'), @event, @game) {
		if(array_index_exists(@game['players'], player())) {
			@item = @event['item'];
			if(!@item) {
				die();
			}
			if(string_ends_with(@item['name'], '_SPAWN_EGG')) {
				cancel();
				consume();
				if(pmode() == 'CREATIVE' && array_index_exists(@event, 'location')) {
					@loc = @event['location'];
					if(get_block_info(@loc)['solid']) {
						@loc = location_shift(@loc, @event['facing']);
					}
					@loc['x'] += 0.5;
					@loc['z'] += 0.5;
					@type = reg_match('(.*)_SPAWN_EGG', @item['name'])[1];
					if(@type == 'MOOSHROOM') {
						@type = 'MUSHROOM_COW';
					}
					_hazard_create_entity(@game, @type, @loc, player());
				}
			} else if(string_contains(@item['name'], 'MINECART')) {
				cancel();
				consume();
				if(pmode() == 'CREATIVE' && array_index_exists(@event, 'location')) {
					@loc = @event['location'];
					if(get_block_info(@loc)['solid']) {
						@loc = location_shift(@loc, @event['facing']);
					}
					@loc['x'] += 0.5;
					@loc['z'] += 0.5;
					@type = split('_', @item['name'], 1)[0];
					_hazard_create_entity(@game, 'MINECART'.if(@type != 'MINECART', '_'.@type), @loc);
				}
			} else if(pmode() == 'CREATIVE' && @event['action'] == 'right_click_air'
			 && material_info(@item['name'], 'isBlock')) {
				@loc = ploc();
				@loc['y'] += 2.5;
				@v = get_vector(@loc);
				@loc['y'] += @v['y'] * 4;
				@loc['x'] += @v['x'] * 4;
				@loc['z'] += @v['z'] * 4;
				if(sk_can_build(@loc)) {
					try(set_block(@loc, @item['name']));
					play_sound(@loc, array(sound: 'BLOCK_STONE_PLACE'));
				}
			}
			if(pmode() == 'CREATIVE') {
				@game['countdown'] = true;
			}
		}
	}

	@game['binds'][] = bind('entity_damage', null, array(cause: 'ENTITY_ATTACK', world: @game['world']), @event, @game) {
		if(array_index_exists(@game['players'], @event['damager']) && pmode(@event['damager']) == 'CREATIVE') {
			_hazard_remove_entity(@game, @event['id']);
		}
	}

	@game['binds'][] = bind('vehicle_destroy', null, null, @event, @game) {
		if(array_index_exists(@game['players'], @event['damager']) && pmode(@event['damager']) == 'CREATIVE') {
			_hazard_remove_entity(@game, @event['vehicle']);
		}
	}

	@game['binds'][] = bind('player_death', null, null, @event, @game) {
		if(array_index_exists(@game['players'], player())) {
			if(array_index_exists(@event['cause'], 'damager') && length(@event['cause']['damager']) > 17) {
				// damaged by an entity, see if it was spawned by another player
				@spawner = _hazard_entity_spawner(@game, @event['cause']['damager']);
				if(@spawner && @spawner != player() && array_index_exists(@game['players'], @spawner)) {
					@data = @game['players'][@spawner];
					@data['score']++;
					set_pscore('score', @spawner, @data['score'], 'hazard');
					play_sound(ploc(@spawner), array(sound: 'ENTITY_ARROW_HIT_PLAYER'), @spawner);
				}
			}
			set_pmode(player(), 'SPECTATOR');
			play_sound(ploc(), array(sound: 'ENTITY_EVOKER_DEATH'));
			modify_event('drops', null);
			modify_event('xp', null);
			modify_event('keep_inventory', true);
			export(player().'spawn', ploc());
			set_timeout(150, closure() {
				respawn(player());
			});
		}
	}

	@game['binds'][] = bind('player_spawn', array(priority: 'HIGHEST'), null, @event, @game) {
		if(array_index_exists(@game['players'], player())) {
			@loc = import(player().'spawn');
			if(@loc) {
				modify_event('location', @loc);
				export(player().'spawn', null);
			}
			consume();
		}
	}
	
	@game['binds'][] = bind('creature_spawn', null, null, @event, @game) {
		if(@event['reason'] != 'CUSTOM' && array_contains(sk_regions_at(@event['location']), 'hazard')) {
			_hazard_add_entity(@game, @event['id']);
		}
	}

	@game['binds'][] = bind('item_pickup', null, null, @event, @game) {
		if(!array_index_exists(@game['players'], player()) && array_contains(sk_current_regions(), 'hazard')) {
			cancel();
		}
	}

	@game['binds'][] = bind('item_spawn', null, null, @event, @game) {
		if(@game['state'] == 'RUN' && array_contains(sk_regions_at(@event['location']), 'hazard')) {
			cancel();
		};
	}

	@game['binds'][] = bind('item_drop', null, null, @event, @game) {
		if(@game['state'] == 'BUILD' && array_contains(sk_current_regions(), 'hazard')) {
			bind('item_spawn', array(priority: 'HIGHEST'), null, @event, @game, @player = player()) {
				if(array_contains(sk_regions_at(@event['location']), 'hazard')) {
					consume();
					unbind();
					// delay to get accurate drop location
					set_timeout(1000, closure() {
						_hazard_add_entity(@game, @event['id'], 'DROPPED_ITEM', entity_loc(@event['id']), @player, @event['item']);
					});
				};
			}
		};
	}

	@game['binds'][] = bind('region_change', null, null, @event, @game) {
		if(array_index_exists(@game['players'], player())) {
			if(pmode() == 'ADVENTURE' && array_contains(@event['toRegions'], 'hazard_end')) {
				@data = @game['players'][player()];
				@data['score'] += 10;
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
}

proc _hazard_unbind(@game) {
	foreach(@bind in @game['binds']) {
		unbind(@bind);
	}
}
