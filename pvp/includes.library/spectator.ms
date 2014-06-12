proc('_set_spectator', @id, @player, @pvp) {
	if(pinfo(@player, 5) > 0) {
		@pvp['spectators'][] = @player
		set_collides_with_entities(@player, false)
		foreach(@p in all_players('custom')) {
			raw_set_pvanish(@player, true, @p)
		}
		set_pflight(@player, true)
		set_ploc(@player, @pvp['arena']['spawn'][0][0])
		set_peffect(@player, 14, 0, 999, true)
	} else {
		bind('player_spawn', null, array('player': @player), @e, @id = @id) {
			@pvp = import('pvp'.@id)
			if(@pvp['running']) {
				@pvp['spectators'][] = player()
				set_collides_with_entities(player(), false)
				foreach(@p in all_players('custom')) {
					raw_set_pvanish(player(), true, @p)
				}
				set_pflight(player(), true)
				modify_event('location', @pvp['arena']['spawn'][0][0])
				set_timeout(50, closure(){
					set_peffect(player(), 14, 0, 999, true)
				})
			}
			unbind()
		}
	}
}

proc('_remove_spectator', @id, @player, @pvp) {
	array_remove_values(@pvp['spectators'], @player)
	if(ponline(@player)) {
		set_collides_with_entities(@player, true)
		foreach(@p in all_players('custom')) {
			raw_set_pvanish(@player, false, @p)
		}
		set_pflight(@player, false)
		if(pworld(@player) == 'custom' && pinfo(@player, 5) > 0) {
			set_peffect(@player, 14, 0, 0)
			if(!array_index_exists(@pvp['players'], @player)) {
				set_ploc(@player, @pvp['arena']['lobby'])
			}
		}
	}
}