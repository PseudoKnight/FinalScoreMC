bind('creature_spawn', null, array(type: 'ZOMBIE', reason: 'NATURAL'), @event, 
		@trims = reflect_pull('enum', 'TrimPattern'),
		@mats = array('LAPIS', 'AMETHYST', 'EMERALD', 'DIAMOND', 'GOLD', 'REDSTONE')) {
	if(@event['location']['world'] === 'outworld' && rand(2)) {
		@entity = @event['id'];
		add_scoreboard_tag(@entity, 'easter_bunny');
		set_mob_equipment(@entity, array(
			HELMET: array(name: 'PLAYER_HEAD', meta: array(owneruuid: 'fbec11d4-80a7-4c1c-9de3-4136a16f1de0', texture:
			'eyJ0ZXh0dXJlcyI6eyJTS0lOIjp7InVybCI6Imh0dHA6Ly90ZXh0dXJlcy5taW5lY3JhZnQubmV0L3RleHR1cmUvZDU5YjU3MWRiMDI4NDI5ZmZlZmQwZTg2NzQ3NjBlMjU4ZjA4M2FlNjliYWQ4NWJjMzc2MTk2MWJjY2Q0YWFlIn19fQ==')),
			CHESTPLATE: array(name: 'IRON_CHESTPLATE', meta: array(trim: array(material: array_get_rand(@mats), pattern: array_get_rand(@trims)))),
			LEGGINGS: array(name: 'IRON_LEGGINGS', meta: array(trim: array(material: array_get_rand(@mats), pattern: array_get_rand(@trims)))),
			BOOTS: array(name: 'IRON_BOOTS', meta: array(trim: array(material: array_get_rand(@mats), pattern: array_get_rand(@trims)))),
		));
		set_equipment_droprates(@entity, array(
			WEAPON: 1,
			OFF_HAND: 1,
			HELMET: 0,
			CHESTPLATE: 0,
			LEGGINGS: 0,
			BOOTS: 0,
		));
		set_entity_spec(@entity, array(baby: true));
		set_mob_effect(@entity, 'jump_boost', 1, -1, true, false);
		set_entity_silent(@entity, true);
	}
}

bind('entity_damage', null, array(type: 'ZOMBIE'), @event) {
	if(has_scoreboard_tag(@event['id'], 'easter_bunny')) {
		@loc = location_shift(@event['location'], 'up');
		@count = 3;
		while(@count-- > 0) {
			spawn_particle(@loc, array(
				particle: 'REDSTONE',
				count: 5,
				xoffset: 1,
				yoffset: 1,
				zoffset: 1,
				color: array(rand(256), rand(256), rand(256)),
			));
		}
		if(@event['finalamount'] >= get_entity_health(@event['id'])) {
			play_sound(@loc, array(sound: 'ENTITY_RABBIT_DEATH', pitch: 0.5));
		} else {
			play_sound(@loc, array(sound: 'ENTITY_RABBIT_HURT', pitch: 0.5));
		}
	}
}

bind('entity_death', null, array(type: 'ZOMBIE'), @event) {
	if(has_scoreboard_tag(@event['id'], 'easter_bunny')) {
		@drops = @event['drops'];
		foreach(@i: @drop in @drops) {
			if(@drop['name'] == 'ROTTEN_FLESH') {
				array_remove(@drops, @i);
			}
		}
		modify_event('drops', @drops);
	}
}

bind('target_player', null, array(mobtype: 'ZOMBIE'), @event, @day, @passive = array(
	'ALLAY',
	'ARMADILLO',
	'AXOLOTL',
	'BAT',
	'BEE',
	'CAMEL':
	'CAT',
	'CHICKEN',
	'COD',
	'COW',
	'DOLPHIN',
	'DONKEY',
	'FOX',
	'FROG',
	'GLOW_SQUID',
	'GOAT',
	'HORSE',
	'IRON_GOLEM',
	'LLAMA',
	'MAGMA_CUBE',
	'MULE',
	'MOOSHROOM', // MUSHROOM_COW
	'OCELOT',
	'PANDA',
	'PARROT',
	'PIG',
	'POLAR_BEAR',
	'RABBIT',
	'SALMON',
	'SHEEP',
	'SNIFFER':
	'SNOW_GOLEM', // SNOWMAN
	'SQUID',
	'STRIDER',
	'TADPOLE',
	'TRADER_LLAMA',
	'TROPICAL_FISH',
	'TURTLE',
	'VILLAGER',
	'WANDERING_TRADER',
	'WOLF',
	'ZOMBIE_HORSE',
), @hostile = array(
	'BOGGED',
	'BREEZE',
	'CAVE_SPIDER',
	'CREAKING',
	'CREEPER',
	'DROWNED',
	'ELDER_GUARDIAN',
	'ENDERMAN',
	'ENDERMITE',
	'EVOKER',
	'GUARDIAN',
	'HOGLIN',
	'HUSK',
	'PHANTOM',
	'PIGLIN',
	'PIGLIN_BRUTE',
	'PILLAGER',
	'PUFFERFISH',
	'RAVAGER',
	'SHULKER',
	'SILVERFISH',
	'SKELETON',
	'SKELETON_HORSE',
	'SLIME',
	'SPIDER',
	'STRAY',
	'VEX',
	'VINDICATOR',
	'WITCH',
	'WITHER_SKELETON',
	'ZOGLIN',
	'ZOMBIE',
	'ZOMBIE_VILLAGER',
	'ZOMBIFIED_PIGLIN',
	// 'BLAZE', destructive
	// 'WARDEN', too dangerous
	// 'ENDER_DRAGON', too destructive and has an advancement
	// 'GHAST', destructive and has an advancement
)) {
	try {
		@entity = @event['id'];
		if(has_scoreboard_tag(@entity, 'easter_bunny')) {
			@throwEgg = closure(@hand) {
				if(entity_exists(@entity)
				&& get_entity_health(@entity) > 0
				&& ponline(@event['player'])
				&& phealth(@event['player']) > 10
				&& entity_can_see(@entity, puuid(@event['player']))) {
					@equipment = get_mob_equipment(@entity);
					@item = @equipment[@hand];
					@mob = null;
					if(!@item || @hand === 'off_hand') {
						@mob = array_get_rand(if(@hand === 'weapon', @passive, @hostile));
						@item = array(name: @mob.'_SPAWN_EGG');
						@equipment[@hand] = @item;
						set_mob_equipment(@entity, @equipment);
					} else {
						@mob = replace(@item['name'], '_SPAWN_EGG', '');
					}
					@egg = shoot_projectile(@entity, 'EGG', @event['player'], rand() + 1);
					set_projectile_item(@egg, @item);
					if(@day == 1 || @day == 2 || @day == 31) {
						if(get_mob_name(@entity) === 'Dinnerbone') {
							set_mob_name(@entity, 'Dinnerbun');
						} else {
							set_mob_name(@entity, 'Dinnerbone');
						}
					}
					set_timeout(0, closure(try(set_metadata(@egg, 'spawn_egg', @mob))));
				}
			}

			set_timeout(500, closure() {
				@throwEgg('weapon');
				set_timeout((2 + rand(4)) * 1000, closure() {
					@throwEgg('off_hand');
				});
			});
		}
	} catch(BadEntityException @ex) {
		// non-existent entity is targeting somehow
	}
}

bind('projectile_hit', null, array(type: 'EGG'), @event) {
	if(has_metadata(@event['id'], 'spawn_egg')) {
		@mob = get_metadata(@event['id'], 'spawn_egg', 'CommandHelper');
		if(@mob === 'MOOSHROOM') {
			@mob = 'MUSHROOM_COW';
		} else if(@mob === 'SNOW_GOLEM') {
			@mob = 'SNOWMAN';
		}
		@loc = _center(@event['location'], 1);
		spawn_entity(@mob, 1, @loc, closure(@entity) {
			set_entity_persistence(@entity, false);
		});
		play_sound(@loc, array(sound: 'ENTITY_CHICKEN_EGG', pitch: 0.5));
		@count = 3;
		while(@count-- > 0) {
			spawn_particle(@loc, array(
				particle: 'REDSTONE',
				count: 5,
				xoffset: 1,
				yoffset: 1,
				zoffset: 1,
				color: array(rand(256), rand(256), rand(256)),
			));
		}
	}
}

bind('player_interact_entity', null, array(hand: 'main_hand'), @event) {
	if(entity_loc(@event['id'])['world'] === 'outworld' && is_tameable(@event['id'])) {
		set_entity_persistence(@event['id'], true);
	}
}

bind('creature_spawn', null, array(type: 'CHICKEN', reason: 'EGG'), @event) {
	if(@event['location']['world'] === 'outworld') {
		cancel();
	}
}

bind('player_death', array(priority: 'HIGHEST'), null, @event) {
	if(@event['cause']['cause'] === 'ENTITY_ATTACK'
	&& length(@event['cause']['damager']) > 17
	&& has_scoreboard_tag(@event['cause']['damager'], 'easter_bunny')) {
		modify_event('death_message', @event['player'].' was hugged by the Easter Bunny');
	}
}
