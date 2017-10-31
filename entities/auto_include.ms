proc _spawn_mob(@mob, @loc, @owner, @teammates) {
	if(!is_array(@mob)) {
		@mob = _get_mob(@mob);
	}
	if(is_null(@mob)) {
		return(null);
	}
	bind(creature_spawn, array('id': 'customspawn'), array('reason': 'CUSTOM'), @event, @mob, @loc, @owner, @teammates) {
		@m = @event['id'];
		set_entity_persistence(@m, true);
		foreach(@key: @value in @mob) {
			switch(@key) {
				case 'type':
					continue();
					
				case 'name':
					set_mob_name(@m, @value);
					
				case 'gear':
					set_mob_equipment(@m, @value);
					
				case 'droprate':
					set_equipment_droprates(@m, @value);
				
				case 'tags':
					set_entity_spec(@m, @value);
				
				case 'attributes':
					foreach(@k: @v in @value) {
						set_attribute(@m, @k, @v);
					}
				
				case 'tame':
					tame_mob(@owner, @m);
					
				case 'age':
					set_mob_age(@m, @value);
				
				case 'ai':
					set_entity_ai(@m, @value);
					
				case 'lifetime':
					set_timeout(@value * 1000, closure(){
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
					
				case 'health':
					set_max_health(@m, @value);
					set_entity_health(@m, 100);
					
				case 'rider':
					if(@value === 'owner') {
						set_entity_rider(@m, puuid(@owner));
					} else {
						set_timeout(50, closure() {
							@rider = _spawn_mob(@value, @loc);
							set_entity_rider(@m, @rider);
						});
					}
				
				case 'onfire':
					set_entity_onfire(@m, @value);
				
				case 'glowing':
					set_entity_glowing(@m, @value);
					
				case 'explode':
					set_timeout(50, closure(){
						@display = spawn_entity('ARMOR_STAND', 1, @loc)[0];
						set_entity_spec(@display, array('small': true, 'visible': false));
						set_mob_name(@display, @mob['explode'][0]);
						set_name_visible(@display, true);
						set_entity_rider(@m, @display);
						set_interval(1000, closure(){
							@mob['explode'][0] -= 1;
							@cleanup = false;
							try {
								if(get_entity_health(@m) > 0) {
									if(@mob['explode'][0] <= 3) {
										set_mob_name(@display, color('yellow').@mob['explode'][0]);
									} else {
										set_mob_name(@display, @mob['explode'][0]);
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
							if(@cleanup) {
								try(entity_remove(@display));
								try(damage_entity(@m, 50));
								clear_task();
							}
						});
					});
					
				case 'targetnear':
					@range = @mob['targetnear'];
					@projectile = '';
					switch(to_upper(@mob['type'])) {
						case 'SNOWGOLEM':
							@projectile = 'SNOWBALL';
						case 'CHICKEN':
							@projectile = 'EGG';
					}
					if(@projectile) {
						set_interval(1500, closure() {
							try {
								if(get_entity_health(@m) == 0.0) {
									clear_task();
								} else {
									@loc1 = entity_loc(@m);
									foreach(@p in players_in_radius(@loc1, @range)) {
										if(!array_contains(@teammates, @p)) {
											@loc2 = ploc(@p);
											@loc2['y'] += 2;
											@loc1['yaw'] = get_yaw(@loc1, @loc2);
											@loc1['pitch'] = get_pitch(@loc1, @loc2);
											set_entity_loc(@m, @loc1);
											shoot_projectile(@m, @projectile, @p);
											break();
										}
									}
								}
							} catch(BadEntityException @ex) {
								clear_task();
							}
						});
					} else {
						set_timeout(50, closure(){
							foreach(@p in players_in_radius(entity_loc(@m), @range)) {
								if(!array_contains(@teammates, @p)) {
									damage_entity(@m, 0, puuid(@p));
									break();
								}
							}
						});
					}
					
				case 'effects':
					queue_push(closure(){
						try {
							foreach(@e in @mob['effects']) {
								set_mob_effect(@m, @e['id'], @e['strength'], @e['seconds'], true);
							}
						} catch(BadEntityException @ex) {
							// mob is gone for some reason
						}
					})
			}
		}
	}
	@m = spawn_mob(@mob['type'], 1, @loc)[0];
	unbind('customspawn');
	return(@m);
}

proc _get_mob(@mob = null) {
	@mobTypes = import('mobs');
	if(is_null(@mobTypes)) {
		@mobTypes = get_value('mobs');
		if(is_null(@mobTypes)) {
			@mobTypes = reflect_pull('enum', 'Mobs');
			store_value('mobs', @mobTypes);
		}
		export('mobs', @mobTypes);
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
