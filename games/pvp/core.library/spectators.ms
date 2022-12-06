proc _spectator_add(@player, @pvp) {
	if(!ponline(@player)) {
		return();
	}
	@pvp['spectators'][] = @player;
	set_pmode(@player, 'SPECTATOR');
	set_pscoreboard(@player, @pvp['id']);
	if(!array_contains(sk_current_regions(), @pvp['arena']['region'])) {
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
	}
}

proc _spectator_remove(@player, @pvp) {
	try {
		array_remove_values(@pvp['spectators'], @player);
		if(ponline(@player)) {
			_equip_kit(@player);
			set_entity_fall_distance(puuid(@player), 0);
			set_ploc(@player, @pvp['arena']['lobby']);
			if(array_index_exists(@pvp['arena'], 'resourcepack')) {
				set_timeout(100, closure(){
					send_resourcepack(@player, 'http://mc.finalscoremc.com:27836/resourcepacks/default.zip');
				});
			}
			_set_pactivity(@player, null);
		}
	} catch(Exception @ex) {
		// not sure why this happens, but let us log it and continue
		console(@ex, false);
	}
}
