switch(@action) {
case 'load':
	bind('player_interact', array('id': @player.'plasmagun'), array('item': 382, 'button': 'right', 'player': @player), @e) {
		cancel()
		if(pexp() >= 100) {
			@arrow = shoot_projectile(player(), 'ARROW')
			@velocity = entity_velocity(@arrow)
			set_entity_velocity(@arrow, array(@velocity['x'] * 2.9, @velocity['y'] * 2.9, @velocity['z'] * 2.9))
			set_entity_onfire(@arrow, 1)
			play_sound(ploc(), array('sound': 'ENDERDRAGON_HIT', 'pitch': 2))
			set_pexp(0)
			set_interval(250, closure(){
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
	
	bind('player_interact', array('id': @player.'teleport'), array('item': 381, 'player': @player, 'button': 'right'), @e, @pvp = @pvp) {
		cancel()
		@loc = pinfo(player(), 2)
		foreach(@p in players_in_radius(@loc, 3)) {
			if(@p != player() && array_index_exists(@pvp['players'], @p)) {
				@player = @p
				break()
			}
		}
		
		if(@player) {
			@loc1 = ploc(@player)
			@loc2 = ploc()
			set_ploc(@loc1)
			damage_entity(pinfo(player(), 13), 1, pinfo(player(), 13))
			set_ploc(@player, @loc2)
			damage_entity(pinfo(@player, 13), 1, pinfo(player(), 13))
			play_sound(@loc1, array('sound': 'ENDERMAN_TELEPORT', 'pitch': 0.5))
			make_effect(_relative(@loc1, 'up', 2), 'ENDER_SIGNAL')
			play_sound(@loc2, array('sound': 'ENDERMAN_TELEPORT', 'pitch': 0.5))
			make_effect(_relative(@loc2, 'up', 2), 'ENDER_SIGNAL')
		} else {
			play_sound(ploc(), array('sound': 'ENDERMAN_IDLE', 'pitch': 2))
		}
		
		@item = pinv(player(), null)
		@item['qty'] -= 1
		if(@item['qty'] == 0) {
			set_pinv(player(), array(null: null))
		} else {
			set_pinv(player(), array(null: @item))
		}
	}
	
case 'powerup':
	set_pexp(@player, 100)

case 'unload':
	unbind(@player.'plasmagun')
	unbind(@player.'hit')
	unbind(@player.'teleport')
	
}