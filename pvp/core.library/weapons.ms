proc _weapon_cooldown(@player, @time, @type, @onCooldown, @remove = 1) {
	@item = pinv(@player, null);
	@item['qty'] -= @remove;
	if(@item['qty'] == 0) {
		set_pinv(@player, array(null: null));
	} else {
		if(@type == null) {
			set_pinv(@player, array(null: null));
		} else {
			@newItem = @item[];
			@newItem['name'] = @type;
			@newItem['data'] = 0;
			set_pinv(@player, array(null: @newItem));
		}
		@slot = pinfo(@player, 15);
		set_timeout(@time, closure(){
			try {
				@newItem = pinv(@player, @slot);
				if(@type == null || (!is_null(@newItem)
				&& @newItem['name'] == @type)) {
					@inv = associative_array();
					@inv[@slot] = @item;
					set_pinv(@player, @inv);
					if(is_closure(@onCooldown)) {
						execute(@onCooldown);
					}
				}
			} catch(PlayerOfflineException @ex) {
				// gun safety failure
			}
		});
	}
}

proc _hit_scan(@origin, @range, @damage, @tracerParticle, @hitParticle, @pvp){
	@origin = _relative(@origin, 'up', if(get_entity_gliding(puuid()), 1, 2.3));
	@vector = _get_vector(@origin['yaw'], @origin['pitch']);
	@x = @vector['x'];
	@y = @vector['y'];
	@z = @vector['z'];
	@loc = @origin[];

	proc _whitelisted_block(@loc, @whitelisted = array(
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
	)) {
		@id = split(get_block_at(@loc), ':')[0];
		if(array_contains(@whitelisted, @id)) {
			return(true);
		}
		return(false);
	}

	@particle = '';
	if(!is_array(@tracerParticle)) {
		@particle = @tracerParticle;
	}
	while(@range > 0) {
		@range--;
		@loc['x'] += @x;
		@loc['y'] += @y;
		@loc['z'] += @z;
		if(is_array(@tracerParticle)) {
			@particle = @tracerParticle[rand(3)];
		}
		play_effect(@loc, @particle, array('speed': 0, 'radius': 64));
		if(get_block_info(@loc, 'solid') && !_whitelisted_block(@loc)) {
			play_effect(@loc, @hitParticle, array('particleCount': 8, 'speed': 0.05));
			break();
		}
	}

	@players = array();
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
			if(@damage) {
				try(damage_entity(puuid(@p), @damage, puuid()));
			}
			play_effect(@ploc, @hitParticle, array('particleCount': 4, 'speed': 0.05));
			play_sound(@origin, array('sound': 'SUCCESSFUL_HIT'), player());
			@players[] = @p;
		}
	}

	return(@players);
}
