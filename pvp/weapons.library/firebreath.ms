array_push(@pvp['binds'], @id.'firebreath')
bind(player_interact, array('id': @id.'firebreath'), array('item': 377, 'button': 'right'), @e, assign(@id, @id)) {
	@pvp = import('pvp'.@id)
	if(!array_index_exists(@pvp['players'], player()), die())
	play_sound(ploc(), array('sound': 'GHAST_FIREBALL', 'pitch': 0.5))
	@facing = pfacing(player())
	@facing[0] = @facing[0] + 90
	@facing[1] = 0 - @facing[1]
	@xc = 1.25 * cos(to_radians(@facing[0])) * cos(to_radians(@facing[1]))
	@y = 1.25 * sin(to_radians(@facing[1]))
	@zc = 1.25 * sin(to_radians(@facing[0])) * cos(to_radians(@facing[1]))
	@xl = 1.25 * cos(to_radians(@facing[0] - 40)) * cos(to_radians(@facing[1]))
	@zl = 1.25 * sin(to_radians(@facing[0] - 40)) * cos(to_radians(@facing[1]))
	@xr = 1.25 * cos(to_radians(@facing[0] + 40)) * cos(to_radians(@facing[1]))
	@zr = 1.25 * sin(to_radians(@facing[0] + 40)) * cos(to_radians(@facing[1]))
	
	@loc = ploc()
	@loc['y'] += 1.9
	@entities = array()
	@time = nano_time()
	#msg((nano_time() - @time) / 1000000)
	@targetl = array('world': 'custom')
	@targetc = array('world': 'custom')
	@targetr = array('world': 'custom')
	for(@range = 1, @range <= 4, @range++) {
		if(@range == 1) {
			@chunkc = array(floor(@loc['x'] / 16), floor(@loc['z'] / 16))
			@es = all_entities('custom', @chunkc[0], @chunkc[1])
			foreach(@e in @es) {
				if(is_entity_living(@e)
				&& (entity_type(@e) != 'PLAYER'
				|| get_player_from_entity_id(@e) != player())) {
					@entities[] = @e
				}
			}
		} else if(@range == 4) {
			@chunkl = array(floor((@loc['x'] + (@xl * @range)) / 16), floor((@loc['z'] + (@zl * @range)) / 16))
			if(@chunkl != @chunk) {
				@es = all_entities('custom', @chunkl[0], @chunkl[1])
				foreach(@e in @es) {
					if(is_entity_living(@e)
					&& (entity_type(@e) != 'PLAYER'
					|| get_player_from_entity_id(@e) != player())) {
						@entities[] = @e
					}
				}
			}
			@chunkr = array(floor((@loc['x'] + (@xr * @range)) / 16), floor((@loc['z'] + (@zr * @range)) / 16))
			if(@chunkr != @chunkl && @chunkr != @chunkc) {
				@es = all_entities('custom', @chunkr[0], @chunkr[1])
				foreach(@e in @es) {
					if(is_entity_living(@e)
					&& (entity_type(@e) != 'PLAYER'
					|| get_player_from_entity_id(@e) != player())) {
						@entities[] = @e
					}
				}
			}
		}
		@targetl['x'] = @loc['x'] + (@xl * @range)
		@targetl['y'] = @loc['y'] + (@y * @range)
		@targetl['z'] = @loc['z'] + (@zl * @range)
		@targetc['x'] = @loc['x'] + (@xc * @range)
		@targetc['y'] = @loc['y'] + (@y * @range)
		@targetc['z'] = @loc['z'] + (@zc * @range)
		@targetr['x'] = @loc['x'] + (@xr * @range)
		@targetr['y'] = @loc['y'] + (@y * @range)
		@targetr['z'] = @loc['z'] + (@zr * @range)
		play_effect(@targetl, 'mobspawner_flames')
		play_effect(@targetc, 'mobspawner_flames')
		play_effect(@targetr, 'mobspawner_flames')
	}
	#msg((nano_time() - @time) / 1000000)
	
	foreach(@e in @entities) {
		@eloc = entity_loc(@e)
		@eloc['y'] += 0.9
		@dist = _squared_distance_to_segment(@eloc, @loc, @targetc)
		if(@dist < 2.25) { # 1.5 ^ 2
			damage_entity(@e, 7, pinfo(player(), 13))
			set_entity_onfire(@e, 1)
			continue()
		}
		@dist = _squared_distance_to_segment(@eloc, @loc, @targetl)
		if(@dist < 2.25) { # 1.5 ^ 2
			damage_entity(@e, 6, pinfo(player(), 13))
			set_entity_onfire(@e, 1)
			continue()
		}
		@dist = _squared_distance_to_segment(@eloc, @loc, @targetr)
		if(@dist < 2.25) { # 1.5 ^ 2
			damage_entity(@e, 6, pinfo(player(), 13))
			set_entity_onfire(@e, 1)
			continue()
		}
	}
	#msg((nano_time() - @time) / 1000000)
	@item = pinv(player(), null)
	@item['qty'] -= 1
	if(@item['qty'] == 0) {
		set_pinv(array('null': null))
	} else {
		@item['type'] = 402
		set_pinv(array('null': @item))
		@slot = pinfo(player(), 15)
		set_timeout(1100, closure(){
			@item = pinv(player(), @slot)
			if(!is_null(@item) && @item['type'] == 402) {
				play_sound(ploc(), array('sound': 'FIZZ', 'pitch': 2))
				@inv = array()
				@item['type'] = 377
				@inv[@slot] = @item
				set_pinv(@inv)
			}
		})
	}
}