bind('creature_spawn', null, array(type: 'ZOMBIE', reason: 'NATURAL'), @event) {
	if(!rand(4)) {
		@id = @event['id'];
		set_entity_spec(@id, array(baby: true));

		// generate potion
		@bottle = null;
		if(rand(8)) {
			@bottle = array(name: 'POTION', meta: array(
				display: 'Suspicious Potion',
				lore: 'The effects are unknown and possibly lethal.',
				flags: array('HIDE_POTION_EFFECTS'),
				potions: associative_array(),
				color: array(rand(256), rand(256), rand(256)),
			));
			@effects = reflect_pull('enum', 'PotionEffectType');
			do {
				@effect = to_lower(string(array_get_rand(@effects)));
				@bottle['meta']['potions'][@effect] = array(seconds: rand(1, 540), strength: rand(3)),
			} while(rand() > 0.67)
		} else {
			@bottle = array(name: 'POTION', meta: array(
				base: array(type: 'LUCK')
			));
		}

		set_mob_equipment(@id, array(
			HELMET: array(name: 'PLAYER_HEAD', meta: array(display: 'Leprechaun\'s Head',
				owneruuid: '617a67e5-7988-4645-af56-42c770a6dda5', texture:
				'eyJ0ZXh0dXJlcyI6eyJTS0lOIjp7InVybCI6Imh0dHA6Ly90ZXh0dXJlcy5taW5lY3JhZnQubmV0L3RleHR1cmUvZDgxM2M5YmJmYTFhNmY1YzNhYTFlYzliZWIyYWI2ZDhjNTI3NzdjOWQyZjkwYTMyMzRmZDkxYTBiN2ViIn19fQ==',
			)),
			CHESTPLATE: array(name: 'LEATHER_CHESTPLATE', meta: array(display: 'Leprechaun\'s Jacket',
				color: array(0, 255, 0),
				trim: array(material: 'GOLD', pattern: 'VEX'),
			)),
			LEGGINGS: array(name: 'GOLDEN_LEGGINGS', meta: array(display: 'Leprechaun\'s Pants',
				trim: array(material: 'EMERALD', pattern: 'SILENCE'),
			)),
			BOOTS: array(name: 'LEATHER_BOOTS', meta: array(display: 'Leprechaun\'s Boots',
				trim: array(material: 'GOLD', pattern: 'WARD'),
			)),
			WEAPON: @bottle,
			OFF_HAND: array(name: 'GOLD_INGOT', qty: rand(1, 4)),
		));
		set_equipment_droprates(@id, array(
			HELMET: 0.04,
			CHESTPLATE: 0.04,
			LEGGINGS: 0.04,
			BOOTS: 0.04,
			WEAPON: 1,
			OFF_HAND: 1,
		));
		set_mob_effect(@id, 'speed', 0, -1, true, false);
		set_mob_name(@id, 'Leprechaun');
		set_entity_silent(@id, true);
	}
}

bind('target_player', null, array(mobtype: 'ZOMBIE'), @event) {
	@id = @event['id'];
	try {
		if(get_entity_silent(@id)) {
			@loc = entity_loc(@id);
			play_sound(@loc, array(sound: 'ENTITY_VINDICATOR_CELEBRATE', pitch: 1.8, volume: 3));
			@loc['pitch'] = -60.0;
			@v = get_vector(@loc, 0.6);
			set_entity_velocity(@id, @v);
		}
	} catch (BadEntityException @ex) {}
	set_timeout(rand(1000, 5000), closure(){
		try {
			if(get_entity_silent(@id)) {
				@loc = entity_loc(@id);
				play_sound(@loc, array(sound: 'ENTITY_VINDICATOR_CELEBRATE', pitch: 1.9, volume: 3));
				@loc['pitch'] = -60.0;
				@v = get_vector(@loc, 0.6);
				set_entity_velocity(@id, @v);
			}
		} catch (BadEntityException @ex) {}
	});
}

bind('entity_damage', null, array(type: 'ZOMBIE'), @event) {
	@id = @event['id'];
	if(get_entity_silent(@id)) {
		if(@event['cause'] == 'FALL') {
			cancel();
		} else {
			set_timeout(500, closure(){
				try {
					if(get_entity_health(@id) > 0.0) {
						@loc = entity_loc(@id);
						play_sound(@loc, array(sound: 'ENTITY_VINDICATOR_CELEBRATE', pitch: 2, volume: 3));
						@loc['pitch'] = -60.0;
						@loc['yaw'] = rand(360);
						@v = get_vector(@loc, 0.6);
						set_entity_velocity(@id, @v);
					}
				} catch (BadEntityException @ex) {}
			});
		}
	}
}
