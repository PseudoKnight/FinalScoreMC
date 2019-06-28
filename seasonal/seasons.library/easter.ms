bind('creature_spawn', null, array('type': 'ZOMBIE', 'reason': 'NATURAL'), @event) {
	if(@event['location']['world'] === 'outworld') {
		set_mob_equipment(@event['id'], associative_array(
			'HELMET': array('name': 'PLAYER_HEAD', 'meta': array('owner': 'rabbit2077')),
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
		&& @inv['helmet']['name'] == 'PLAYER_HEAD') {
			@loc = location_shift(@event['location'], 'up');
			spawn_particle(@loc, array(
				'particle': 'REDSTONE',
				'count': 15,
				'xoffset': 1,
				'yoffset': 1,
				'zoffset': 1,
				'color': array(rand(256), rand(256), rand(256)),
			));
		}
	}
}

bind('target_player', null, array('mobtype': 'ZOMBIE'), @event, @day) {
	try {
		if(entity_loc(@event['id'])['world'] === 'outworld') {
			@inv = get_mob_equipment(@event['id']);
			if(!is_null(@inv['helmet'])
			&& @inv['helmet']['name'] == 'PLAYER_HEAD'
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
					'MOOSHROOM', //'MUSHROOM_COW'
					'OCELOT',
					'PARROT',
					'PIG',
					'ZOMBIE_PIGMAN', // 'PIG_ZOMBIE'
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
					'PHANTOM',
					'DOLPHIN',
					'TURTLE',
					'DROWNED',
					'COD',
					'SALMON',
					'PUFFERFISH',
					'TROPICAL_FISH',
					'CAT',
					'PILLAGER',
					'FOX',
					'PANDA',
					'RAVAGER',
					'TRADER_LLAMA',
					'WANDERING_TRADER',
				);
				@mob = @mobs[rand(array_size(@mobs))];
				set_mob_equipment(@event['id'], associative_array(
					'WEAPON': array('name': @mob.'_SPAWN_EGG'),
				));
				@e = shoot_projectile(@event['id'], 'EGG', @event['player'], rand() + 1);
				if(@day == 1 || @day == 2 || @day == 31) {
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
							'OFF_HAND': array('name': @mob.'_SPAWN_EGG'),
						));
						@e = shoot_projectile(@event['id'], 'EGG', @event['player'], rand() + 1);
						if(@day == 1 || @day == 2 || @day == 31) {
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
		if(@mob == 'MOOSHROOM') {
			@mob = 'MUSHROOM_COW';
		} else if(@mob == 'ZOMBIE_PIGMAN') {
			@mob = 'PIG_ZOMBIE';
		}
		@loc = location_shift(@event['location'], 'up');
		@loc['x'] = floor(@loc['x']) + 0.5;
		@loc['z'] = floor(@loc['z']) + 0.5;
		@entity = spawn_entity(@mob, 1, @loc)[0];
		play_sound(@loc, array('sound': 'ENTITY_CHICKEN_EGG', 'pitch': 0.5));
		spawn_particle(@loc, array(
			'particle': 'REDSTONE',
			'count': 15,
			'xoffset': 1,
			'yoffset': 1,
			'zoffset': 1,
			'color': array(rand(256), rand(256), rand(256)),
		));
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
