proc _is_snake_tail(@block) {
	@id = split(':', @block)[0];
	return(@id == '159' || @id == '251');
}

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

proc _snake_safe_dir(@snake) {
	@loc = _relative(@snake['loc'], @snake['last-dir']);
	if(_snake_safe_block(get_block_at(@loc), @loc)) {
		return(@snake['last-dir']);
	}
	@turn = _snake_turn(@snake['top'], @snake['dir']);
	foreach(@t in @turn) {
		@loc = _relative(@snake['loc'], @t);
		if(@t != @snake['last-dir'] && _snake_safe_block(get_block_at(@loc), @loc)) {
			return(@t);
		}
	}
	return(@snake['dir']);
}

proc _snake_safe_path(@loc, @top, @dir, @missiles) {
	@loc = _relative(@loc, @dir);
	if(!_snake_safe_block(get_block_at(@loc), @loc)) {
		return(false);
	}
	foreach(@missile in @missiles) {
		if(@missile['loc'][0] == @loc[0]
		|| @missile['loc'][1] == @loc[1]
		|| @missile['loc'][2] == @loc[2]) {
			return(false);
		}
	}
	@turn = _snake_turn(@top, @dir);
	@block = get_block_at(_relative(@loc, @dir));
	if((_snake_safe_block(@block)
	&& (@block == '169:0' || _snake_safe_block(get_block_at(_relative(@loc, @dir, 2)))))
	|| _snake_safe_block(get_block_at(_relative(@loc, @turn[0])))
	|| _snake_safe_block(get_block_at(_relative(@loc, @turn[1])))) {
		return(true);
	}
	return(false);
}

proc _snake_safe_block(@block, @loc) {
	// special case for lasers, as the powerup block is the same as the deadly laser
	if(@loc && @block == '95:14') {
		@game = import('snake');
		foreach(@powerup in @game['powerups']){
			if(@powerup['loc'][0] == @loc[0]
			&& @powerup['loc'][1] == @loc[1]
			&& @powerup['loc'][2] == @loc[2]) {
				return(true);
			}
		}
		return(false);
	}
	return(@block == '0:0' || @block == '169:0' || _snake_get_powerup_from(@block));
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

proc _snake_play_song(@game) {
	@songs = array('security_robots', 'so_long', 'neon_transit', 'flying_me_softly', 'epic_fall', 'zigzag');
	@song = @songs[rand(array_size(@songs))];
	foreach(@p in all_players()) {
		if(array_contains(sk_current_regions(@p), 'snake_'.@game['arena'])) {
			action_msg(@p, color('aqua').@song.' by Alexandr Zhelanov');
		}
	}
	runas('~console', '/jukebox music @snake http://finalscoremc.com/media/'.@song.'.mp3 {volume:30,fadeDuration:3}');
}

proc _snake_stop_song() {
	runas('~console', '/jukebox stop music @snake {fadeDuration:6}');
}
