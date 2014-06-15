switch(@action) {
case 'load':
	bind('player_interact', array('id': @player.'plasmagun'), array('item': 382, 'button': 'right', 'player': @player), @e) {
		cancel()
		if(pexp() >= 100) {
			@arrow = shoot_projectile(player(), 'ARROW')
			@velocity = entity_velocity(@arrow)
			set_entity_velocity(@arrow, array(@velocity['x'] * 3, @velocity['y'] * 3, @velocity['z'] * 3))
			set_entity_onfire(@arrow, 1)
			play_sound(ploc(), array('sound': 'ENDERDRAGON_HIT', 'pitch': 2))
			set_pexp(0)
			set_interval(150, closure(){
				try(
					@xp = pexp()
					@xp += 10
					set_pexp(@xp)
					if(@xp >= 100) {
						clear_task()
					}
					
				, clear_task())
			})
		}
	}

	bind('projectile_hit', array('id': @player.'hit'), array('type': 'ARROW'), @e, @shooter = pinfo(@player, 13)) {
		if(@e['shooter'] == @shooter && entity_type(@e['id']), try(entity_remove(@e['id'])))
	}

case 'unload':
	unbind(@player.'plasmagun')
	unbind(@player.'hit')
	
}