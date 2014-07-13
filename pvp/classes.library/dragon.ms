switch(@action) {
case 'load':
	set_pflight(@player, true)
	bind('player_toggle_flight', array('id': @player.'dragon'), array('player': @player), @e) {
		cancel()
		play_sound(ploc(), array('sound': 'ENDERDRAGON_WINGS', 'pitch': 1.2))
		proc('_flap', @player) {
			queue_push(closure(){
				if(pexp(@player) > 0) {
					@facing = pfacing(@player)
					@facing[0] = @facing[0] + 90
					@facing[1] = 0 - @facing[1]
					@x = cos(to_radians(@facing[0])) * cos(to_radians(@facing[1]))
					@z = sin(to_radians(@facing[0])) * cos(to_radians(@facing[1]))
					set_pexp(@player, max(0, pexp(@player) - 7))
					set_pvelocity(@player, @x * 0.6, 0.46, @z * 0.6)
					play_sound(ploc(@player), array('sound': 'ENDERDRAGON_WINGS', 'pitch': 1.2))
					_flap(@player)
				} else {
					set_interval(100, closure(){
						try(
							if(entity_grounded(pinfo(@player, 13))) {
								@xp = pexp(@player)
								if(@xp >= 100) {
									clear_task()
								}
								set_pexp(@player, @xp + 2)
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

	bind('player_toggle_sneak', array('id': @player.'dragon2'), array('player': @player, 'sneaking': true), @e) {
		if(!phas_flight()) {
			set_pexp(0)
		}
	}

case 'unload':
	unbind(@player.'dragon')
	unbind(@player.'dragon2')
	set_pflight(@player, false)
	queue_clear(@player.'flap')
	
}