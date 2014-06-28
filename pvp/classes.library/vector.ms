switch(@action) {
case 'load':
	bind('player_interact', array('id': @player.'interact'), array('player': @player, 'button': 'right', 'item': '292'), @e) {
		cancel()
		if(get_block_at(ploc())[0] == '0'
		|| phunger() == 0, die())
		@facing = pfacing(player())
		@facing[0] = @facing[0] + 90
		@facing[1] = 0 - @facing[1]
		@x = 1.40 * cos(to_radians(@facing[0])) * cos(to_radians(@facing[1]))
		@y = max((1.40 * sin(to_radians(@facing[1]))) + 0.2, 0.2)
		@z = 1.40 * sin(to_radians(@facing[0])) * cos(to_radians(@facing[1]))
		set_timeout(50, closure(){
			set_pvelocity(player(), @x, @y, @z)
			play_sound(ploc(), array('sound': 'GHAST_CHARGE', 'pitch': 2, 'volume': 2))
			if(psaturation() >= 1) {
				set_psaturation(psaturation() - 1)
			} else if(phunger() >= 1) {
				set_phunger(phunger() - 1)
			}
		})
	}
	bind('entity_damage', array('id': @player.'falldamage'), array('type': 'PLAYER', 'cause': 'FALL', 'world': 'custom'), @e, @p = @player) {
		if(@e['player'] == @p, cancel())
	}
	bind('entity_damage', array('id': @player.'damage'), array('type': 'PLAYER', 'cause': 'ENTITY_ATTACK', 'world': 'custom'), @e, @p = @player) {
		if(@e['damager'] == @p) {
			@helm = pinv(@e['player'], 102)
			if(@armor && @armor['type'] == 20) {
				modify_event('amount', 16)
			} else {
				modify_event('amount', 8)
			}
		} else if(@e['player'] == @p 
		&& is_numeric(@e['damager'])
		&& entity_type(@e['damager']) == 'ZOMBIE') {
			cancel()
		}
	}
	bind('player_death', array('id': @player.'death'), array('player': @player), @e) {
		play_sound(ploc(), array('sound': 'GHAST_DEATH', 'pitch': 0))
	}

	proc('_manti_noise', @player) {
		if(ponline(@player)) {
			if(pinfo(@player, 5) > 0) {
				play_sound(ploc(@player), array('sound': 'CAT_PURREOW', 'pitch': 0, 'volume': 2))
			}
			queue_delay(1000 * rand(5, 15), @player)
			queue_push(closure(_manti_noise()), @player)
		}
	}
	_manti_noise(@player)

case 'unload':
	unbind(@player.'interact')
	unbind(@player.'falldamage')
	unbind(@player.'damage')
	unbind(@player.'death')
	queue_clear(@player)
	
}