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
				if(!sk_region_contains(@region, @loc)) {
					continue();
				}
				@sx = -1;
				if(@loc['x'] - floor(@loc['x']) > 0.5) {
					@sx = 0;
				}
				@sz = -1;
				if(@loc['z'] - floor(@loc['z']) > 0.5) {
					@sz = 0;
				}
				@ignite = false;
				for(@x = @sx, @x < 2 + @sx, @x++) {
					for(@z = @sz, @z < 2 + @sz, @z++) {
						@l = array(@loc['x'] + @x, @loc['y'], @loc['z'] + @z, @loc['world']);
						@type = get_block(@l);
						if(@type === 'ORANGE_TERRACOTTA' || @type === 'WHITE_TERRACOTTA') {
							@ignite = true;
							set_block(@l, 'RED_TERRACOTTA');
						}
					}
				}

				if(@ignite) {
					set_timeout(500, closure() {
						for(@x = @sx, @x < 2 + @sx, @x++) {
							for(@z = @sz, @z < 2 + @sz, @z++) {
								@l = array(@loc['x'] + @x, @loc['y'], @loc['z'] + @z, @loc['world']);
								if(get_block(@l) === 'RED_TERRACOTTA') {
									set_block(@l, 'AIR');
								}
							}
						}
						spawn_entity('PRIMED_TNT', 1, _center(@loc, 0), closure(@tnt) {
							set_entity_spec(@tnt, array(fuseticks: 40));
							set_entity_velocity(@tnt, array(x: 0, y: -0.2, z: 0));
						});
					});
				}
			}
		} catch (Exception @ex) {
			console(@ex);
			clear_task();
		}
	});

	proc _explode(@loc, @radius = 1) {
		@loc = location_shift(@loc, 'down');
		for(@x = -@radius, @x <= @radius, @x++) {
			for(@z = -@radius, @z <= @radius, @z++) {
				@l = array(@loc['x'] + @x, @loc['y'], @loc['z'] + @z, @loc['world']);
				@type = get_block(@l);
				if(@type === 'ORANGE_TERRACOTTA' || @type === 'WHITE_TERRACOTTA') {
					set_block(@l, 'AIR');
				}
			}
		}
	}

	@pvp['binds'][] = bind('entity_explode', null, array(type: 'PRIMED_TNT'), @event, @region) {
		if(sk_region_contains(@region, @event['location'])) {
			cancel();
			spawn_particle(location_shift(@event['location'], 'up', 0.5), array(particle: 'EXPLOSION_LARGE'));
			play_sound(@event['location'], array(sound: 'ENTITY_CHICKEN_EGG', pitch: 0.5 + rand() / 2));
			_explode(@event['location']);
		}
	}

	@pvp['binds'][] = bind('projectile_hit', null, array(type: 'SNOWBALL'), @event, @pvp) {
		if(get_projectile_item(@event['id'])['name'] === 'RED_CANDLE') {
			_explode(@event['location'], 2);
		}
	}

	@pvp['binds'][] = bind('entity_damage', null, array(type: 'PLAYER'), @event, @pvp) {
		if(array_index_exists(@pvp['players'], @event['player']) && @event['amount'] > 1) {
			modify_event('amount', 1);
		}
	}
}
