bind('creature_spawn', null, array('type': 'ZOMBIE', 'reason': 'NATURAL'), @event) {
	if(@event['location']['world'] === 'outworld') {
		set_mob_equipment(@event['id'], associative_array(
			'HELMET': array('name': 'SKULL_ITEM', 'data': 3, 'meta': array('owner': 'rabbit2077')),
			'CHESTPLATE': array('name': 'LEATHER_CHESTPLATE', 'meta': array('color': array('r': 180, 'g': 180, 'b': 180))),
			'LEGGINGS': array('name': 'LEATHER_LEGGINGS', 'meta': array('color': array('r': 180, 'g': 180, 'b': 180))),
			'BOOTS': array('name': 'IRON_BOOTS'),
		));
		set_equipment_droprates(@event['id'], associative_array(
			'WEAPON': 1,
			'OFF_HAND': 1,
			'HELMET': 0,
			'CHESTPLATE': 0,
			'LEGGINGS': 0,
			'BOOTS': 0,
		));
		if(!entity_spec(@event['id'])['baby']){
			set_mob_effect(@event['id'], 1, 0, 9999, true);
		}
		set_mob_effect(@event['id'], 8, 1, 9999, true);
		set_entity_silent(@event['id'], true);
	}
}

bind('entity_death', null, array('type': 'ZOMBIE'), @event) {
	if(@event['location']['world'] === 'outworld') {
		@inv = get_mob_equipment(@event['id']);
		if(!is_null(@inv['helmet'])
		&& @inv['helmet']['name'] == 'SKULL_ITEM') {
			@loc = location_shift(@event['location'], 'up');
			if(function_exists('play_effect')) {
				play_effect(@loc, 'COLOURED_DUST', array('particleCount': 15, 'offsetX': 1, 'offsetY': 1, 'offsetZ': 1));
			}
		}
	}
}

bind('target_player', null, array('mobtype': 'ZOMBIE'), @event, @day) {
	try {
		if(entity_loc(@event['id'])['world'] === 'outworld') {
			@inv = get_mob_equipment(@event['id']);
			if(!is_null(@inv['helmet'])
			&& @inv['helmet']['name'] == 'SKULL_ITEM'
			&& entity_can_see(@event['id'], puuid(@event['player']))) {
				@mobs = array(
					'BAT',
					'CAVE_SPIDER',
					'CHICKEN',
					'COW',
					'ELDER_GUARDIAN',
					'ENDERMAN',
					'ENDERMITE',
					'EVOKER',
					'GUARDIAN',
					'HORSE',
					'HUSK',
					'LLAMA',
					'MAGMA_CUBE',
					'MULE',
					'MUSHROOM_COW',
					'OCELOT',
					'PARROT',
					'PIG',
					'PIG_ZOMBIE',
					'POLAR_BEAR',
					'RABBIT',
					'SHEEP',
					'SHULKER',
					'SKELETON',
					'SKELETON_HORSE',
					'SLIME',
					'SPIDER',
					'SQUID',
					'STRAY',
					'VEX',
					'VILLAGER',
					'VINDICATOR',
					'WITCH',
					'WITHER_SKELETON',
					'WOLF',
					'ZOMBIE',
					'ZOMBIE_HORSE',
					'ZOMBIE_VILLAGER',
				);
				@mob = @mobs[rand(array_size(@mobs))];
				set_mob_equipment(@event['id'], associative_array(
					'WEAPON': array('name': 'MONSTER_EGG', 'meta': array('spawntype': @mob)),
				));
				@e = shoot_projectile(@event['id'], 'EGG', @event['player'], rand() + 1);
				if(@day == 1) {
					if(get_mob_name(@event['id']) == 'Dinnerbone') {
						set_mob_name(@event['id'], 'Dinnerbun');
					} else {
						set_mob_name(@event['id'], 'Dinnerbone');
					}
				}
				set_metadata(@e, 'spawn_egg', @mob);
				set_timeout((1 + rand(3)) * 1000, closure() {
					if(entity_exists(@event['id'])
					&& ponline(@event['player'])
					&& phealth(@event['player']) > 10
					&& entity_can_see(@event['id'], puuid(@event['player']))) {
						@mob = @mobs[rand(array_size(@mobs))];
						set_mob_equipment(@event['id'], associative_array(
							'OFF_HAND': array('name': 'MONSTER_EGG', 'meta': array('spawntype': @mob)),
						));
						@e = shoot_projectile(@event['id'], 'EGG', @event['player'], rand() + 1);
						if(@day == 1) {
							if(get_mob_name(@event['id']) == 'Dinnerbone') {
								set_mob_name(@event['id'], 'Dinnerbun');
							} else {
								set_mob_name(@event['id'], 'Dinnerbone');
							}
						}
						set_metadata(@e, 'spawn_egg', @mob);
					}
				});
			}
		}
	} catch(BadEntityException @ex) {
		// non-existent entity is targeting somehow
	}
}

bind('projectile_hit', null, array('type': 'EGG'), @event) {
	if(has_metadata(@event['id'], 'spawn_egg')) {
		@mob = get_metadata(@event['id'], 'spawn_egg', 'CommandHelper');
		@loc = location_shift(@event['location'], 'up');
		@loc['x'] = floor(@loc['x']) + 0.5;
		@loc['z'] = floor(@loc['z']) + 0.5;
		@entity = spawn_entity(@mob, 1, @loc)[0];
		play_sound(@loc, array('sound': 'CHICKEN_EGG_POP', 'pitch': 0.5));
		if(function_exists('play_effect')) {
			play_effect(@loc, 'COLOURED_DUST', array('particleCount': 15, 'offsetX': 1, 'offsetY': 1, 'offsetZ': 1));
		}
		set_entity_persistence(@entity, false);
	}
}

bind('player_interact_entity', null, array('clicked': '/(HORSE|WOLF)/'), @event) {
	if(entity_loc(@event['id'])['world'] === 'outworld') {
		set_entity_persistence(@event['id'], true);
	}
}

bind('creature_spawn', null, array('type': 'CHICKEN', 'reason': 'EGG'), @event) {
	if(@event['location']['world'] === 'outworld') {
		cancel();
	}
}
