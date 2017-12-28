array_push(@pvp['binds'], @id.'nodrops')
bind(item_spawn, array('id': @id.'nodrops'), array('item': 70), @e, @region = @pvp['arena']['region']) {
	if(array_contains(sk_regions_at(@e['location']), @region)) {
		cancel()
	}
}

array_push(@pvp['binds'], @id.'limitentities')
bind(entity_change_block, array('id': @id.'limitentities'), array('from': 12), @e, @region = @pvp['arena']['region']) {
	if(array_contains(sk_regions_at(@e['location']), @region)) {
		entity_remove(@e['entity'])
	}
}

@tnt = array();

array_push(@pvp['binds'], @id.'tntexplode');
bind(entity_explode, array('id': @id.'tntexplode'), array('type': 'PRIMED_TNT'), @e, @tnt) {
	@index = array_index(@tnt, @e['id']);
	if(!is_null(@index)) {
		foreach(@block in @e['blocks']) {
			if(get_block_at(@block) == '70:0') {
				set_block_at(@block, 0);
				set_block_at(_relative(@block, 'down'), 0);
				set_block_at(_relative(@block, 'down', 2), 0);
			}
		}
		array_remove(@tnt, @index);
	}
}

array_push(@pvp['binds'], @id.'tntpickup');
bind(player_interact_entity, array('id': @id.'tntpickup'), array('clicked': 'PRIMED_TNT'), @e, @pvp, @tnt) {
	if(array_index_exists(@pvp['players'], player()) && is_null(get_entity_rider(puuid()))) {
		set_entity_rider(puuid(player()), @e['id']);
		set_pinv(player(), null, array('name': 'TNT'));
		play_sound(ploc(), array('sound': 'CHICKEN_EGG_POP', 'pitch': 0.5));
		@tnt[] = @e['id'];
	}
}

array_push(@pvp['binds'], @id.'tntthrow');
bind(player_interact, array('id': @id.'tntthrow'), array('button': 'left', 'item': data_values('TNT')), @e, @pvp) {
	if(array_index_exists(@pvp['players'], player())) {
		set_pinv(player(), null, null);
		@rider = get_entity_rider(puuid());
		if(!is_null(@rider)) {
			set_entity_rider(null, @rider);
			set_entity_loc(@rider, _relative(ploc(), 'up', 3));
			set_timeout(50, closure(){
				@vector = _get_vector(pfacing(), 1, 0.1);
				try {
					set_entity_velocity(@rider, @vector);
					play_sound(ploc(), array('sound': 'IRONGOLEM_THROW'));
				} catch(BadEntityException @ex) {
					// it done blown up!
				}
			});
		}
	}
}
