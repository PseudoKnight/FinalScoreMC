proc _place_ball(@mobtype, @loc, @ball, @course) {
	@loc = @loc[];
	@loc['x'] += 0.5;
	@loc['y'] -= 1;
	@loc['z'] += 0.5;

	@ball['id'] = spawn_entity('ARMOR_STAND', 1, @loc)[0];
	@loc['y'] += 2;
	@ball['slime'] = spawn_mob(@mobtype.':1', 1, @loc)[0];
	@ball['velocity'] = array('x': 0, 'y': 0, 'z': 0);

	set_entity_ai(@ball['slime'], false);
	set_entity_velocity(@ball['id'], array(0, 0, 0));
	set_entity_spec(@ball['id'], associative_array('visible': false, 'small': true));
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
	@block = get_block_at(@loc);
	if(@block != '0:0') {
		if(@block == '35:15') {
			play_sound(@loc, array('sound': 'WOOD_CLICK', 'pitch': 0.5));
		}
		return(@block);
	}
	# adjust ball velocity towards center of air block, if above black wool.
	if(get_block_at(location_shift(@loc, 'down')) == '35:15') {
		@center = @loc[];
		@center['x'] = floor(@center['x']) + 0.5;
		@center['z'] = floor(@center['z']) + 0.5;
		@dist = _distance(@center, @loc);
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
	if(@dirx && get_block_at(_relative(@loc, @dirx)) != '0:0') {
		return(@block);
	} else {
		@rz = @loc['z'] - floor(@loc['z']);
		@dirz = '';
		if(@rz < 0.21) {
			@dirz = 'south';
		} else if(@rz > 0.79) {
			@dirz = 'north';
		}
		if(@dirz && get_block_at(_relative(@loc, @dirz)) != '0:0') {
			return(@block);
		}
	}
	return(null);
}
