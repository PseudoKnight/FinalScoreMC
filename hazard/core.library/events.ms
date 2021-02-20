proc _hazard_bind(@game) {
	bind('player_interact', array(id: 'hazard_interact', priority: 'HIGHEST'), array(button: 'right'), @event, @game) {
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
				@loc['y'] += @v['y'] * 3;
				@loc['x'] += @v['x'] * 3;
				@loc['z'] += @v['z'] * 3;
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

	bind('entity_damage', array(id: 'hazard_damage'), array(cause: 'ENTITY_ATTACK', world: @game['world']), @event, @game) {
		if(array_index_exists(@game['players'], @event['damager']) && pmode(@event['damager']) == 'CREATIVE') {
			_hazard_remove_entity(@game, @event['id']);
		}
	}

	bind('vehicle_destroy', array(id: 'hazard_vehicle_damage'), null, @event, @game) {
		if(array_index_exists(@game['players'], @event['damager']) && pmode(@event['damager']) == 'CREATIVE') {
			_hazard_remove_entity(@game, @event['vehicle']);
		}
	}

	bind('player_death', array(id: 'hazard_death'), null, @event, @game) {
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

	bind('player_spawn', array(id: 'hazard_spawn', priority: 'HIGHEST'), null, @event, @game) {
		if(array_index_exists(@game['players'], player())) {
			@loc = import(player().'spawn');
			if(@loc) {
				modify_event('location', @loc);
				export(player().'spawn', null);
			}
			consume();
		}
	}
	
	bind('creature_spawn', array(id: 'hazard_creature_spawn'), null, @event, @game) {
		if(@event['reason'] != 'CUSTOM' && array_contains(sk_regions_at(@event['location']), 'hazard')) {
			@game['entities'][] = array(uuid: @event['id']);
		}
	}

	bind('item_pickup', array(id: 'hazard_pickup'), null, @event, @game) {
		if(!array_index_exists(@game['players'], player()) && array_contains(sk_current_regions(), 'hazard')) {
			cancel();
		}
	}

	bind('item_spawn', array(id: 'hazard_item_spawn'), null, @event, @game) {
		if(@game['state'] == 'RUN' && array_contains(sk_regions_at(@event['location']), 'hazard')) {
			cancel();
		};
	}

	bind('item_drop', array(id: 'hazard_item_drop'), null, @event, @game) {
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
}

proc _hazard_unbind(@game) {
	unbind('hazard_interact');
	unbind('hazard_damage');
	unbind('hazard_vehicle_damage');
	unbind('hazard_death');
	unbind('hazard_spawn');
	unbind('hazard_creature_spawn');
	unbind('hazard_pickup');
	unbind('hazard_item_spawn');
	unbind('hazard_item_drop');
}
