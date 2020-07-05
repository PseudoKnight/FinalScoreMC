proc _hazard_bind(@game) {
	bind('player_interact', array('id': 'hazard_interact', 'priority': 'HIGHEST'), array('button': 'right'), @event, @game) {
		if(array_index_exists(@game['players'], player())) {
			if(@event['item'] && string_ends_with(@event['item']['name'], '_SPAWN_EGG')) {
				cancel();
				consume();
				if(pmode() == 'CREATIVE' && array_index_exists(@event, 'location')) {
					@loc = @event['location'];
					if(get_block_info(@loc)['solid']) {
						@loc = location_shift(@loc, @event['facing']);
					}
					@loc['x'] += 0.5;
					@loc['z'] += 0.5;
					@type = reg_match('(.*)_SPAWN_EGG', @event['item']['name'])[1];
					if(@type == 'MOOSHROOM') {
						@type = 'MUSHROOM_COW';
					}
					_hazard_create_entity(@game, @type, @loc);
				}
			} else if(pmode() == 'CREATIVE' && @event['action'] == 'right_click_air'
			&& @event['item'] && material_info(@event['item']['name'], 'isBlock')) {
				@loc = ploc();
				@loc['y'] += 2.5;
				@v = get_vector(@loc);
				@loc['y'] += @v['y'] * 3;
				@loc['x'] += @v['x'] * 3;
				@loc['z'] += @v['z'] * 3;
				if(sk_can_build(@loc)) {
					try(set_block(@loc, @event['item']['name']));
					play_sound(@loc, array('sound': 'BLOCK_STONE_PLACE'));
				}
			}
			if(pmode() == 'CREATIVE') {
				@game['countdown'] = true;
			}
		}
	}

	bind('entity_damage', array('id': 'hazard_damage'), array('cause': 'ENTITY_ATTACK', 'world': @game['world']), @event, @game) {
		if(array_index_exists(@game['players'], @event['damager']) && pmode(@event['damager']) == 'CREATIVE') {
			_hazard_remove_entity(@event['id'], @game);
		}
	}

	bind('player_death', array('id': 'hazard_death'), null, @event, @game) {
		if(array_index_exists(@game['players'], player())) {
			set_pmode(player(), 'SPECTATOR');
			play_sound(ploc(), array('sound': 'ENTITY_EVOKER_DEATH'));
			modify_event('drops', null);
			modify_event('xp', null);
			modify_event('keep_inventory', true);
			export(player().'spawn', ploc());
			set_timeout(150, closure() {
				respawn(player());
			});
		}
	}

	bind('player_spawn', array('id': 'hazard_spawn', 'priority': 'HIGHEST'), null, @event, @game) {
		if(array_index_exists(@game['players'], player())) {
			@loc = import(player().'spawn');
			if(@loc) {
				modify_event('location', @loc);
				export(player().'spawn', null);
			}
			consume();
		}
	}
}

proc _hazard_unbind(@game) {
	unbind('hazard_interact');
	unbind('hazard_damage');
	unbind('hazard_death');
	unbind('hazard_spawn');
}
