proc _set_spectator(@id, @player, @pvp) {
	if(pinfo(@player, 5) > 0) {
		@pvp['spectators'][] = @player
		set_collides_with_entities(@player, false)
		foreach(@p in all_players('custom')) {
			if(ponline(@p)) {
				raw_set_pvanish(@player, true, @p)
			}
		}
		set_pflight(@player, true)
		@spawn = false
		foreach(@p in array_keys(@pvp['players'])) {
			if(array_contains(sk_current_regions(@p), @pvp['arena']['region'])) {
				set_ploc(@player, ploc(@p))
				@spawn = true
			}
		}
		if(!@spawn) {
			set_ploc(@player, @pvp['arena']['spawn'][0][0])
		}
		set_peffect(@player, 14, 0, 9999, true)
	} else {
		bind(player_spawn, null, array('player': @player), @e, @id) {
			unbind()
			@pvp = import('pvp'.@id)
			if(@pvp['running'] && array_size(@pvp['players']) > 1) {
				@pvp['spectators'][] = player()
				@spawn = false
				foreach(@p in array_keys(@pvp['players'])) {
					if(array_contains(sk_current_regions(@p), @pvp['arena']['region'])) {
						modify_event('location', ploc(@p))
						@spawn = true
					}
				}
				if(!@spawn) {
					modify_event('location', @pvp['arena']['spawn'][0][0])
				}
				queue_push(closure(){
					foreach(@p in all_players('custom')) {
						if(ponline(@p)) {
							raw_set_pvanish(player(), true, @p)
						}
					}
					set_pflight(player(), true)
					set_peffect(player(), 14, 0, 9999, true)
					set_collides_with_entities(false)
				})
			}
		}
	}
}

proc _remove_spectator(@id, @player, @pvp) {
	try(
		array_remove_values(@pvp['spectators'], @player)
		if(ponline(@player)) {
			set_collides_with_entities(@player, true)
			if(array_index_exists(@pvp['arena'], 'resourcepack')) {
				send_resourcepack(@player, 'http://mc.finalscoremc.com:25966/resourcepacks/default.zip')
			}
			foreach(@p in all_players('custom')) {
				if(ponline(@p)) {
					raw_set_pvanish(@player, false, @p)
				}
			}
			set_entity_fall_distance(puuid(@player), 0);
			set_pflight(@player, false);
			if(pinfo(@player, 5) > 0) {
				set_peffect(@player, 14, 0, 0);
				if(!array_index_exists(@pvp['players'], @player)) {
					set_ploc(@player, @pvp['arena']['lobby'])
				}
			}
		}
	, @ex, #catch
		console(@ex)
	)
}