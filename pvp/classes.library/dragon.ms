switch(@action) {
case 'load':
	set_pflight(@player, true)
	bind(player_toggle_flight, array('id': @player.'dragonfly'), array('player': @player), @e) {
		cancel()
		play_sound(ploc(), array('sound': 'ENDERDRAGON_WINGS', 'pitch': 1.2));
		set_pflight(@e['player'], false);
		proc _flap(@player) {
			queue_push(closure(){
				if(pexp(@player) > 0 && !pinfo(@player, 11)) {
					@facing = pfacing(@player)
					@facing[0] = @facing[0] + 90
					@facing[1] = 0 - @facing[1]
					@x = cos(to_radians(@facing[0])) * cos(to_radians(@facing[1]))
					@z = sin(to_radians(@facing[0])) * cos(to_radians(@facing[1]))
					set_pexp(@player, max(0, pexp(@player) - 8))
					set_pvelocity(@player, @x * 0.6, 0.47, @z * 0.6);
					play_sound(ploc(@player), array('sound': 'ENDERDRAGON_WINGS', 'pitch': 1.2))
					_flap(@player)
				} else {
					set_interval(200, closure(){
						try(
							if(entity_grounded(pinfo(@player, 13))) {
								@xp = pexp(@player)
								if(@xp >= 100) {
									clear_task();
									set_pflight(@player, true);
								} else {
									set_pexp(@player, @xp + 2);
								}
							}

						, clear_task())
					})
				}
			}, @player.'flap')
			queue_delay(500, @player.'flap')
		}
		if(pexp() >= 100) {
			_flap(player())
		}
	}
	
	bind(entity_damage, array('id': @player.'dragonfall'), array('type': 'PLAYER', 'cause': 'FALL', 'world': 'custom'), @e, 
			@player = @player) {
			
		if(@e['player'] == @player) {
			modify_event('amount', 1);
		}
	}
	
case 'powerup':
	set_pexp(@player, 100)

case 'unload':
	unbind(@player.'dragonfly');
	unbind(@palyer.'dragonfall');
	set_pflight(@player, false);
	queue_clear(@player.'flap');
	
}