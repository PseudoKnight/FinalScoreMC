bind('creature_spawn', null, array(type: 'ZOMBIE', reason: 'NATURAL'), @event) {
	if(@event['location']['world'] === 'outworld' && !rand(4)) {
		@id = @event['id'];
		set_entity_spec(@id, array(baby: true));
		add_scoreboard_tag(@id, 'leprechaun');

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
				@bottle['meta']['potions'][@effect] = array(
					seconds: if(string_starts_with(@effect, 'INSTANT'), 0.1, rand(1, 540)),
					strength: rand(2));
			} while(rand() > 0.75)
		} else {
			@bottle = array(name: 'POTION', meta: array(potiontype: 'LUCK'));
		}

		set_mob_equipment(@id, array(
			HELMET: array(name: 'PLAYER_HEAD', meta: array(display: 'Leprechaun\'s Head',
				owneruuid: 'ec352aee-a368-42cc-beaa-0c3ecccbfdd3', texture:
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
		set_entity_silent(@id, true);
	}
}

bind('target_player', null, array(mobtype: 'ZOMBIE'), @event) {
	@id = @event['id'];
	try {
		if(has_scoreboard_tag(@id, 'leprechaun')) {
			@loc = entity_loc(@id);
			if(distance(@loc, ploc()) > 12) {
				@meta = get_mob_equipment(@id)['weapon']['meta'];
				if(@meta['potions']) {
					set_mob_effect(@id, 'slowness', 4, 1.5, true, false);
					play_sound(@loc, array(sound: 'ENTITY_GENERIC_DRINK', volume: 2));
					foreach(@effect: @data in @meta['potions']) {
						set_mob_effect(@id, @effect, @data['strength'], @data['seconds']);
					}
				}
			} else {
				play_sound(@loc, array(sound: 'ENTITY_VINDICATOR_CELEBRATE', pitch: 1.8, volume: 2));
				@loc['pitch'] = -60.0;
				@v = get_vector(@loc, 0.6);
				set_entity_velocity(@id, @v);
			}
			set_timeout(rand(1000, 5000), closure(){
				try {
					if(has_scoreboard_tag(@id, 'leprechaun')) {
						if(!get_mob_name(@id)) {
							set_mob_name(@id, 'Leprechaun');
						}
						@loc = entity_loc(@id);
						play_sound(@loc, array(sound: 'ENTITY_VINDICATOR_CELEBRATE', pitch: 1.9, volume: 2));
						@loc['pitch'] = -60.0;
						@v = get_vector(@loc, 0.6);
						set_entity_velocity(@id, @v);
						if(distance(entity_loc(@id), ploc()) > 12) {
							@meta = get_mob_equipment(@id)['weapon']['meta'];
							if(@meta['potions']) {
								set_mob_effect(@id, 'slowness', 4, 1.5, true, false);
								play_sound(entity_loc(@id), array(sound: 'ENTITY_GENERIC_DRINK', volume: 2));
								foreach(@effect: @data in @meta['potions']) {
									set_mob_effect(@id, @effect, @data['strength'], @data['seconds']);
								}
							}
						}
					}
				} catch (BadEntityException @ex) {}
			});
		}
	} catch (BadEntityException @ex) {}
}

bind('entity_damage', null, array(type: 'ZOMBIE'), @event) {
	@id = @event['id'];
	if(has_scoreboard_tag(@id, 'leprechaun')) {
		if(@event['cause'] === 'ENTITY_ATTACK' || @event['cause'] === 'PROJECTILE') {
			set_timeout(500, closure(){
				try {
					if(get_entity_health(@id) > 0.0) {
						@loc = entity_loc(@id);
						play_sound(@loc, array(sound: 'ENTITY_VINDICATOR_CELEBRATE', pitch: 2, volume: 2));
						@loc['pitch'] = -60.0;
						@loc['yaw'] = rand(360);
						@v = get_vector(@loc, 0.6);
						set_entity_velocity(@id, @v);
					}
				} catch (BadEntityException @ex) {}
			});
		} else {
			if(rand(100)) { // occasionally allow this damage to prevent invincibility
				cancel();
			}
			if(rand(2)) {
				set_timeout(50, closure(){
					try {
						@loc = entity_loc(@id);
						if(rand(2)) { // mitigate sound spam
							play_sound(@loc, array(sound: 'ENTITY_VINDICATOR_CELEBRATE', pitch: 1.8));
						}
						@loc['pitch'] = -60.0;
						@v = get_vector(@loc, 0.6);
						set_entity_velocity(@id, @v);
					} catch (BadEntityException @ex) {}
				});
			}
		}
	}
}
