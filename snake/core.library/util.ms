proc _snake_valid_location(@region, @padding = 0) {
	@i = 0;
	while(@i < 20) {
		@i++;
		@coords = sk_region_info(@region, 'custom')[0];
		@x = 0;
		@y = 0;
		@z = 0;
		if(@padding == 0 || @coords[1][0] == @coords[0][0]) {
			@x = @coords[1][0] + rand(1 + @coords[0][0] - @coords[1][0]);
		} else {
			@x = (@coords[1][0] + @padding) + rand(1 + @coords[0][0] - @coords[1][0] - (@padding * 2));
		}
		if(@padding == 0 || @coords[1][1] == @coords[0][1]) {
			@y = @coords[1][1] + rand(1 + @coords[0][1] - @coords[1][1]);
		} else {
			@y = (@coords[1][1] + @padding) + rand(1 + @coords[0][1] - @coords[1][1] - (@padding * 2));
		}
		if(@padding == 0 || @coords[1][2] == @coords[0][2]) {
			@z = @coords[1][2] + rand(1 + @coords[0][2] - @coords[1][2]);
		} else {
			@z = (@coords[1][2] + @padding) + rand(1 + @coords[0][2] - @coords[1][2] - (@padding * 2));
		}
		if(get_block_at(@x, @y, @z, 'custom') == '0:0') {
			return(array(@x, @y, @z, 'custom'));
		}
	}
	return(null);
}

proc _snake_direction_of(@loc, @block, @not) {
	foreach(@dir in array('down', 'up', 'north', 'south', 'east', 'west')) {
		if((!@not || @not != @dir) && get_block_at(_relative(@loc, @dir)) == @block) {
			return(@dir);
		}
	}
	return(null);
}

proc _snake_safe_dir(@loc, @direction, @last) {
	foreach(@dir in array(@last, 'down', 'up', 'north', 'south', 'east', 'west')) {
		if(@dir != @direction && _snake_safe_block(_relative(@loc, @dir))) {
			return(@dir);
		}
	}
	return(@direction);
}

proc _snake_safe_block(@loc, @recurse = true, @avoid = array()) {
	@id = split(':', get_block_at(@loc))[0];
	if(@id == '159' || @id == '155' || @id == '166' || @id == '35' || array_contains(@avoid, @id)) {
		return(false);
	}
	if(!@recurse) {
		return(true);
	}
	foreach(@dir in array('down', 'up', 'north', 'south', 'east', 'west')) {
		if(_snake_safe_block(_relative(@loc, @dir), false)) {
			return(true);
		}
	}
	return(false);
}

proc _snake_opposite_dir(@dir) {
	switch(@dir) {
		case 'up':
			return('down');
		case 'down':
			return('up');
		case 'north':
			return('south');
		case 'south':
			return('north');
		case 'east':
			return('west');
		case 'west':
			return('east');
	}
	return(null);
}

proc _snake_change_speed(@value, @game) {
	@speeds = array('slow', 'normal', 'fast', 'superfast');
	@current = array_index(@speeds, @game['speed']);
	@new = @current + @value;
	if(@new > -1 && array_index_exists(@speeds, @new)) {
		@game['speed'] = @speeds[@new];
		clear_task(@game['interval']);
		_snake_start_task(@game);
		return(true);
	}
	return(false);
}

proc _snake_play_song() {
	@loc = sk_region_info('snake', 'custom', 0)[1];
	@loc[0] += 25;
	@loc[1] += 15;
	@loc[2] += 25;
	play_effect(@loc, 'RECORD_PLAY', array('id': rand(2257, 2266), 'radius': 40));
}

proc _snake_stop_song() {
	@loc = sk_region_info('snake', 'custom', 0)[1];
	@loc[0] += 25;
	@loc[1] += 15;
	@loc[2] += 25;
	play_effect(@loc, 'RECORD_PLAY', array('id': 0, 'radius': 40));
}
