switch(@action) {
case 'load':
	set_pflight(@player, true)
	bind(player_toggle_flight, array('id': @player.'dragonfly'), array('player': @player), @e) {
		cancel()
		play_sound(ploc(), array('sound': 'ENDERDRAGON_WINGS', 'pitch': 1.2));
		set_pflight(@e['player'], false);
		proc _flap(@player) {
			queue_push(closure(){
				if(phealth(@player) == 0) {
					queue_clear(@player.'flap');
				} else if(pexp(@player) > 0 && !psneaking(@player)) {
					@facing = pfacing(@player);
					@facing[0] = @facing[0] + 90;
					@facing[1] = 0 - @facing[1];
					@x = cos(to_radians(@facing[0])) * cos(to_radians(@facing[1]));
					@z = sin(to_radians(@facing[0])) * cos(to_radians(@facing[1]));
					set_pexp(@player, max(0, pexp(@player) - 8));
					set_pvelocity(@player, @x * 0.6, 0.47, @z * 0.6);
					play_sound(ploc(@player), array('sound': 'ENDERDRAGON_WINGS', 'pitch': 1.2));
					set_entity_fall_distance(puuid(@player), 0);
					_flap(@player);
				} else {
					set_interval(200, closure(){
						try {
							if(pinv(@player, 103)['name'] == 'SKULL_ITEM') {
								clear_task();
							} else if(entity_grounded(puuid(@player))) {
								@xp = pexp(@player);
								if(@xp > 98) {
									clear_task();
									set_pflight(@player, true);
								} else {
									set_pexp(@player, min(99, @xp + 2));
								}
							}

						} catch(Exception @ex) {
							clear_task();
						}
					})
				}
			}, @player.'flap');
			queue_delay(500, @player.'flap');
		}
		if(pexp() == 99) {
			_flap(player())
		}
	}

	bind(entity_damage, array('id': @player.'dragonfall'), array('type': 'PLAYER', 'cause': 'FALL'), @e, @player) {
		if(@e['player'] == @player) {
			modify_event('amount', 1);
		}
	}


	bind(projectile_hit, array('id': @player.'dragonsbreath'), array('type': 'FIREBALL'), @e, @player = puuid(@player)) {
		if(@e['shooter'] == @player) {
			@cloud = spawn_entity('AREA_EFFECT_CLOUD', 1, @e['location'])[0];
			set_entity_spec(@cloud, associative_array('particle': 'FLAME', 'duration': 300, 'source': puuid(@player),
				'potionmeta': associative_array('base': associative_array('type': 'INSTANT_DAMAGE'))
			));
		}
	}


case 'powerup':
	set_pexp(@player, 99);
	set_pflight(@player, true);

case 'unload':
	unbind(@player.'dragonfly');
	unbind(@player.'dragonfall');
	unbind(@player.'dragonsbreath');
	set_pexp(@player, 0);
	set_pflight(@player, false);
	queue_clear(@player.'flap');

}
