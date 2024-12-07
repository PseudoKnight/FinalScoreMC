proc _class_load(@player, @pvp) {
	set_pflight(@player, true);
	bind('player_toggle_flight', array(id: @player.'dragonfly'), array(player: @player), @e) {
		cancel();
		play_sound(ploc(), array(sound: 'ENTITY_ENDER_DRAGON_FLAP', pitch: 1.2));
		set_pflight(@e['player'], false);
		@health = phealth();
		proc _flap(@player, @health) {
			queue_push(closure(){
				if(pmode() == 'SPECTATOR') {
					queue_clear(@player.'flap');
				} else if(pexp(@player) > 0) {
					if(psneaking(@player) || phealth(@player) < @health) {
						set_pflight(@player, true);
					} else {
						@facing = pfacing(@player);
						@facing[0] = @facing[0] + 90;
						@facing[1] = 0 - @facing[1];
						@x = cos(to_radians(@facing[0])) * cos(to_radians(@facing[1]));
						@z = sin(to_radians(@facing[0])) * cos(to_radians(@facing[1]));
						set_pexp(@player, max(0, pexp(@player) - 9));
						set_pvelocity(@player, @x * 0.6, 0.47, @z * 0.6);
						play_sound(ploc(@player), array(sound: 'ENTITY_ENDER_DRAGON_FLAP', pitch: 1.2));
						set_entity_fall_distance(puuid(@player), 0);
						_flap(@player, @health);
					}
				}
			}, @player.'flap');
			queue_delay(500, @player.'flap');
		}
		if(pexp() > 0) {
			_flap(player(), @health);
		}
	}

	bind('projectile_hit', array(id: @player.'dragonsbreath'), array(type: 'FIREBALL'), @event, @region = @pvp['arena']['region']) {
		if(sk_region_contains(@region, @event['location'])) {
			spawn_entity('AREA_EFFECT_CLOUD', 1, @event['location'], closure(@cloud) {
				set_entity_spec(@cloud, array(particle: 'FLAME', duration: 240, source: @event['shooter'],
					potionmeta: array(base: array(type: 'INSTANT_DAMAGE'))
				));
			});
		}
	}
}

proc _class_powerup(@player) {
	set_pexp(@player, 99);
	set_pflight(@player, true);
}

proc _class_unload(@player, @pvp) {
	unbind(@player.'dragonfly');
	unbind(@player.'dragonsbreath');
	set_pexp(@player, 0);
	set_pflight(@player, false);
	queue_clear(@player.'flap');
}
