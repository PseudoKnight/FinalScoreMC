switch(@action) {
case 'load':
	set_pflight(@player, true);
	bind('player_toggle_flight', array(id: @player.'dragonfly'), array(player: @player), @e) {
		cancel();
		play_sound(ploc(), array(sound: 'ENTITY_ENDER_DRAGON_FLAP', pitch: 1.2));
		set_pflight(@e['player'], false);
		proc _flap(@player) {
			queue_push(closure(){
				if(pmode() == 'SPECTATOR') {
					queue_clear(@player.'flap');
				} else if(pexp(@player) > 0) {
					if(psneaking(@player)) {
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
						_flap(@player);
					}
				}
			}, @player.'flap');
			queue_delay(500, @player.'flap');
		}
		if(pexp() > 0) {
			_flap(player());
		}
	}

	bind('projectile_hit', array(id: @player.'dragonsbreath'), array(type: 'FIREBALL'), @event, @region = @pvp['arena']['region']) {
		if(array_contains(sk_regions_at(@event['location']), @region)) {
			spawn_entity('AREA_EFFECT_CLOUD', 1, @event['location'], closure(@cloud) {
				set_entity_spec(@cloud, array(particle: 'FLAME', duration: 300, source: @event['shooter'],
					potionmeta: array(base: array(type: 'INSTANT_DAMAGE'))
				));
			});
		}
	}


case 'powerup':
	set_pexp(@player, 99);
	set_pflight(@player, true);

case 'unload':
	unbind(@player.'dragonfly');
	unbind(@player.'dragonsbreath');
	set_pexp(@player, 0);
	set_pflight(@player, false);
	queue_clear(@player.'flap');

}
