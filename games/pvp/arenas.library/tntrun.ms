proc _arena_bind_events(@id) {
	@pvp = import('pvp'.@id);
	@region = @pvp['arena']['region'];

	set_interval(50, closure() {
		try {
			if(@pvp['running'] != 2) {
				clear_task();
				die();
			}
			foreach(@p: @data in @pvp['players']) {
				@loc = ploc(@p);
				@type = get_block(@loc);
				if((@type == 'ORANGE_TERRACOTTA' || @type == 'WHITE_TERRACOTTA')
					&& array_contains(sk_regions_at(@loc), @region)) {

					@rx = @loc['x'] - floor(@loc['x']);
					@sx = -1;
					if(@rx > 0.5) {
						@sx = 0;
					}
					@rz = @loc['z'] - floor(@loc['z']);
					@sz = -1;
					if(@rz > 0.5) {
						@sz = 0;
					}
					for(@x = @sx, @x < 2 + @sx, @x++) {
						for(@z = @sz, @z < 2 + @sz, @z++) {
							@l = array(@loc['x'] + @x, @loc['y'], @loc['z'] + @z, @loc['world']);
							@type = get_block(@l);
							if(@type == 'ORANGE_TERRACOTTA' || @type == 'WHITE_TERRACOTTA') {
								set_block(@l, 'RED_TERRACOTTA');
							}
						}
					}

					set_timeout(500, closure() {
						for(@x = @sx, @x < 2 + @sx, @x++) {
							for(@z = @sz, @z < 2 + @sz, @z++) {
								@l = array(@loc['x'] + @x, @loc['y'], @loc['z'] + @z, @loc['world']);
								if(get_block(@l) == 'RED_TERRACOTTA') {
									set_block(@l, 'AIR');
								}
							}
						}
						spawn_entity('PRIMED_TNT', 1, _center(@loc, -1), closure(@tnt) {
							set_entity_spec(@tnt, array(fuseticks: 40));
						});
					});
				}
			}
		} catch (Exception @ex) {
			console(@ex);
			clear_task();
		}
	});

	@tnt = array();

	@pvp['binds'][] = bind('entity_explode', null, array(type: 'PRIMED_TNT'), @e, @tnt) {
		@index = array_index(@tnt, @e['id']);
		if(!is_null(@index)) {
			foreach(@block in @e['blocks']) {
				@type = get_block(@block);
				if(@type == 'ORANGE_TERRACOTTA' || @type == 'WHITE_TERRACOTTA' || @type == 'RED_TERRACOTTA') {
					set_block(@block, 'AIR');
				}
			}
			array_remove(@tnt, @index);
		} else {
			@type = get_block(location_shift(@e['location'], 'down'));
			if(@type == 'ORANGE_TERRACOTTA' || @type == 'WHITE_TERRACOTTA' || @type == 'RED_TERRACOTTA') {
				set_block(location_shift(@e['location'], 'down'), 'AIR');
			}
		}
	}

	@pvp['binds'][] = bind('player_interact_entity', null, array(clicked: 'PRIMED_TNT'), @e, @pvp, @tnt) {
		if(array_index_exists(@pvp['players'], player()) && is_null(get_entity_rider(puuid()))) {
			set_entity_rider(puuid(player()), @e['id']);
			set_entity_spec(@e['id'], array(fuseticks: 60, source: puuid()));
			add_scoreboard_tag(@e['id'], 'nodamage');
			set_pinv(player(), null, array(name: 'TNT'));
			play_sound(ploc(), array(sound: 'ENTITY_CHICKEN_EGG', pitch: 0.5));
			@tnt[] = @e['id'];
		}
	}

	@pvp['binds'][] = bind('player_interact', null, array(button: 'left', itemname: 'TNT'), @e, @pvp) {
		if(array_index_exists(@pvp['players'], player())) {
			set_pinv(player(), null, null);
			@rider = get_entity_rider(puuid());
			if(!is_null(@rider)) {
				set_entity_rider(null, @rider);
				set_entity_loc(@rider, location_shift(ploc(), 'up', 3));
				set_timeout(1, closure(){
					@vector = get_vector(ploc());
					@vector['y'] += 0.1;
					try {
						set_entity_velocity(@rider, @vector);
						set_entity_spec(@rider, array(fuseticks: 20));
						play_sound(ploc(), array(sound: 'ENTITY_IRON_GOLEM_ATTACK'));
					} catch(BadEntityException @ex) {
						// it done blown up!
					}
				});
			}
		}
	}
}
