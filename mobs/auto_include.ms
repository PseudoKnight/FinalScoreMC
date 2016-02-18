proc _spawn_mob(@mob, @qty, @loc, @owner = 'Notch') {
	@mob = _get_mob(@mob);
	if(is_null(@mob)) {
		return(array());
	}
	@mobs = spawn_mob(@mob['type'], @qty, @loc);
	foreach(@i: @m in @mobs) {
		try(
			if(array_index_exists(@mob, 'name'), set_mob_name(@m, @mob['name']));
			if(array_index_exists(@mob, 'gear'), set_mob_equipment(@m, @mob['gear']));
			if(array_index_exists(@mob, 'droprate'), set_equipment_droprates(@m, @mob['droprate']));
			if(array_index_exists(@mob, 'tags'), set_entity_spec(@m, @mob['tags']));
			if(array_index_exists(@mob, 'tame'), tame_mob(@owner, @m));
			if(array_index_exists(@mob, 'age'), set_mob_age(@m, @mob['age']));
			if(array_index_exists(@mob, 'health')) {
				set_max_health(@m, @mob['health']);
				set_entity_health(@m, 100);
			}
			if(array_index_exists(@mob, 'rider')) {
				if(@mob['rider'] === 'owner') {
					set_entity_rider(@m, puuid(@owner));
				} else {
					@rider = _spawn_mob(@mob['rider'], 1, @loc)[0];
					set_entity_rider(@m, @rider);
				}
			}
			if(array_index_exists(@mob, 'onfire')) {
				set_entity_onfire(@m, @mob['onfire']);
			}
			set_entity_persistence(@m, true);
		, # failed to spawn
			array_remove(@mobs, @i);
			console('Failed to spawn mob @ '.@loc);
		);
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
			foreach(@i: @m in @mobs) {
				try(
					if(get_entity_health(@m) > 0) {
						try(
							if(@mob['explode'][0] <= 3) {
								set_mob_name(@display[@i], color('yellow').@mob['explode'][0]);
							} else {
								set_mob_name(@display[@i], @mob['explode'][0]);
							}
							if(@mob['explode'][0] == 0) {
								try(entity_remove(@display[@i]));
								explosion(entity_loc(@m), @mob['explode'][1], true);
								damage_entity(@m, 20);
							} else {
								play_sound(entity_loc(@m), array('sound': 'NOTE_STICKS', 'pitch': 2, 'volume': 1));
							}
						, # display entity doesn't exist
							damage_entity(@m, 20);
						);
					} else {
						try(entity_remove(@display[@i]));
					}
				);
			}
			if(@mob['explode'][0] == 0) {
				clear_task();
			}
		})
	}
	if(array_index_exists(@mob, 'effects')) {
		queue_push(closure(){
			foreach(@m in @mobs) {
				foreach(@e in @mob['effects']) {
					try(set_mob_effect(@m, @e['id'], @e['strength'], @e['seconds'], true));
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
