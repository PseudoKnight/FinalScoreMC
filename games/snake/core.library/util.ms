proc _is_snake_tail(@block) {
	@match = reg_match('^([A-Z_]+)_(TERRACOTTA|CONCRETE)$', @block);
	return(@match && @match[1] != 'BLACK');
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
		@loc = array(@x, @y, @z, 'custom');
		if(get_block(@loc) === 'AIR') {
			return(@loc);
		}
	}
	return(null);
}

proc _snake_direction_of(@loc, @block) {
	foreach(@dir in array('down', 'up', 'north', 'south', 'east', 'west')) {
		if(get_block(location_shift(@loc, @dir)) == @block) {
			return(@dir);
		}
	}
	return(null);
}

proc _snake_dir_of_surface(@loc, @notThisDir) {
	foreach(@dir in array('down', 'up', 'north', 'south', 'east', 'west')) {
		if(@dir != @notThisDir) {
			@l = location_shift(@loc, @dir);
			if(array_size(sk_regions_at(@l)) > 1) {
				return(@dir);
			}
		}
	}
}

proc _snake_safe_dir(@snake) {
	@loc = @snake['loc'];
	if(@snake['last-dir']) {
		@loc = location_shift(@loc, @snake['last-dir']);
		if(_snake_safe_block(get_block(@loc), @loc, @snake['last-dir'])) {
			return(@snake['last-dir']);
		}
	}
	@directions = _snake_turn_directions(@snake);
	if(is_array(@directions)) {
		foreach(@dir in @directions) {
			@loc = location_shift(@snake['loc'], @dir);
			if(@dir !== @snake['last-dir'] && _snake_safe_block(get_block(@loc), @loc, @dir)) {
				return(@dir);
			}
		}
	}
	return(@snake['dir']);
}

proc _snake_safe_path(@snake, @missiles) {
	@dir = @snake['dir'];
	@loc = location_shift(@snake['loc'], @dir);
	if(!_snake_safe_block(get_block(@loc), @loc, @dir)) {
		return(false);
	}
	foreach(@missile in @missiles) {
		if(@missile['loc'][0] == @loc[0]
		|| @missile['loc'][1] == @loc[1]
		|| @missile['loc'][2] == @loc[2]) {
			return(false);
		}
	}
	@directions = _snake_turn_directions(@snake);
	@block = get_block(location_shift(@loc, @dir));
	if((_snake_safe_block(@block)
	&& (@block === 'SEA_LANTERN' || _snake_safe_block(get_block(location_shift(@loc, @dir, 2)))))
	|| _snake_safe_block(get_block(location_shift(@loc, @directions[0])))
	|| _snake_safe_block(get_block(location_shift(@loc, @directions[1])))) {
		return(true);
	}
	return(false);
}

proc _snake_safe_block(@block, @loc, @dir) {
	// special case for lasers, as the powerup block is the same as the deadly laser
	if(@loc && @block === 'RED_STAINED_GLASS') {
		@game = import('snake');
		foreach(@powerup in @game['powerups']){
			if(_snake_loc_equals(@powerup['loc'], @loc)) {
				return(true);
			}
		}
		return(false);
	}
	if(@loc && @dir && @block === 'SEA_LANTERN') {
		return(_snake_safe_block(get_block(location_shift(@loc, _snake_dir_of_surface(@loc, _snake_opposite_dir(@dir))))));
	}
	return(@block === 'AIR' || @block === 'SEA_LANTERN' || _snake_get_powerup_from(@block));
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

proc _snake_clean_surfaces(@game) {
	@region = @game['region'];
	@count = @game['surfaces'];
	@walls = @game['mode'] === 'capture';
	while(@count) {
		@area = sk_region_info(@region.@count, 'custom', 0);
		@minX = min(@area[1][0], @area[0][0]);
		@maxX = max(@area[1][0], @area[0][0]);
		@minY = min(@area[1][1], @area[0][1]);
		@maxY = max(@area[1][1], @area[0][1]);
		@minZ = min(@area[1][2], @area[0][2]);
		@maxZ = max(@area[1][2], @area[0][2]);
		if(@minX == @maxX) {
			for(@x = @minX, @x <= @maxX, @x++) {
				for(@y = @minY, @y <= @maxY, @y += 2) {
					queue_push(closure(){
						for(@z = @minZ, @z <= @maxZ, @z++) {
							set_block(array(@x, @y, @z, 'custom'), 'AIR', false);
							spawn_particle(array(@x, @y, @z, 'custom'), array(particle: 'CRIT', speed: 0.01, force: true));
							if(@y + 1 <= @maxY) {
								set_block(array(@x, @y + 1, @z, 'custom'), 'AIR', false);
								spawn_particle(array(@x, @y + 1, @z, 'custom'), array(particle: 'CRIT', speed: 0.01, force: true));
							}
						}
					}, 'snake_cleanup');
				}
			}
		} else {
			for(@z = @minZ, @z <= @maxZ, @z++) {
				for(@y = @minY, @y <= @maxY, @y += 2) {
					queue_push(closure(){
						@halfX = integer((@maxX - @minX) / 2 + @minX);
						@oneQuarterX = integer((@maxX - @minX) / 4) + @minX;
						@threeQuarterX = integer((@maxX - @minX) * 3 / 4 + @minX);
						for(@x = @minX, @x <= @maxX, @x++) {
							if(@walls && @x == @halfX) {
								set_block(array(@x, @y, @z, 'custom'), 'WHITE_TERRACOTTA', false);
								if(@y + 1 <= @maxY) {
									set_block(array(@x, @y + 1, @z, 'custom'), 'WHITE_TERRACOTTA', false);
								}
							} else if(@walls && (@x == @oneQuarterX || @x == @threeQuarterX)) {
								set_block(array(@x, @y, @z, 'custom'), 'LIGHT_GRAY_TERRACOTTA', false);
								if(@y + 1 <= @maxY) {
									set_block(array(@x, @y + 1, @z, 'custom'), 'LIGHT_GRAY_TERRACOTTA', false);
								}
							} else {
								set_block(array(@x, @y, @z, 'custom'), 'AIR', false);
								spawn_particle(array(@x, @y, @z, 'custom'), array(particle: 'CRIT', speed: 0.01, force: true));
								if(@y + 1 <= @maxY) {
									set_block(array(@x, @y + 1, @z, 'custom'), 'AIR', false);
									spawn_particle(array(@x, @y + 1, @z, 'custom'), array(particle: 'CRIT', speed: 0.01, force: true));
								}
							}
						}
					}, 'snake_cleanup');
				}
			}
		}
		@count--;
	}
}
proc _snake_spawn_flag(@team, @game) {
	@region = @game['region'].(@team * 2 + 2);
	@loc = _snake_valid_location(@region, 13);
	if(@loc) {
		set_block(@loc, if(@team, 'RED_GLAZED_TERRACOTTA', 'CYAN_GLAZED_TERRACOTTA'), false);
	}
	@game['flags'][@team] = @loc;
}

proc _snake_loc_equals(@a, @b) {
	return(is_array(@a) && is_array(@b) && @a[0] == @b[0] && @a[1] == @b[1] && @a[2] == @b[2]);
}

proc _snake_shift(@loc, @dir) {
	@loc = @loc[];
	switch(@dir) {
		case 'down':
			@loc[1]--;
		case 'up':
			@loc[1]++;
		case 'north':
			@loc[2]--;
		case 'south':
			@loc[2]++;
		case 'west':
			@loc[0]--;
		case 'east':
			@loc[0]++;
	}
	return(@loc);
}
