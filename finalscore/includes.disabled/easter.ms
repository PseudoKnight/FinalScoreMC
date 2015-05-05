bind('creature_spawn', null, array('type': 'ZOMBIE', 'reason': 'NATURAL'), @event) {
	if(@event['location']['world'] == 'outworld') {
		# @mobs = array(
			# 51: 'SKELETON', 
			# 52: 'SPIDER', 
			# 54: 'ZOMBIE', 
			# 55: 'SLIME', 
			# 57: 'PIGZOMBIE', 
			# 58: 'ENDERMAN', 
			# 59: 'CAVESPIDER', 
			# 62: 'MAGMACUBE', 
			# 65: 'BAT', 
			# 66: 'WITCH', 
			# 67: 'ENDERMITE',
			# 68: 'GUARDIAN',
			# 90: 'PIG', 
			# 91: 'SHEEP', 
			# 92: 'COW', 
			# 93: 'CHICKEN', 
			# 94: 'SQUID', 
			# 95: 'WOLF', 
			# 96: 'MOOSHROOM', 
			# 98: 'OCELOT', 
			# 100: 'HORSE',
			# 101: 'RABBIT',
			# 120: 'VILLAGER',
		# );
		set_timeout(50, closure(){
			if(entity_exists(@event['id'])) {
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
			}
		})
	}
}

bind('entity_death', null, array('type': 'ZOMBIE'), @event) {
	if(@event['location']['world'] == 'outworld') {
		@inv = get_mob_equipment(@event['id']);
		if(!is_null(@inv['helmet'])
		&& @inv['helmet']['type'] == 397) {
			@player = '';
			if(array_index_exists(@event['cause'], 'damager')) {
				if(ponline(@event['cause']['damager'])) {
					@player = @event['cause']['damager'];
				} else if(array_index_exists(@event['cause'], 'shooter')
				&& ponline(@event['cause']['shooter'])) {
					@player = @event['cause']['shooter'];
				}
			}

			if(@player != '') {
				@looting = 0;
				@weapon = pinv(@player, null);
				if(!is_null(@weapon)) {
					foreach(@enchant in @weapon['enchants']) {
						if(@enchant['etype'] == 'LOOT_BONUS_MOBS') {
							@looting = @enchant['elevel'];
							break();
						}
					}
				}
				@loc = _relative(@event['location'], 'up');
				if(function_exists('play_effect')) {
					play_effect(@loc, 'COLOURED_DUST', array('particleCount': 15, 'offsetX': 1, 'offsetY': 1, 'offsetZ': 1));
				}
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
				modify_event('drops', array(array('type': 383, 'qty': rand(1, 4 + @looting), 'data': array_rand(@mobs)[0])));
			}
		}
	}
}

bind('target_player', null, array('mobtype': 'ZOMBIE'), @event) {
	if(entity_loc(@event['id'])['world'] == 'outworld') {
		@inv = get_mob_equipment(@event['id']);
		if(!is_null(@inv['helmet'])
		&& @inv['helmet']['type'] == 397
		&& entity_can_see(@event['id'], pinfo(@event['player'], 13))) {
			shoot_projectile(@event['id'], 'EGG', @event['player'], rand() + 1);
			set_timeout((1 + rand(3)) * 1000, closure() {
				if(entity_exists(@event['id'])
				&& ponline(@event['player'])
				&& pinfo(@event['player'], 5) > 10
				&& entity_can_see(@event['id'], pinfo(@event['player'], 13))) {
					shoot_projectile(@event['id'], 'EGG', @event['player'], rand() + 1);
				}
			});
		}
	}
}

bind('projectile_hit', null, array('type': 'EGG'), @event) {
	if(entity_loc(@event['id'])['world'] == 'outworld') {
		@mobs = array(
			51: 'SKELETON', 
			52: 'SPIDER', 
			54: 'ZOMBIE', 
			55: 'SLIME', 
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
		@loc['x'] = floor(@loc['x']) + 0.5;
		@loc['z'] = floor(@loc['z']) + 0.5;
		@entity = spawn_mob(@mob, 1, @loc)[0];
		play_sound(@loc, array('sound': 'CHICKEN_EGG_POP', 'pitch': 0.5));
		if(function_exists('play_effect')) {
			play_effect(@loc, 'COLOURED_DUST', array('particleCount': 15, 'offsetX': 1, 'offsetY': 1, 'offsetZ': 1));
		}
		set_entity_persistence(@entity, false);
	}
}

bind('player_interact_entity', null, array('clicked': '/(HORSE|WOLF)/'), @event) {
	if(entity_loc(@event['id'])['world'] == 'outworld') {
		set_entity_persistence(@event['id'], true);
	}
}

bind('creature_spawn', null, array('type': 'CHICKEN', 'reason': 'EGG'), @event) {
	if(@event['location']['world'] == 'outworld') {
		cancel();
	}
}