proc _set_spectator(@player, @pvp) {
	if(pinfo(@player, 5) > 0) {
		@pvp['spectators'][] = @player;
		foreach(@p in all_players('custom')) {
			if(ponline(@p)) {
				raw_set_pvanish(@player, true, @p);
			}
		}
		@spawn = false;
		foreach(@p in array_keys(@pvp['players'])) {
			if(ponline(@p) && array_contains(sk_current_regions(@p), @pvp['arena']['region'])) {
				set_ploc(@player, ploc(@p));
				@spawn = true;
			}
		}
		if(!@spawn) {
			set_ploc(@player, @pvp['arena']['spawn'][0][0]);
		}
		set_peffect(@player, 14, 0, 9999, true);
		set_collides_with_entities(@player, false);
		set_pflight(@player, true);
	} else {
		bind(player_spawn, associative_array('priority': 'HIGH'), associative_array('player': @player), @e, @pvp) {
			unbind();
			if(@pvp['running'] && array_size(@pvp['players']) > 1) {
				consume();
				@pvp['spectators'][] = player();
				@spawn = false;
				foreach(@p in array_keys(@pvp['players'])) {
					if(ponline(@p) && array_contains(sk_current_regions(@p), @pvp['arena']['region'])) {
						modify_event('location', ploc(@p));
						@spawn = true;
					}
				}
				if(!@spawn) {
					modify_event('location', @pvp['arena']['spawn'][0][0]);
				}
				set_timeout(50, closure(){
					if(@pvp['running']) {
						foreach(@p in all_players('custom')) {
							if(ponline(@p)) {
								raw_set_pvanish(player(), true, @p);
							}
						}

						set_peffect(player(), 14, 0, 9999, true);
						set_collides_with_entities(false);
						set_pflight(player(), true);
					}
				});
			}
		}
	}
}

proc _remove_spectator(@player, @pvp) {
	try {
		array_remove_values(@pvp['spectators'], @player)
		if(ponline(@player)) {
			set_pflight(@player, false);
			set_collides_with_entities(@player, true);
			dm_set_pvisible(@player, true);

			foreach(@p in all_players('custom')) {
				if(ponline(@p)) {
					raw_set_pvanish(@player, false, @p);
				}
			}
			set_entity_fall_distance(puuid(@player), 0);
			if(pinfo(@player, 5) > 0) {
				set_peffect(@player, 14, 0, 0);
				if(!array_index_exists(@pvp['players'], @player)) {
					set_ploc(@player, @pvp['arena']['lobby']);
				}
			} else {
				console('WARNING: Spectator somehow dead');
				respawn(@player);
			}
			if(array_index_exists(@pvp['arena'], 'resourcepack')) {
				set_timeout(100, closure(){
					send_resourcepack(@player, 'http://mc.finalscoremc.com:25966/resourcepacks/default.zip');
				});
			}
		}
	} catch(Exception @ex) {
		// not sure why this happens, but let's log it and continue
		console(@ex);
	}
}
