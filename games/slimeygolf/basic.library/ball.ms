proc _place_ball(@mobtype, @loc, @ball, @course) {
	@ball['id'] = spawn_entity('ARMOR_STAND', 1, @loc, closure(@armorStand){
		set_entity_velocity(@armorStand, array(0, 0, 0));
		set_entity_spec(@armorStand, associative_array(visible: false, small: true));
		add_scoreboard_tag(@armorStand, 'remove');
	})[0];
	@loc['y'] += 0.01;
	@ball['slime'] = spawn_entity(@mobtype, 1, @loc, closure(@slime) {
		set_entity_spec(@slime, array(size: 1));
		set_entity_ai(@slime, false);
		add_scoreboard_tag(@slime, 'remove');
	})[0];
	@ball['velocity'] = array(x: 0, y: 0, z: 0);

	if(function_exists('set_entity_size')) {
		set_entity_size(@ball['id'], 0.5, 0.5);
	}
	spawn_particle(@loc, array(particle: 'SLIME', count: 20, xoffset: 0.6, zoffset: 0.6));
	play_sound(@loc, array(sound: 'ENTITY_SLIME_JUMP', volume: 0.5));
	set_timeout(1, closure(){
		set_mob_effect(@ball['slime'], 'resistance', 4, -1, true, false);
	});
}

proc _ball_exists(@id) {
	return(@id && entity_exists(@id));
}

proc _remove_ball(@ball, @course) {
	try {
		entity_remove(@ball['slime']);
		entity_remove(@ball['id']);
	} catch(Exception @ex) {
		// does not exist
	}
}

proc _get_block_below(@loc, @v) {
	@block = get_block(@loc);
	if(@block !== 'AIR') {
		if(@block === 'BLACK_WOOL') {
			play_sound(@loc, array('sound': 'BLOCK_WOODEN_BUTTON_CLICK_ON', 'pitch': 0.5));
		}
		return(@block);
	}

	@rx = @loc['x'] - floor(@loc['x']);
	@dirx = '';
	if(@rx < 0.21) {
		@dirx = 'west';
	} else if(@rx > 0.79) {
		@dirx = 'east';
	}
	@blockX = if(@dirx, get_block(location_shift(@loc, @dirx)), @block);
	if(@blockX !== 'AIR') {
		// adjust ball velocity towards edge if hanging off
		if(@rx < 0.21) {
			@v['x'] += @rx * 0.2;
		} else if(@rx > 0.79) {
			@v['x'] -= (1.0 - @rx) * 0.2;
		}
	}

	@rz = @loc['z'] - floor(@loc['z']);
	@dirz = '';
	if(@rz < 0.21) {
		@dirz = 'north';
	} else if(@rz > 0.79) {
		@dirz = 'south';
	}
	@blockZ = if(@dirz, get_block(location_shift(@loc, @dirz)), @block);
	if(@blockZ !== 'AIR') {
		if(@rz < 0.21) {
			@v['z'] += @rz * 0.2;
		} else if(@rz > 0.79) {
			@v['z'] -= (1.0 - @rz) * 0.2;
		}
	}
	if(@blockX !== 'AIR') {
		return(@blockX);
	}
	if(@blockZ !== 'AIR') {
		return(@blockZ);
	}
	return(null);
}
