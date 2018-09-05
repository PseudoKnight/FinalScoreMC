proc _place_ball(@mobtype, @loc, @ball, @course) {
	@loc = @loc[];
	@loc['x'] += 0.5;
	@loc['y'] -= 1;
	@loc['z'] += 0.5;

	@ball['id'] = spawn_entity('ARMOR_STAND', 1, @loc)[0];
	@loc['y'] += 2;
	@ball['slime'] = spawn_entity(@mobtype, 1, @loc, closure(@id, set_entity_spec(@id, array('size': 1))))[0];
	@ball['velocity'] = array('x': 0, 'y': 0, 'z': 0);

	set_entity_ai(@ball['slime'], false);
	set_entity_velocity(@ball['id'], array(0, 0, 0));
	set_entity_spec(@ball['id'], associative_array('visible': false, 'small': true));
	if(function_exists('set_entity_size')) {
		set_entity_size(@ball['id'], 1.0, 1.0);
	}
	set_entity_loc(@ball['id'], @loc);
	set_timeout(50, closure(){
		set_mob_effect(@ball['slime'], 11, 4, 99999, true, false);
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
		// doesn't exist
	}
}

proc _get_block_below(@loc, @v) {
	@block = get_block(@loc);
	if(@block != 'AIR') {
		if(@block == 'BLACK_WOOL') {
			play_sound(@loc, array('sound': 'BLOCK_WOODEN_BUTTON_CLICK_ON', 'pitch': 0.5));
		}
		return(@block);
	}
	# adjust ball velocity towards center of air block, if above black wool.
	if(get_block(location_shift(@loc, 'down')) == 'BLACK_WOOL') {
		@center = @loc[];
		@center['x'] = floor(@center['x']) + 0.5;
		@center['z'] = floor(@center['z']) + 0.5;
		@dist = distance(@center, @loc);
		@v['x'] += ((@center['x'] - @loc['x']) / @dist) * 0.02;
		@v['z'] += ((@center['z'] - @loc['z']) / @dist) * 0.02;
	}

	# check closer if it's over the edge
	@rx = @loc['x'] - floor(@loc['x']);
	@dirx = '';
	if(@rx < 0.21) {
		@dirx = 'east';
	} else if(@rx > 0.79) {
		@dirx = 'west';
	}
	if(@dirx && get_block(location_shift(@loc, @dirx)) != 'AIR') {
		return(@block);
	} else {
		@rz = @loc['z'] - floor(@loc['z']);
		@dirz = '';
		if(@rz < 0.21) {
			@dirz = 'south';
		} else if(@rz > 0.79) {
			@dirz = 'north';
		}
		if(@dirz && get_block(location_shift(@loc, @dirz)) != 'AIR') {
			return(@block);
		}
	}
	return(null);
}
