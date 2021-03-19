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
				'enchants': array('protection': 1),
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
				'enchants': array('feather_falling': 3),
			)),
			'WEAPON': @bottle,
			'OFF_HAND': array('name': 'GOLD_INGOT', 'qty': rand(1, 4)),
		));
		set_equipment_droprates(@id, array(
			'HELMET': 0.05,
			'CHESTPLATE': 0.05,
			'LEGGINGS': 0.05,
			'BOOTS': 0.05,
			'WEAPON': 1,
			'OFF_HAND': 1,
		));
		set_mob_effect(@id, 'speed', 0, 107374182);
		set_entity_silent(@id, true);
	}
}

bind('target_player', null, array('mobtype': 'ZOMBIE'), @event) {
	@id = @event['id'];
	try {
		if(get_entity_silent(@id)) {
			@loc = entity_loc(@id);
			play_sound(@loc, array('sound': 'ENTITY_WITCH_AMBIENT', 'pitch': 2, 'volume': 3));
			@loc['pitch'] = -60.0;
			@v = get_vector(@loc, 0.6);
			set_entity_velocity(@id, @v);
		}
	} catch (BadEntityException @ex) {}
	set_timeout(rand(1000, 5000), closure(){
		try {
			if(get_entity_silent(@id)) {
				@loc = entity_loc(@id);
				play_sound(@loc, array('sound': 'ENTITY_WITCH_AMBIENT', 'pitch': 2, 'volume': 3));
				@loc['pitch'] = -60.0;
				@v = get_vector(@loc, 0.6);
				set_entity_velocity(@id, @v);
			}
		} catch (BadEntityException @ex) {}
	});
}
