switch(@action) {
case 'load':
	set_pexp(@player, 0);

	proc _offset(@loc, @amount) {
		@loc = @loc[];
		@loc['x'] += rand() * @amount * 2.0 - @amount;
		@loc['y'] += rand() * @amount * 2.0 - @amount;
		@loc['z'] += rand() * @amount * 2.0 - @amount;
		return(@loc);
	}
	
	@particle = array('particle': 'REDSTONE', 'speed': 1.0, 'count': 0, 'color': array('r': 25, 'g': 25, 'b': 25));
	set_interval(50, closure(){
		try {
			if(!array_index_exists(@pvp['players'], @player) || @pvp['players'][@player]['class'] != 'reaper') {
				clear_task();
			} else {
				@ploc = ploc(@player);
				@loc = location_shift(@ploc, 'up', 1.7);
				spawn_particle(_offset(@loc, 0.25), @particle);
				spawn_particle(_offset(@loc, 0.25), @particle);
				spawn_particle(_offset(@loc, 0.25), @particle);
			}
		} catch(PlayerOfflineException @ex) {
			clear_task();
		}
	});
	
	bind('player_interact', array('id': @player.'hover'), array('player': @player), @event, @pvp) {
		if(@event['button'] == 'right') {
			set_peffect(player(), 'LEVITATION', -1, 0.3, true);
			set_entity_fall_distance(puuid(), 0);
			play_sound(ploc(), array('sound': 'ENTITY_HORSE_BREATHE', 'pitch': 0.5, 'volume': 0.10), player());
			set_timeout(50, closure(){
				play_sound(ploc(), array('sound': 'ENTITY_HORSE_BREATHE', 'pitch': 0.7, 'volume': 0.10), player());
			});
		} else {
			@trace = ray_trace(player(), 12);
			@target = null;
			@player = null;
			foreach(@e in @trace['entities']) {
				if(entity_type(@e['uuid']) == 'PLAYER') {
					@player = player(@e['uuid']);
					if(array_index_exists(@pvp['players'], @player) && pmode(@player) != 'SPECTATOR') {
						@target = @e['uuid'];
						break();
					}
				}
			}
			if(@target) {
				@sound1 = array('sound': 'ENTITY_PLAYER_BREATH', 'pitch': 0.5, 'volume': 0.25);
				@sound2 = array('sound': 'BLOCK_PORTAL_AMBIENT', 'pitch': 2, 'volume': 0.15);
				@loc = ploc();
				play_sound(@loc, @sound1, player());
				set_phealth(@player, max(0, phealth(@player) - 0.3));
				set_phealth(player(), min(20, phealth() + 0.2));
				if(pexp() != 99) {
					set_pexp(player(), 99);
					set_interval(200, closure(){
						try {
							if(pmode() == 'SPECTATOR' || pmode(@player) == 'SPECTATOR') {
								clear_task();
								set_pexp(player(), 0);
							} else if(entity_can_see(puuid(), @target) && distance(entity_loc(@target), entity_loc(puuid())) < 12) {
								set_phealth(@player, max(0, phealth(@player) - 0.3));
								set_phealth(player(), min(20, phealth() + 0.2));
								_stats_damage(player(), @player, 0.3, @pvp);
								@loc = location_shift(ploc(), 'up', 2);
								@loc2 = location_shift(entity_loc(@target), 'up');
								if(!rand(3)) {
									spawn_particle(location_shift(@loc, 'up', 2), 'HEART');
									spawn_particle(location_shift(@loc2, 'up', 2), 'HEART');
								}
								play_sound(@loc, @sound2, player());
								@i = 3;
								do {
									@loc = location_shift(@loc, @loc2, 1);
									spawn_particle(@loc, 'VILLAGER_HAPPY');
								} while(--@i > 0);
							} else {
								clear_task();
								set_pexp(player(), 0);
							}
						} catch(BadEntityException @ex) {
							clear_task();
							set_pexp(player(), 0);
						} catch(PlayerOfflineException @ex) {
							clear_task();
						}
					});
				}
			}
		}
	}

case 'unload':
	unbind(@player.'hover');

}
