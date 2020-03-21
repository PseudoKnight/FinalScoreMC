bind('creature_spawn', null, array('type': 'ZOMBIE', 'reason': 'NATURAL'), @event) {
	if(!rand(3)) {
		@id = @event['id'];
		set_entity_spec(@id, array('baby': true));

		// generate potion
		@bottle = null;
		if(rand(8)) {
			@bottle = array('name': 'POTION', 'meta': array(
				'display': 'Suspicious Potion',
				'lore': 'The effects are unknown and possibly lethal.',
				'flags': array('HIDE_POTION_EFFECTS'),
				'potions': associative_array(),
				'color': array(rand(256), rand(256), rand(256)),
			));
			@effects = reflect_pull('enum', 'PotionEffectType');
			do {
				@effect = to_lower(string(array_get_rand(@effects)));
				@bottle['meta']['potions'][@effect] = array('seconds': rand(1, 480), 'strength': rand(3)),
			} while(rand() > 0.67);
		} else {
			@bottle = array('name': 'POTION', 'meta': array(
				'base': array('type': 'LUCK');
			));
		}

		set_mob_equipment(@id, array(
			'HELMET': array('name': 'LEATHER_HELMET', 'meta': array(
				'color': array(0, 255, 0),
				'enchants': array('fire_protection': 1),
			)),
			'CHESTPLATE': array('name': 'LEATHER_CHESTPLATE', 'meta': array(
				'color': array(0, 255, 0),
				'enchants': array('projectile_protection': 1),
			)),
			'LEGGINGS': array('name': 'LEATHER_LEGGINGS', 'meta': array(
				'color': array(0, 255, 0),
				'enchants': array('thorns': 1),
			)),
			'BOOTS': array('name': 'LEATHER_BOOTS', 'meta': array(
				'color': array(0, 255, 0),
				'enchants': array('protection': 1),
			)),
			'WEAPON': @bottle,
			'OFF_HAND': array('name': 'GOLD_INGOT', 'qty': rand(1, 4)),
		));
		set_equipment_droprates(@id, array(
			'HELMET': 0.1,
			'CHESTPLATE': 0.1,
			'LEGGINGS': 0.1,
			'BOOTS': 0.1,
			'WEAPON': 1,
			'OFF_HAND': 1,
		));
		set_mob_effect(@id, 'speed', 0, 107374182);
		set_entity_silent(@id, true);
	}
}

bind('target_player', null, array('mobtype': 'ZOMBIE'), @event) {
	try {
		if(get_entity_silent(@event['id'])) {
			play_sound(entity_loc(@event['id']), array('sound': 'ENTITY_WITCH_AMBIENT', 'pitch': 2, 'volume': 3));
			set_entity_velocity(@event['id'], array(0, 0.3, 0));
		}
	} catch (BadEntityException @ex) {}
}
