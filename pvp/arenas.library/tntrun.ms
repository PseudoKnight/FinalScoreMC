proc _load_events(@id) {
	@pvp = import('pvp'.@id);
	
	array_push(@pvp['binds'], @id.'nodrops')
	bind('item_spawn', array('id': @id.'nodrops'), array('item': 70), @e, @region = @pvp['arena']['region']) {
		if(array_contains(sk_regions_at(@e['location']), @region)) {
			cancel()
		}
	}

	array_push(@pvp['binds'], @id.'limitentities')
	bind('entity_change_block', array('id': @id.'limitentities'), array('from': 12), @e, @region = @pvp['arena']['region']) {
		if(array_contains(sk_regions_at(@e['location']), @region)) {
			entity_remove(@e['entity'])
		}
	}

	@tnt = array();

	array_push(@pvp['binds'], @id.'tntexplode');
	bind('entity_explode', array('id': @id.'tntexplode'), array('type': 'PRIMED_TNT'), @e, @tnt) {
		@index = array_index(@tnt, @e['id']);
		if(!is_null(@index)) {
			foreach(@block in @e['blocks']) {
				if(get_block(@block) == 'STONE_PRESSURE_PLATE') {
					set_block(@block, 'AIR');
					set_block(location_shift(@block, 'down'), 'AIR');
					set_block(location_shift(@block, 'down', 2), 'AIR');
				}
			}
			array_remove(@tnt, @index);
		}
	}

	array_push(@pvp['binds'], @id.'tntpickup');
	bind('player_interact_entity', array('id': @id.'tntpickup'), array('clicked': 'PRIMED_TNT'), @e, @pvp, @tnt) {
		if(array_index_exists(@pvp['players'], player()) && is_null(get_entity_rider(puuid()))) {
			set_entity_rider(puuid(player()), @e['id']);
			set_pinv(player(), null, array('name': 'TNT'));
			play_sound(ploc(), array('sound': 'ENTITY_CHICKEN_EGG', 'pitch': 0.5));
			@tnt[] = @e['id'];
		}
	}

	array_push(@pvp['binds'], @id.'tntthrow');
	bind('player_interact', array('id': @id.'tntthrow'), array('button': 'left', 'itemname': 'TNT'), @e, @pvp) {
		if(array_index_exists(@pvp['players'], player())) {
			set_pinv(player(), null, null);
			@rider = get_entity_rider(puuid());
			if(!is_null(@rider)) {
				set_entity_rider(null, @rider);
				set_entity_loc(@rider, location_shift(ploc(), 'up', 3));
				set_timeout(50, closure(){
					@vector = get_vector(ploc());
					@vector['y'] += 0.1;
					try {
						set_entity_velocity(@rider, @vector);
						play_sound(ploc(), array('sound': 'ENTITY_IRONGOLEM_THROW'));
					} catch(BadEntityException @ex) {
						// it done blown up!
					}
				});
			}
		}
	}
}
