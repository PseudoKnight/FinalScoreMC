proc _hazard_add_player(@player, @game) {
	if(array_index_exists(@game['inactivePlayers'], @player)) {
		@game['players'][@player] = array_remove(@game['inactivePlayers'], @player);
	} else {
		@game['players'][@player] = array(
			score: 0,
			inv: array(),
		);
	}
	set_pscoreboard(@player, 'hazard');
	bar_add_player('hazard', @player);
	if(@game['state'] == 'RUN') {
		@coords = sk_region_info('hazard_start', @game['world'], 0);
		@loc = array(rand(@coords[1][0] + 1, @coords[0][0]) + 0.5, @coords[1][1], rand(@coords[1][2] + 1, @coords[0][2]) + 0.5, @game['world']);
		set_ploc(@player, @loc);
	} else if(@game['state'] == 'BUILD') {
		set_pmode(@player, 'CREATIVE');
	}
}

proc _hazard_remove_player(@player, @game) {
	@game['inactivePlayers'][@player] = array_remove(@game['players'], @player);
	if(ponline(@player)) {
		bar_remove_player('hazard', @player);
		set_pscoreboard(@player);
		_equip_kit(@player);
	}
}

proc _hazard_spawn_players(@game) {
	@coords = sk_region_info('hazard_start', @game['world'], 0);
	@mode = if(@game['state'] == 'RUN', 'ADVENTURE', 'CREATIVE');
	foreach(@player: @data in @game['players']) {
		if(ponline(@player)) {
			@loc = array(rand(@coords[1][0] + 1, @coords[0][0]) + 0.5, @coords[1][1], rand(@coords[1][2] + 1, @coords[0][2]) + 0.5, @game['world']);
			set_ploc(@player, @loc);
			set_pmode(@player, @mode);
			set_pbed_location(@player, @loc);
			set_phealth(@player, 2);
			set_phunger(@player, 16);
			set_psaturation(@player, 0);
			if(pmode(@player) == 'ADVENTURE') {
				play_sound(@loc, array(sound: 'ENTITY_FIREWORK_ROCKET_BLAST'), @player);
				@data['inv'] = pinv(@player);
				clear_pinv(@player);
			} else {
				set_pinv(@player, @data['inv']);
			}
		}
	}
}

proc _hazard_are_players_alive(@game) {
	foreach(@player: @data in @game['players']) {
		if(pmode(@player) == 'ADVENTURE') {
			return(true);
		}
	}
	return(false);
}

proc _hazard_did_player_win(@game) {
	foreach(@player: @data in @game['players']) {
		if(@data['score'] >= @game['targetScore']) {
			return(true);
		}
	}
	return(false);
}

proc _hazard_get_winner(@game) {
	@highestScore = 0;
	@winner = array();
	foreach(@player: @data in @game['players']) {
		if(!ponline(@player)) {
			continue();
		}
		if(@data['score'] > @highestScore) {
			@highestScore = @data['score'];
			@winner = array(@player);
		} else if(@data['score'] == @highestScore) {
			@winner[] = @player;
		}
	}
	return(@winner);
}
