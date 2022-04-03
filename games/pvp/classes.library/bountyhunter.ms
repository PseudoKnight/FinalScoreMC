proc _class_load(@player, @pvp) {
		set_pexp(@player, 99);
		bind('player_toggle_sneak', array(id: @player.'bountyhunter'), array(sneaking: true, player: @player), @event,
			@gasSound = array(sound: 'BLOCK_FIRE_EXTINGUISH', pitch: 1.1, volume: 0.5),
			@hissSound = array(sound: 'ENTITY_CAT_HISS', volume: 0.3, pitch: 1.1, volume: 0.3),
			@smokeEffect = array(particle: 'CLOUD', speed: 0.02, count: 10, xoffset: 0.25, yoffset: 0.25, zoffset: 0.25),
			@deathSound = array(sound: 'ENTITY_BLAZE_DEATH', pitch: 2.0)
		) {
			if(pexp() == 0) {
				die();
			}
			@loc = ploc();
			@y = array(@loc['y']);

			play_sound(@loc, @gasSound);
			play_sound(@loc, @hissSound);
			spawn_particle(@loc, @smokeEffect);

			set_pvelocity(player(), array(0, if(entity_grounded(puuid()), 0.4, 0.1), 0));
			set_entity_fall_distance(puuid(), 0);
			set_peffect(player(), 'LEVITATION', 0, 1, true, false);

			set_pexp(max(0, pexp() - 5));

			@startHealth = phealth();
			set_interval(100, closure(){
				try {
					@currentHealth = phealth();
					@loc = ploc();
					@xp = pexp();
					if(@xp == 0 || !psneaking() || @currentHealth < @startHealth) {
						set_entity_fall_distance(puuid(), 0);
						clear_task();
						if(@xp == 0) {
							play_sound(@loc, @deathSound);
						}
						set_peffect(player(), 'LEVITATION', 0, 0, true, false);
					} else {
						set_entity_fall_distance(puuid(), 0);
						@y[0] = @loc['y'];
						@loc['y'] += 1.3;
						if(rand() < @xp / 100, play_sound(@loc, @gasSound));
						spawn_particle(@loc, @smokeEffect);
						set_pexp(max(0, @xp - 1));
						@v = get_vector(@loc);
						@v['x'] /= 3;
						@v['z'] /= 3;
						@v['y'] = 0.1;
						set_pvelocity(player(), @v);
						set_peffect(player(), 'LEVITATION', 0, 1, true, false);
					}
				} catch(PlayerOfflineException @ex) {
					clear_task();
				}
			});
		}
}

proc _class_powerup(@player) {
		set_pexp(@player, 99);
}

proc _class_unload(@player, @pvp) {
		unbind(@player.'bountyhunter');
}
