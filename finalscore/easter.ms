bind('creature_spawn', null, array('type': 'ZOMBIE', 'reason': 'SPAWNER_EGG'), @event) {
	if(@event['location']['world'] == 'dev') {
		@mobs = array(
			51: 'SKELETON', 
			52: 'SPIDER', 
			54: 'ZOMBIE', 
			55: 'SLIME', 
			57: 'PIGZOMBIE', 
			58: 'ENDERMAN', 
			59: 'CAVESPIDER', 
			62: 'MAGMACUBE', 
			65: 'BAT', 
			66: 'WITCH', 
			67: 'ENDERMITE',
			68: 'GUARDIAN',
			90: 'PIG', 
			91: 'SHEEP', 
			92: 'COW', 
			93: 'CHICKEN', 
			94: 'SQUID', 
			95: 'WOLF', 
			96: 'MOOSHROOM', 
			98: 'OCELOT', 
			100: 'HORSE',
			101: 'RABBIT',
			120: 'VILLAGER',
		);
		@loc = _relative(@event['location'], 'up');
		drop_item(@loc, array('type': 383, 'data': array_rand(@mobs)[0]), true);
		set_timeout(50, closure(){
			if(entity_exists(@event['id'])) {
				@loc = _relative(@event['location'], 'up');
				# @dinnerbone = spawn_mob('SKELETON', 1, @loc)[0];
				set_timeout(50, closure(){
					# set_mob_name(@dinnerbone, 'Dinnerbone');
					# set_mob_equipment(@dinnerbone, array(
						# 'WEAPON': null,
						# 'HELMET': array('type': 397, 'data': 3, 'meta': array('owner': 'robbydeezle')),
						# 'CHESTPLATE': null,
						# 'LEGGINGS': null,
						# 'BOOTS': null,
					# ));
					# set_equipment_droprates(@dinnerbone, null);
					# set_entity_persistence(@dinnerbone, true);
					# set_entity_rider(@event['id'], @dinnerbone);
					set_entity_persistence(@event['id'], true);
					set_mob_equipment(@event['id'], array(
						'WEAPON': array('type': 383),
						'HELMET': array('type': 397, 'data': 3, 'meta': array('owner': 'rabbit2077')),
						'CHESTPLATE': array('type': 299, 'meta': array('color': array('r': 180, 'g': 180, 'b': 180))),
						'LEGGINGS': array('type': 300, 'meta': array('color': array('r': 180, 'g': 180, 'b': 180))),
						'BOOTS': array('type': 309),
					));
					set_equipment_droprates(@event['id'], null);
					set_mob_effect(@event['id'], 1, 0, 9999, true);
					set_mob_effect(@event['id'], 8, 1, 9999, true);
				})
			}
		})
	}
}

bind('entity_damage', null, array('type': 'ZOMBIE', 'world': 'dev'), @event) {
	if((@event['cause'] == 'ENTITY_ATTACK' || @event['cause'] == 'PROJECTILE')) {
		@inv = get_mob_equipment(@event['id']);
		if(!is_null(@inv['helmet'])
		&& @inv['helmet']['type'] == 397) {
			@loc = _relative(@event['location'], 'up');
			if(function_exists('play_effect')) {
				play_effect(@loc, 'COLOURED_DUST', array('particleCount': 15, 'offsetX': 1, 'offsetY': 1, 'offsetZ': 1));
			}
			if(rand(2)) {
				@mobs = array(
					51: 'SKELETON', 
					52: 'SPIDER', 
					54: 'ZOMBIE', 
					55: 'SLIME', 
					57: 'PIGZOMBIE', 
					58: 'ENDERMAN', 
					59: 'CAVESPIDER', 
					62: 'MAGMACUBE', 
					65: 'BAT', 
					66: 'WITCH',
					67: 'ENDERMITE',
					68: 'GUARDIAN',
					90: 'PIG', 
					91: 'SHEEP', 
					92: 'COW', 
					93: 'CHICKEN', 
					94: 'SQUID', 
					95: 'WOLF', 
					96: 'MOOSHROOM', 
					98: 'OCELOT', 
					100: 'HORSE',
					101: 'RABBIT',
					120: 'VILLAGER',
				);
				drop_item(@loc, array('type': 383, 'data': array_rand(@mobs)[0]), true);
			}
		}
	}
}

bind('target_player', null, array('mobtype': 'ZOMBIE'), @event) {
	if(entity_loc(@event['id'])['world'] == 'dev') {
		@inv = get_mob_equipment(@event['id']);
		if(!is_null(@inv['helmet'])
		&& @inv['helmet']['type'] == 397) {
			shoot_projectile(@event['id'], 'EGG', @event['player'], 2);
			set_timeout(2000, closure(){
				if(entity_exists(@event['id'])) {
					shoot_projectile(@event['id'], 'EGG', @event['player']);
				}
			});
		}
	}
}

bind('projectile_hit', null, array('type': 'EGG'), @event) {
	if(entity_loc(@event['id'])['world'] == 'dev') {
		@mobs = array(
			51: 'SKELETON', 
			52: 'SPIDER', 
			54: 'ZOMBIE', 
			55: 'SLIME', 
			57: 'PIGZOMBIE', 
			58: 'ENDERMAN', 
			59: 'CAVESPIDER', 
			62: 'MAGMACUBE', 
			65: 'BAT', 
			66: 'WITCH', 
			67: 'ENDERMITE',
			68: 'GUARDIAN',
			90: 'PIG', 
			91: 'SHEEP', 
			92: 'COW', 
			93: 'CHICKEN', 
			94: 'SQUID', 
			95: 'WOLF', 
			96: 'MOOSHROOM', 
			98: 'OCELOT', 
			100: 'HORSE',
			101: 'RABBIT',
			120: 'VILLAGER',
		);
		@mob = array_rand(@mobs, 1, false)[0];
		@loc = _relative(@event['location'], 'up');
		@entity = spawn_mob(@mob, 1, @loc)[0];
		if(function_exists('play_effect')) {
			play_effect(@loc, 'COLOURED_DUST', array('particleCount': 15, 'offsetX': 1, 'offsetY': 1, 'offsetZ': 1));
		}
	}
}

bind('creature_spawn', null, array('type': 'CHICKEN', 'reason': 'EGG'), @event) {
	if(@event['location']['world'] == 'dev') {
		cancel();
	}
}