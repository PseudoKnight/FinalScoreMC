switch(@action) {
case 'load':
	bind('player_interact', array('id': @player.'interact'), array('player': @player, 'button': 'right', 'item': 359), @e) {
		if(split(':', @e['block'])[0] != '77' && pexp() >= 100) {
			cancel()
			@arrow = shoot_projectile(player(), 'ARROW')
			@velocity = entity_velocity(@arrow)
			set_entity_velocity(@arrow, array(@velocity['x'] * 3, @velocity['y'] * 3, @velocity['z'] * 3))
			set_entity_onfire(@arrow, 1)
			play_sound(ploc(), array('sound': 'ENDERDRAGON_HIT', 'pitch': 2))
			set_pexp(0)
			set_timeout(450, closure(){
				if(ponline(player()) && pinfo(player(), 5) > 0) {
					set_pexp(100)
				}
			})
		}
	}
	bind('projectile_hit', array('id': @player.'hit'), array('type': 'ARROW'), @e, @shooter = pinfo(@player, 13)) {
		if(@e['shooter'] == @shooter && entity_type(@e['id']), try(entity_remove(@e['id'])))
	}
	bind('entity_damage', array('id': @player.'damage'), array('cause': 'PROJECTILE', 'world': 'custom'), @e, @p = @player) {
		if(@e['shooter'] == @p, modify_event('amount', 28))
	}
	bind('player_death', array('id': @player.'death'), array('player': @player), @e) {
		play_sound(ploc(), array('sound': 'ZOMBIE_UNFECT', 'pitch': 1, 'volume': 3))
	}

case 'unload':
	unbind(@player.'interact')
	unbind(@player.'hit')
	unbind(@player.'damage')
	unbind(@player.'death')
	
}