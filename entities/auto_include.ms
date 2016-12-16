proc _spawn_mob(@mob, @qty, @loc, @args) {
	@mob = _get_mob(@mob);
	if(is_null(@mob)) {
		return(array());
	}
	@mobs = spawn_mob(@mob['type'], @qty, @loc);
	foreach(@i: @m in @mobs) {
		try {
			if(array_index_exists(@mob, 'name'), set_mob_name(@m, @mob['name']));
			if(array_index_exists(@mob, 'gear'), set_mob_equipment(@m, @mob['gear']));
			if(array_index_exists(@mob, 'droprate'), set_equipment_droprates(@m, @mob['droprate']));
			if(array_index_exists(@mob, 'tags'), set_entity_spec(@m, @mob['tags']));
			if(array_index_exists(@mob, 'tame'), tame_mob(@args, @m));
			if(array_index_exists(@mob, 'age'), set_mob_age(@m, @mob['age']));
			if(array_index_exists(@mob, 'ai'), set_entity_ai(@m, @mob['ai']));
			if(array_index_exists(@mob, 'lifetime')) {
				set_timeout(@mob['lifetime'] * 1000, closure(){
					try {
						@loc = entity_loc(@m);
						@loc['y'] += 1;
						play_sound(@loc, array('sound': 'ZOMBIE_INFECT'));
						play_effect(@loc, 'cloud', array('speed': 0, 'particleCount': 10, 'offsetX': 0.4, 'offsetZ': 0.4, 'offsetY': 0.4));
						entity_remove(@m);
					} catch(BadEntityException @ex) {
						// already dead
					}
				});
			}
			if(array_index_exists(@mob, 'health')) {
				set_max_health(@m, @mob['health']);
				set_entity_health(@m, 100);
			}
			if(array_index_exists(@mob, 'rider')) {
				if(@mob['rider'] === 'owner') {
					set_entity_rider(@m, puuid(@args));
				} else {
					@rider = _spawn_mob(@mob['rider'], 1, @loc)[0];
					set_entity_rider(@m, @rider);
				}
			}
			if(array_index_exists(@mob, 'onfire')) {
				set_entity_onfire(@m, @mob['onfire']);
			}
			set_entity_persistence(@m, true);
		} catch(BadEntityException @ex) {
			array_remove(@mobs, @i);
			console('Failed to spawn mob @ '.@loc, false);
		}
	}
	if(array_index_exists(@mob, 'explode')) {
		@display = array();
		foreach(@i: @m in @mobs) {
			@display[@i] = spawn_entity('ARMOR_STAND', 1, @loc)[0];
			set_entity_spec(@display[@i], array('small': true, 'visible': false));
			set_mob_name(@display[@i], @mob['explode'][0]);
			set_name_visible(@display[@i], true);
			set_entity_rider(@m, @display[@i]);
		}
		set_interval(1000, closure(){
			@mob['explode'][0] -= 1;
			@cleanup = false;
			foreach(@i: @m in @mobs) {
				try {
					if(get_entity_health(@m) > 0) {
						if(@mob['explode'][0] <= 3) {
							set_mob_name(@display[@i], color('yellow').@mob['explode'][0]);
						} else {
							set_mob_name(@display[@i], @mob['explode'][0]);
						}
						if(@mob['explode'][0] == 0) {
							@cleanup = true;
							explosion(entity_loc(@m), @mob['explode'][1], true);
						} else {
							play_sound(entity_loc(@m), array('sound': 'NOTE_STICKS', 'pitch': 2, 'volume': 1));
						}
					}
				} catch(BadEntityException @ex) {
					@cleanup = true;
				}
			}
			if(@cleanup) {
				try {
					entity_remove(@display[@i]);
				} catch(BadEntityException @ex) {
					// already removed
				}
				try {
					damage_entity(@m, 50);
				} catch(BadEntityException @ex) {
					// already removed
				}
				clear_task();
			}
		});
	}
	if(array_index_exists(@mob, 'targetnear')) {
		@range = @mob['targetnear'];
		@projectile = 'ARROW';
		switch(to_upper(@mob['type'])) {
			case 'SNOWGOLEM':
				@projectile = 'SNOWBALL';
			case 'CHICKEN':
				@projectile = 'EGG';
			case 'BLAZE':
				@projectile = 'SMALL_FIREBALL';
			case 'WITHER':
				@projectile = 'WITHER_SKULL';
			case 'GHAST':
				@projectile = 'FIREBALL';
			case 'ENDERDRAGON':
				@projectile = 'DRAGON_FIREBALL';
		}
		set_interval(1500, closure() {
			foreach(@i: @m in @mobs) {
				try {
					@loc1 = entity_loc(@m);
					foreach(@p in players_in_radius(@loc1, @range)) {
						if(!array_contains(@args, @p)) {
							@loc2 = ploc(@p);
							@loc2['y'] += 2;
							@loc1['yaw'] = get_yaw(@loc1, @loc2);
							@loc1['pitch'] = get_pitch(@loc1, @loc2);
							set_entity_loc(@m, @loc1);
							shoot_projectile(@m, @projectile, @p);
							break();
						}
					}
				} catch(BadEntityException @ex) {
					array_remove(@mobs, @i);
				}
			} else {
				clear_task();
			}
		});
	}
	if(array_index_exists(@mob, 'effects')) {
		queue_push(closure(){
			foreach(@m in @mobs) {
				try {
					foreach(@e in @mob['effects']) {
						set_mob_effect(@m, @e['id'], @e['strength'], @e['seconds'], true);
					}
				} catch(BadEntityException @ex) {
					// mob is gone for some reason
				}
			}
		})
	}
	return(@mobs)
}

proc _get_mob(@mob = null) {
	@mobTypes = import('mobs');
	if(is_null(@mobTypes)) {
		@mobTypes = get_value('mobs');
		if(is_null(@mobTypes)) {
			@mobTypes = reflect_pull('enum', 'Mobs');
			store_value('mobs', @mobTypes);
		}
	}
	if(is_null(@mob)) {
		@mob = @mobTypes[rand(array_size(@mobTypes))];
	} else {
		@mobType = split(':', @mob)[0];
		if(array_contains_ic(@mobTypes, @mobType)) {
			@mob = array('type': @mob);
		} else {
			@mob = get_value('mob', @mob);
		}
	}
	return(@mob);
}
