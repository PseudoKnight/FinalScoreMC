switch(@action) {
case 'load':
	set_pexp(@player, 0);
	
	@particle = array(particle: 'REDSTONE', count: 4, color: array(r: 25, g: 25, b: 25), xoffset: 0.6, yoffset: 0.6, zoffset: 0.6);
	set_interval(50, closure(){
		try {
			if(!array_index_exists(@pvp['players'], @player) || @pvp['players'][@player]['class'] != 'reaper') {
				clear_task();
			} else {
				spawn_particle(location_shift(ploc(@player), 'up', 1.7), @particle);
			}
		} catch(PlayerOfflineException @ex) {
			clear_task();
		}
	});
	
	bind('player_interact', array(id: @player.'hover'), array(player: @player), @event, @pvp, @previousHealth = array(20.0), @ticks = array(0)) {
		@health = phealth();
		if(@event['button'] == 'right') {
			@ticks[0]++;
			if(!array_index_exists(get_peffect(), 'levitation')) {
				@previousHealth[0] = @health;
				@ticks[0] = 0;
				set_peffect(player(), 'LEVITATION', -1, 0.3, true);
			} else if(@health < @previousHealth[0]) {
				set_peffect(player(), 'LEVITATION', 0, 0); // clear previous effect
				set_peffect(player(), 'LEVITATION', -5, 0.3, true);
			} else if(@ticks[0] > 100) { // 20 second limit on full hover
				set_peffect(player(), 'LEVITATION', 0, 0); // clear previous effect
				set_peffect(player(), 'LEVITATION', -2, 0.3, true);
			} else {
				set_peffect(player(), 'LEVITATION', 0, 0); // clear previous effect
				set_peffect(player(), 'LEVITATION', -1, 0.3, true);
			}
			set_entity_fall_distance(puuid(), 0);
			play_sound(ploc(), array(sound: 'ENTITY_HORSE_BREATHE', pitch: 0.5 + rand() * 0.2, volume: 0.15), player());
		} else {
			@trace = ray_trace(player(), 10);
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
				@sound1 = array(sound: 'ENTITY_PLAYER_BREATH', pitch: 0.5, volume: 0.25);
				@sound2 = array(sound: 'BLOCK_PORTAL_AMBIENT', pitch: 2, volume: 0.15);
				@loc = ploc();
				play_sound(@loc, @sound1, player());
				set_phealth(@player, max(0, phealth(@player) - 0.3));
				set_phealth(player(), min(20, @health + 0.2));
				if(pexp() != 99) {
					set_pexp(player(), 99);
					set_interval(200, closure(){
						try {
							if(pmode() == 'SPECTATOR' || pmode(@player) == 'SPECTATOR') {
								clear_task();
								set_pexp(player(), 0);
							} else if(entity_can_see(puuid(), @target) && distance(entity_loc(@target), entity_loc(puuid())) < 10) {
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
									spawn_particle(@loc, 'SOUL');
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
