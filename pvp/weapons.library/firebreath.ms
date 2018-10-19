array_push(@pvp['binds'], @id.'firebreath')
bind('player_interact', array('id': @id.'firebreath'), array('itemname': 'BLAZE_POWDER', 'button': 'right'), @e, @id) {
	@pvp = import('pvp'.@id);
	if(!array_index_exists(@pvp['players'], player()) || pinfo(player(), 6) != @e['item']['name']) {
		die();
	}
	
	@loc = ploc();
	@loc['y'] += 1.9;
	@world = @loc['world'];
	
	play_sound(@loc, array('sound': 'ENTITY_GHAST_SHOOT', 'pitch': 0.5));
	@facing = pfacing(player());
	@facing[0] = @facing[0] + 90;
	@facing[1] = 0 - @facing[1];
	@xc = cos(to_radians(@facing[0])) * cos(to_radians(@facing[1]));
	@y = sin(to_radians(@facing[1]));
	@zc = sin(to_radians(@facing[0])) * cos(to_radians(@facing[1]));
	@xl = cos(to_radians(@facing[0] - 40)) * cos(to_radians(@facing[1]));
	@zl = sin(to_radians(@facing[0] - 40)) * cos(to_radians(@facing[1]));
	@xr = cos(to_radians(@facing[0] + 40)) * cos(to_radians(@facing[1]));
	@zr = sin(to_radians(@facing[0] + 40)) * cos(to_radians(@facing[1]));
	
	#@entities = array()
	@targetl = array('world': @world);
	@targetc = array('world': @world);
	@targetr = array('world': @world);
	for(@range = 1, @range <= 4, @range++) {
		/*
		if(@range == 1) {
			@chunkc = array(floor(@loc['x'] / 16), floor(@loc['z'] / 16))
			@es = all_entities(@world, @chunkc[0], @chunkc[1])
			foreach(@e in @es) {
				if(is_entity_living(@e)
				&& (entity_type(@e) !== 'PLAYER'
				|| get_player_from_entity_id(@e) != player())) {
					@entities[] = @e
				}
			}
		} else if(@range == 4) {
			@chunkl = array(floor((@loc['x'] + (@xl * @range)) / 16), floor((@loc['z'] + (@zl * @range)) / 16))
			if(@chunkl != @chunkc) {
				@es = all_entities(@world, @chunkl[0], @chunkl[1])
				foreach(@e in @es) {
					if(is_entity_living(@e)
					&& (entity_type(@e) !== 'PLAYER'
					|| get_player_from_entity_id(@e) != player())) {
						@entities[] = @e
					}
				}
			}
			@chunkr = array(floor((@loc['x'] + (@xr * @range)) / 16), floor((@loc['z'] + (@zr * @range)) / 16))
			if(@chunkr != @chunkl && @chunkr != @chunkc) {
				@es = all_entities(@world, @chunkr[0], @chunkr[1])
				foreach(@e in @es) {
					if(is_entity_living(@e)
					&& (entity_type(@e) !== 'PLAYER'
					|| get_player_from_entity_id(@e) != player())) {
						@entities[] = @e
					}
				}
			}
		}
		*/
		@targetl['x'] = @loc['x'] + (@xl * @range);
		@targetl['y'] = @loc['y'] + (@y * @range);
		@targetl['z'] = @loc['z'] + (@zl * @range);
		@targetc['x'] = @loc['x'] + (@xc * @range);
		@targetc['y'] = @loc['y'] + (@y * @range);
		@targetc['z'] = @loc['z'] + (@zc * @range);
		@targetr['x'] = @loc['x'] + (@xr * @range);
		@targetr['y'] = @loc['y'] + (@y * @range);
		@targetr['z'] = @loc['z'] + (@zr * @range);
		spawn_particle(@targetl, 'FLAME');
		spawn_particle(@targetc, 'FLAME');
		spawn_particle(@targetr, 'FLAME');
	}

	/*
	foreach(@e in @entities) {
		@eloc = entity_loc(@e)
		@eloc['y'] += 0.9
		@dist = _squared_distance_to_segment(@eloc, @loc, @targetc)
		if(@dist < 2.25) { # 1.5 ^ 2
			damage_entity(@e, 7, puuid())
			set_entity_onfire(@e, 1)
			continue()
		}
		@dist = _squared_distance_to_segment(@eloc, @loc, @targetl)
		if(@dist < 2.25) { # 1.5 ^ 2
			damage_entity(@e, 6, puuid())
			set_entity_onfire(@e, 1)
			continue()
		}
		@dist = _squared_distance_to_segment(@eloc, @loc, @targetr)
		if(@dist < 2.25) { # 1.5 ^ 2
			damage_entity(@e, 6, puuid())
			set_entity_onfire(@e, 1)
			continue()
		}
	}
	*/
	foreach(@p in array_keys(@pvp['players'])) {
		if(@p == player() || phealth(@p) == 0) {
			continue();
		}
		@ploc = ploc(@p);
		@ploc['y'] += 1.9;
		@dist = _squared_distance_to_segment(@ploc, @loc, @targetc);
		if(@dist < 2.25) { # 1.5 ^ 2
			@uuid = puuid(@p);
			@damage = if(entity_can_see(puuid(), @uuid), 6, 3.5);
			damage_entity(@uuid, @damage, puuid());
			set_entity_onfire(@uuid, 1);
			continue();
		}
		@dist = _squared_distance_to_segment(@ploc, @loc, @targetl)
		if(@dist < 2.25) { # 1.5 ^ 2
			@uuid = puuid(@p);
			@damage = if(entity_can_see(puuid(), @uuid), 5, 3);
			damage_entity(@uuid, @damage, puuid());
			set_entity_onfire(@uuid, 1);
			continue();
		}
		@dist = _squared_distance_to_segment(@ploc, @loc, @targetr)
		if(@dist < 2.25) { # 1.5 ^ 2
			@uuid = puuid(@p);
			@damage = if(entity_can_see(puuid(), @uuid), 5, 3);
			damage_entity(@uuid, @damage, puuid());
			set_entity_onfire(@uuid, 1);
			continue();
		}
	}
	_weapon_cooldown(player(), 1200, 'FIREWORK_STAR', closure(){
		play_sound(ploc(), array('sound': 'BLOCK_FIRE_EXTINGUISH', 'pitch': 2));
	});
}
