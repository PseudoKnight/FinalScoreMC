bind('creature_spawn', null, array(type: 'ZOMBIE', reason: 'NATURAL'), @event) {
	if(@event['location']['world'] == 'outworld') {
		@entity = @event['id'];
		set_mob_equipment(@entity, array(
			HELMET: array(name: 'PLAYER_HEAD', meta: array(owner: 'rabbit2077')),
			CHESTPLATE: array(name: 'LEATHER_CHESTPLATE', meta: array(color: array(r: 180, g: 180, b: 180))),
			LEGGINGS: array(name: 'LEATHER_LEGGINGS', meta: array(color: array(r: 180, g: 180, b: 180))),
			BOOTS: array(name: 'IRON_BOOTS'),
		));
		set_equipment_droprates(@entity, array(
			WEAPON: 1,
			OFF_HAND: 1,
			HELMET: 0,
			CHESTPLATE: 0,
			LEGGINGS: 0,
			BOOTS: 0,
		));
		if(!entity_spec(@entity)['baby']){
			set_mob_effect(@entity, 'speed', 0, 107374182, true);
		}
		set_mob_effect(@entity, 'jump_boost', 1, 107374182, true);
		set_entity_silent(@entity, true);
	}
}

bind('entity_death', null, array(type: 'ZOMBIE'), @event) {
	if(@event['location']['world'] == 'outworld') {
		@inv = get_mob_equipment(@event['id']);
		if(@inv['helmet'] && @inv['helmet']['name'] == 'PLAYER_HEAD') {
			@loc = location_shift(@event['location'], 'up');
			spawn_particle(@loc, array(
				particle: 'REDSTONE',
				count: 15,
				xoffset: 1,
				yoffset: 1,
				zoffset: 1,
				color: array(rand(256), rand(256), rand(256)),
			));
		}
	}
}

bind('target_player', null, array(mobtype: 'ZOMBIE'), @event, @day) {
	try {
		@entity = @event['id'];
		if(entity_loc(@entity)['world'] == 'outworld') {
			@inv = get_mob_equipment(@entity);
			if(@inv['helmet'] && @inv['helmet']['name'] == 'PLAYER_HEAD') {
				@mobs = array(
					'ALLAY',
					'AXOLOTL',
					'BAT',
					'BEE',
					'CAMEL':
					'CAVE_SPIDER',
					'CHICKEN',
					'COW',
					'CREEPER',
					'DONKEY',
					'ELDER_GUARDIAN',
					'ENDERMAN',
					'ENDERMITE',
					'EVOKER',
					'FROG',
					'GLOW_SQUID',
					'GOAT',
					'GUARDIAN',
					'HOGLIN',
					'HORSE',
					'IRON_GOLEM',
					'HUSK',
					'LLAMA',
					'MAGMA_CUBE',
					'MULE',
					'MOOSHROOM', // MUSHROOM_COW
					'OCELOT',
					'PARROT',
					'PIG',
					'PIGLIN',
					'PIGLIN_BRUTE',
					'POLAR_BEAR',
					'RABBIT',
					'SHEEP',
					'SHULKER',
					'SKELETON',
					'SKELETON_HORSE',
					'SLIME',
					'SNIFFER':
					'SNOW_GOLEM', // SNOWMAN
					'SPIDER',
					'SQUID',
					'STRAY',
					'STRIDER',
					'TADPOLE',
					'VEX',
					'VILLAGER',
					'VINDICATOR',
					'WITCH',
					'WITHER_SKELETON',
					'WOLF',
					'ZOGLIN',
					'ZOMBIE',
					'ZOMBIE_HORSE',
					'ZOMBIE_VILLAGER',
					'ZOMBIFIED_PIGLIN',
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

				@throwEgg = closure(@hand) {
					if(entity_exists(@entity)
					&& get_entity_health(@entity) > 0
					&& ponline(@event['player'])
					&& phealth(@event['player']) > 10
					&& entity_can_see(@entity, puuid(@event['player']))) {
						@mob = array_get_rand(@mobs);
						@equipment = associative_array();
						@equipment[@hand] = array(name: @mob.'_SPAWN_EGG');
						set_mob_equipment(@entity, @equipment);
						@egg = shoot_projectile(@entity, 'EGG', @event['player'], rand() + 1);
						if(@day == 1 || @day == 2 || @day == 31) {
							if(get_mob_name(@entity) == 'Dinnerbone') {
								set_mob_name(@entity, 'Dinnerbun');
							} else {
								set_mob_name(@entity, 'Dinnerbone');
							}
						}
						set_timeout(0, closure(try(set_metadata(@egg, 'spawn_egg', @mob))));
					}
				}

				set_timeout(500, closure() {
					@throwEgg('WEAPON');
					set_timeout((2 + rand(4)) * 1000, closure() {
						@throwEgg('OFF_HAND');
					});
				});
			}
		}
	} catch(BadEntityException @ex) {
		// non-existent entity is targeting somehow
	}
}

bind('projectile_hit', null, array(type: 'EGG'), @event) {
	if(has_metadata(@event['id'], 'spawn_egg')) {
		@mob = get_metadata(@event['id'], 'spawn_egg', 'CommandHelper');
		if(@mob == 'MOOSHROOM') {
			@mob = 'MUSHROOM_COW';
		} else if(@mob == 'SNOW_GOLEM') {
			@mob = 'SNOWMAN';
		}
		@loc = _center(@event['location'], 1);
		spawn_entity(@mob, 1, @loc, closure(@entity) {
			set_entity_persistence(@entity, false);
		});
		play_sound(@loc, array(sound: 'ENTITY_CHICKEN_EGG', pitch: 0.5));
		spawn_particle(@loc, array(
			particle: 'REDSTONE',
			count: 15,
			xoffset: 1,
			yoffset: 1,
			zoffset: 1,
			color: array(rand(256), rand(256), rand(256)),
		));
	}
}

bind('player_interact_entity', null, array(clicked: '/(HORSE|WOLF)/'), @event) {
	if(entity_loc(@event['id'])['world'] == 'outworld') {
		set_entity_persistence(@event['id'], true);
	}
}

bind('creature_spawn', null, array(type: 'CHICKEN', reason: 'EGG'), @event) {
	if(@event['location']['world'] == 'outworld') {
		cancel();
	}
}
