/*
	Spawns an entity and applies specific attributes to it.
	@entity : REQUIRED : The entity type, saved entity type, or array defining a custom entity that's not saved.
	@loc : REQUIRED : The spawning location.
	@owner : The owner if the entity is tameable, also rider if the "rider" key is set to exactly "owner".
	@teammates : Players to ignore if the entity is doing custom targeting.
	@consumer : An additional closure to run on the entity during spawning.
*/
proc _spawn_entity(@entity, @loc, @owner, @teammates, @consumer) {
	if(!is_array(@entity)) {
		@entity = _get_entity(@entity);
	}
	if(is_null(@entity)) {
		return(null);
	}
	@modify = closure(@e){
		if(is_entity_living(@e)) {
			set_entity_persistence(@e, true);
		}
		if(array_index_exists(@entity, 'name')) {
			set_mob_name(@e, @entity['name']);
		}
		if(array_index_exists(@entity, 'gear')) {
			set_mob_equipment(@e, @entity['gear']);
		}
		if(array_index_exists(@entity, 'droprate')) {
			set_equipment_droprates(@e, @entity['droprate']);
		}
		if(array_index_exists(@entity, 'tags')) {
			set_entity_spec(@e, @entity['tags']);
		}
		if(array_index_exists(@entity, 'attributes')) {
			foreach(@k: @v in @entity['attributes']) {
				set_entity_attribute_base(@e, @k, @v);
			}
		}
		if(array_index_exists(@entity, 'tame')) {
			set_mob_owner(@e, @owner);
		}
		if(array_index_exists(@entity, 'age')) {
			set_mob_age(@e, @entity['age']);
		}
		if(array_index_exists(@entity, 'ai')) {
			set_entity_ai(@e, @entity['ai']);
		}
		if(array_index_exists(@entity, 'silent')) {
			set_entity_silent(@e, @entity['silent']);
		}
		if(array_index_exists(@entity, 'gravity')) {
			set_entity_gravity(@e, @entity['gravity']);
		}
		if(array_index_exists(@entity, 'lifetime')) {
			set_timeout(integer(@entity['lifetime'] * 1000), closure(){
				try {
					@loc = entity_loc(@e);
					@loc['y'] += 1;
					spawn_particle(@loc, array('particle': 'CLOUD', 'speed': 0, 'count': 10, 'xoffset': 0.4, 'zoffset': 0.4, 'yoffset': 0.4));
					entity_remove(@e);
				} catch(BadEntityException @ex) {
					// already dead
				}
			});
		}
		if(array_index_exists(@entity, 'health')) {
			set_max_health(@e, @entity['health']);
			set_entity_health(@e, 100);
		}
		if(array_index_exists(@entity, 'invulnerable')) {
			set_entity_invulnerable(@e, @entity['invulnerable']);
		}
		if(array_index_exists(@entity, 'rider')) {
			if(@entity['rider'] === 'owner') {
				set_entity_rider(@e, puuid(@owner));
			} else {
				set_timeout(50, closure() {
					@rider = _spawn_entity(@entity['rider'], @loc);
					set_entity_rider(@e, @rider);
				});
			}
		}
		if(array_index_exists(@entity, 'onfire')) {
			set_entity_onfire(@e, @entity['onfire']);
		}
		if(array_index_exists(@entity, 'glowing')) {
			set_entity_glowing(@e, @entity['glowing']);
		}
		if(array_index_exists(@entity, 'explode')) {
			@countdown = array(@entity['explode'][0]);
			@size = @entity['explode'][1];
			set_timeout(50, closure(){
				@display = spawn_entity('ARMOR_STAND', 1, @loc)[0];
				set_entity_spec(@display, array('small': true, 'visible': false));
				set_mob_name(@display, @countdown[0]);
				set_name_visible(@display, true);
				set_entity_rider(@e, @display);
				set_interval(1000, closure(){
					@countdown[0] -= 1;
					@cleanup = false;
					try {
						if(get_entity_health(@e) > 0) {
							if(@countdown[0] <= 3) {
								set_mob_name(@display, color('yellow').@countdown[0]);
							} else {
								set_mob_name(@display, @countdown[0]);
							}
							if(@countdown[0] == 0) {
								@cleanup = true;
								explosion(entity_loc(@e), @size, true);
							} else {
								play_sound(entity_loc(@e), array('sound': 'BLOCK_NOTE_BLOCK_HAT', 'pitch': 2, 'volume': 1));
							}
						}
					} catch(BadEntityException @ex) {
						@cleanup = true;
					}
					if(@cleanup) {
						try(entity_remove(@display));
						try(damage_entity(@e, 50));
						clear_task();
					}
				});
			});
		}
		if(array_index_exists(@entity, 'targetnear')) {
			@range = @entity['targetnear'];
			@projectile = '';
			switch(to_upper(@entity['type'])) {
				case 'SNOWMAN':
					@projectile = 'SNOWBALL';
				case 'CHICKEN':
					@projectile = 'EGG';
			}
			if(@projectile) {
				set_interval(1500, closure() {
					try {
						if(get_entity_health(@e) == 0.0) {
							clear_task();
						} else {
							@loc1 = entity_loc(@e);
							foreach(@p in players_in_radius(@loc1, @range)) {
								if(!array_contains(@teammates, @p)) {
									@loc2 = ploc(@p);
									@loc2['y'] += 2;
									@loc1['yaw'] = get_yaw(@loc1, @loc2);
									@loc1['pitch'] = get_pitch(@loc1, @loc2);
									set_entity_loc(@e, @loc1);
									shoot_projectile(@e, @projectile, @p);
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
					foreach(@p in players_in_radius(entity_loc(@e), @range)) {
						if(!array_contains(@teammates, @p)) {
							damage_entity(@e, 0, puuid(@p));
							break();
						}
					}
				});
			}
		}
		if(array_index_exists(@entity, 'effects')) {
			try {
				foreach(@name: @effect in @entity['effects']) {
					if(array_index_exists(@effect, 'id')) {
						set_mob_effect(@e, @effect['id'], @effect['strength'], @effect['seconds'], true);
					} else {
						set_mob_effect(@e, @name, @effect['strength'], @effect['seconds'], true);
					}
				}
			} catch(BadEntityException @ex) {
				// mob is gone for some reason
			}
		}
		if(array_index_exists(@entity, 'scripts')) {
			foreach(@s in @entity['scripts']) {
				try(include('custom/script.library/'.@s.'.ms'));
			}
		}
		if(is_closure(@consumer)) {
			execute(@e, @consumer);
		}
	}
	return(spawn_entity(@entity['type'], 1, @loc, @modify)[0]);
}

/*
	Gets a vanilla entity type or saved custom entity array by the given name. (see /entity command)
*/
proc _get_entity(@type = null) {
	@entityTypes = import('entityTypes');
	if(is_null(@entityTypes)) {
		// cache entity types
		@entityTypes = reflect_pull('enum', 'EntityType');
		export('entityTypes', @entityTypes);
	}
	if(is_null(@type)) {
		return(array_get_rand(@entityTypes));
	}
	if(array_contains_ic(@entityTypes, @type)) {
		return(array('type': @type));
	}
	@custom = _get_custom_entities();
	return(array_get(@custom, @type, null));
}

/*
	Gets all custom entity definitions
*/
proc _get_custom_entities() {
	@custom = import('customEntities');
	if(is_null(@custom)) {
		@custom = yml_decode(read('custom.yml'));
		export('customEntities', @custom);
	}
	return(@custom);
}

/*
	Removes entities that are inside a region.

	@region: The WorldGuard region name.
	@types: Array of entity types to remove. Defaults to all but excluded types. Can override excluded types.
	@world: The world to remove the entities from. Defaults to 'custom'.
	@removeProtected: If true, will also remove excluded entity types. Defaults to false.
	@excludeTypes: An array of excluded entity types. (visible armor stands are also protected)

	Returns: Number of entities removed.
*/
proc _remove_region_entities(
	@region,
	@types = array(),
	@world = 'custom',
	@removeProtected = false,
	@excludeTypes = array('PLAYER', 'COMPLEX_PART', 'GLOW_ITEM_FRAME', 'ITEM_FRAME', 'PAINTING', 'UNKNOWN')
) {
	if(!sk_region_exists(@world, @region)) {
		console('Can\'t remove entities because region doesn\'t exist: '.@region, false);
		return(0);
	}
	@count = 0;
	foreach(@entity in all_entities(@world)) {
		@type = entity_type(@entity);
		if(!@types && !array_contains(@excludeTypes, @type) || array_contains(@types, @type)) {
			@loc = entity_loc(@entity);
			if(!array_contains(sk_regions_at(@loc), @region)) {
				continue();
			}
			if(@type == 'ARMOR_STAND' && !@removeProtected) {
				if(entity_spec(@entity)['visible']) {
					continue();
				}
			}
			try {
				entity_remove(@entity);
				@count++;
			} catch(BadEntityException @ex) {
				console('Entity not found when trying to remove from region.', false);
				console('Region: '.@region.', EntityID: '.@entity, false);
			}
		}
	}
	return(@count);
}
