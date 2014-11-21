switch(@action) {
case 'load':
	bind(player_toggle_sprint, array(id: @player.'dragon'), array(player: @player), @e) {
		if(@e[sprinting]) {
			if(pexp() >= 100) {
				proc _flap(@player) {
					queue_push(closure(){
						if(pexp(@player) > 0) {
							@facing = pfacing(@player)
							@facing[0] = @facing[0] + 90
							@facing[1] = 0 - @facing[1]
							@x = cos(to_radians(@facing[0])) * cos(to_radians(@facing[1]))
							@z = sin(to_radians(@facing[0])) * cos(to_radians(@facing[1]))
							set_pexp(@player, max(0, pexp(@player) - 8))
							set_pvelocity(@player, @x * 0.6, 0.46, @z * 0.6)
							play_sound(ploc(@player), array(sound: 'ENDERDRAGON_WINGS', pitch: 1.2))
							_flap(@player)
						}
					}, @player.'flap')
					queue_delay(500, @player.'flap')
				}
				_flap(player())
			}
		} else {
			queue_clear(player().'flap')
			if(pexp() < 100) {
				set_pexp(0)
			}
		}
	}
	
	bind(entity_damage, array(id: @player.'dragondamage'), array(id: pinfo(@player, 13), cause: 'FALL'), @e) {
		modify_event('amount', min(2, @e[amount]))
	}
	
case 'powerup':
	set_pexp(@player, 100)

case 'unload':
	unbind(@player.'dragon')
	unbind(@player.'dragondamage')
	queue_clear(@player.'flap')
	
}