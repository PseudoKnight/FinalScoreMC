array_push(@pvp['binds'], @id.'railgun');
bind(player_interact, array('id': @id.'railgun'), array('item': 175, 'button': 'right'), @e, @id) {
	@pvp = import('pvp'.@id);
	if(!array_index_exists(@pvp['players'], player()) || pinfo(player(), 6) != @e['item']) {
		die();
	}

	@origin = _relative(ploc(), 'up', 2.3);
	@facing = pfacing(player());
	@facing[0] = @facing[0] + 90;
	@facing[1] = 0 - @facing[1];
	@x = cos(to_radians(@facing[0])) * cos(to_radians(@facing[1]));
	@y = sin(to_radians(@facing[1]));
	@z = sin(to_radians(@facing[0])) * cos(to_radians(@facing[1]));
	@n = 0;
	@loc = @origin[];

	# @entities = array()
	# @previouschunkx = 0
	# @previouschunkz = 0

	# SOMETHING LIKE THIS WOULD GET CORNER BLOCKS
	# @newblocklocx = floor(@newloc[x])
	# @newblocklocz = floor(@newloc[z])

	# if(@newblocklocx != @oldblocklocx
	# && @newblocklocz != @oldblocklocz) {
	  # @distx = @newblocklocx - @oldloc[x]
	  # @distz = @newblocklocz - @oldloc[z]
	  # if(@distx < @distz) {
		# if( _is_solid(@newloc[x], @oldloc[z])){
		  # break()
		# }
	  # } else {
		# if(_is_solid(@oldloc[x], @newloc[z])) {
		  # break()
		# }
	  # }
	# }

	proc _whitelisted_block(@loc) {
		@whitelisted = array(
			20, # glass
			63, # standing sign
			64, # door
			68, # wall sign
			70, # plate
			71, # door
			72, # plate
			85, # fence
			95, # glass
			96, # trapdoor
			101, # iron bars
			102, # glass
			107, # fence gate
			113, # fence
			147, # late
			148, # plate
			151, # daylight detector
			160, # glass
			167, # trapdoor
			176, # standing banner
			177, # wall banner
			178, # daylight detector
			183, # fence gate
			184, # fence gate
			185, # fence gate
			186, # fence gate
			187, # fence gate
			188, # fence
			189, # fence
			190, # fence
			191, # fence
			192, # fence
			193, # door
			194, # door
			195, # door
			196, # door
			197, # door
		);
		@id = split(get_block_at(@loc), ':')[0];
		if(array_contains(@whitelisted, @id)) {
			return(true);
		}
		return(false);
	}

	while(@n < 80) {
		@n++;
		@loc['x'] += @x;
		@loc['y'] += @y;
		@loc['z'] += @z;
		play_effect(@loc, array('flame', 'crit', 'cloud')[rand(3)], array('speed': 0, 'radius': 64));
		if(get_block_info(@loc, 'solid') && !_whitelisted_block(@loc)) {
			play_effect(@loc, 'lava_pop', array('particleCount': 8));
			break();
		} /*else {

			@currentchunkx = floor(@loc['x'] / 16)
			@currentchunkz = floor(@loc['z'] / 16)
			if(@currentchunkx != @previouschunkx
			|| @currentchunkz != @previouschunkz) {
				foreach(@e in all_entities('custom', @currentchunkx, @currentchunkz)) {
					if(is_entity_living(@e) && @e != puuid()) {
						@entities[] = @e
					}
				}
				@previouschunkx = @currentchunkx
				@previouschunkz = @currentchunkz
			}
			play_effect(@loc, array('flame', 'crit', 'cloud')[rand(3)], array('speed': 0, 'radius': 64))
			@n++
		}
		*/
	}

	foreach(@p in array_keys(@pvp['players'])) {
		if(@p == player()) {
			continue();
		}
		@ploc = ploc(@p);
		@ploc['y'] += 2.5;
		@dist = _squared_distance_to_segment(@ploc, @origin, @loc);
		@hit = false;
		if(@dist < 0.5625) { # 0.75 ^ 2
			@hit = true;
		} else if(@dist < 2.25) { # (0.75 * 2) ^ 2
			@ploc['y'] -= 1;
			@dist = _squared_distance_to_segment(@ploc, @origin, @loc);
			if(@dist < 0.5625) { # 0.75 ^ 2
				@hit = true;
			}
		}
		if(@hit) {
			try(damage_entity(puuid(@p), 16, puuid()));
			play_effect(@ploc, 'lava_pop', array('particleCount': 4));
			play_sound(@origin, array('sound': 'SUCCESSFUL_HIT'), player());
		}
	}

	play_sound(ploc(), array('sound': 'ZOMBIE_REMEDY', 'pitch': 1.8, 'volume': 3));
	@item = pinv(player(), null);
	@item['qty'] -= 1;
	queue_clear(player().'railgun');
	if(@item['qty'] == 0) {
		set_pinv(array(null: null));
	} else {
		@item['type'] = 402;
		@item['name'] = 'FIREWORK_CHARGE';
		set_pinv(array(null: @item));
		@slot = pinfo(player(), 15);
		queue_delay(7000, player().'railgun');
		queue_push(closure(){
			if(ponline(player())) {
				@item = pinv(player(), @slot);
				if(!is_null(@item) && @item['type'] == 402) {
					play_sound(ploc(), array('sound': 'FIZZ', 'pitch': 0));
					@inv = associative_array();
					@item['type'] = 175;
					@item['name'] = 'DOUBLE_PLANT';
					@inv[@slot] = @item;
					set_pinv(@inv);
				}
			}
		}, player().'railgun');
	}
}
