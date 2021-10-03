switch(@action) {
	case 'load':
		set_pexp(@player, 99);
		bind('player_toggle_sneak', array(id: @player.'bountyhunter'), array(sneaking: true), @event,
			@gasSound = array(sound: 'BLOCK_FIRE_EXTINGUISH', pitch: 1.1, volume: 0.5),
			@hissSound = array(sound: 'ENTITY_CAT_HISS', volume: 0.3, pitch: 1.1, volume: 0.3),
			@smokeEffect = array(particle: 'CLOUD', speed: 0.02, count: 10, xoffset: 0.25, yoffset: 0.25, zoffset: 0.25),
			@deathSound = array(sound: 'ENTITY_BLAZE_DEATH', pitch: 2.0),
			@player,
		) {
			if(@player != player()) {
				die();
			}
			if(pexp() == 0) {
				cancel();
				die();
			}
			@loc = ploc();
			@y = array(@loc['y']);

			play_sound(@loc, @gasSound);
			play_sound(@loc, @hissSound);
			spawn_particle(@loc, @smokeEffect);

			@v = get_vector(ploc());
			@v['x'] /= 3;
			@v['z'] /= 3;
			@v['y'] = 0.2;
			set_pvelocity(player(), @v);
			set_entity_fall_distance(puuid(), 0);

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
					} else {
						set_entity_fall_distance(puuid(), 0);
						@y[0] = @loc['y'];
						@loc['y'] += 1.3;
						play_sound(@loc, @gasSound);
						spawn_particle(@loc, @smokeEffect);
						set_pexp(max(0, @xp - 1));
						@v = get_vector(@loc);
						@v['x'] /= 2.7;
						@v['z'] /= 2.7;
						@v['y'] = 0.3;
						set_pvelocity(player(), @v);
					}
				} catch(PlayerOfflineException @ex) {
					clear_task();
				}
			});
		}

	case 'powerup':
		set_pexp(@player, 99);

	case 'unload':
		unbind(@player.'bountyhunter');

}
