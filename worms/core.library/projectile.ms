proc _worms_shoot_projectile(@player, @game) {
	if(array_size(@game['players'][@player]['segments']) < 2) {
		return();
	}
	@segment = @game['players'][@player]['segments'][0];
	array_remove(@game['players'][@player]['segments'], 0);
	set_entity_spec(@segment, array('small': true, 'visible': false));
	@loc = location_shift(entity_loc(@segment), 'up', 1.5);
	@loc['yaw'] = ploc(@player)['yaw'];
	@loc['pitch'] = 0;
	play_sound(@loc, array('sound': 'ENTITY_SHULKER_SHOOT', 'pitch': 2, 'volume': 3));
	@count = array(64, 0);
	set_interval(50, closure(){
		@count[0]--;
		@trace = ray_trace(@loc, 0.8 - @count[1] * 0.2);
		try(set_entity_loc(@segment, location_shift(@trace['location'], 'down', 1.5)));
		if(@count[0] < 0) {
			clear_task();
			try(set_entity_spec(@segment, array('small': false)));
			@game['segments'][] = @segment;
			spawn_particle(@trace['location'], array('particle': 'EXPLOSION_LARGE', 'count': 0, 'xoffset': 1.1));
			play_sound(@trace['location'], array('sound': 'ENTITY_SHULKER_BULLET_HIT', 'pitch': 2, 'volume': 3));
		} else if(@trace['hitblock']) {
			@count[1]++;
			if(@trace['location']['x'] == round(@trace['location']['x'])) {
				@loc['yaw'] = neg(@loc['yaw']);
			} else if(@trace['location']['z'] == round(@trace['location']['z'])) {
				if(@loc['yaw'] > 180) {
					@loc['yaw'] += (270 - @loc['yaw']) * 2;
				} else {
					@loc['yaw'] += (90 - @loc['yaw']) * 2;
				}
			}
			play_sound(@trace['location'], array('sound': 'BLOCK_END_PORTAL_FRAME_FILL', 'pitch': 2, 'volume': 3));
		} else {
			@loc['x'] = @trace['location']['x'];
			@loc['z'] = @trace['location']['z'];
			foreach(@e in @trace['entities']) {
				if(entity_type(@e['uuid']) == 'ARMOR_STAND' && @e != @segment) {
					foreach(@p: @worm in @game['players']) {
						if(@count[1] == 0 && @p == player()) {
							continue();
						}
						@game['segments'][] = @segment;
						@index = array_index(@worm['segments'], @e['uuid']);
						if(!is_null(@index)) {
							clear_task();
							try(set_entity_spec(@segment, array('small': false)));
							@v = get_vector(@loc);
							while(array_index_exists(@worm['segments'], @index)) {
								@segment = @worm['segments'][@index];
								array_remove(@worm['segments'], @index);
								@l = entity_loc(@segment);
								@l['x'] += rand() * 2 - 1 + @v['x'];
								@l['z'] += rand() * 2 - 1 + @v['z'];
								set_entity_loc(@segment, @l);
								@game['segments'][] = @segment;
							}
							spawn_particle(@e['location'], array('particle': 'EXPLOSION_LARGE', 'count': 0, 'xoffset': 1.1));
							play_sound(@e['location'], array('sound': 'ENTITY_SHULKER_BULLET_HIT', 'pitch': 2, 'volume': 3));
							set_pscore('segments', @p, array_size(@worm['segments']), 'worms');
							if(array_size(@worm['segments']) == 0) {
								_worms_kill(@p, @game);
							} else if(array_size(@worm['segments']) < 35) {
								team_remove_player('leaders', @p, 'worms');
							}
						}
					}
				}
			}
		}
	});
}
