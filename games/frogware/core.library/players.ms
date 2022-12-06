proc _fw_add_player(@player) {
	_fw_create_scoreboard();
	set_pscoreboard(@player, 'fw');
	team_add_player('losers',@player, 'fw');

	@scores = array();
	foreach(@p in all_players('custom')) {
		if(_fw_player(@p)) {
			@scores[] = get_pscore('score', @p, 'fw');
		}
	}
	set_pscore('score', @player, if(@scores, min(@scores), 0), 'fw');

	set_ploc(@player, _fw_loc(-1));
	_fw_reset_player(@player);
}

proc _fw_reset_player(@player) {
	set_phunger(@player, 20);
	set_psaturation(@player, 5);
	set_phealth(@player, 20);
	_clear_pinv(@player);
}

proc _fw_player(@player) {
	if(ponline(@player)
	&& pworld(@player) === 'custom'
	&& get_pscoreboard(@player) === 'fw') {
		return(true);
	} else {
		return(false);
	}
}

proc _fw_total_players() {
	@count = 0;
	foreach(@p in all_players('custom')) {
		if(_fw_player(@p)) {
			@count++;
		}
	}
	return(@count);
}

proc _fw_change_team(@player, @team) {
	switch(@team) {
		case 'losers':
			if(team_remove_player('winners', @player, 'fw')) {
				team_add_player('losers', @player, 'fw');
				return(true);
			} else {
				return(false);
			}
		case 'winners':
			if(team_remove_player('losers', @player, 'fw')) {
				team_add_player('winners', @player, 'fw');
				return(true);
			} else {
				return(false);
			}
	}
}

proc _fw_set_winners() {
	foreach(@p in all_players('custom')) {
		if(_fw_player(@p)) {
			_fw_change_team(@p, 'winners');
		}
	}
}

proc _fw_leader() {
	@top = -1; // ensure we always have a leader, even if they are not actually leading
	@leader = '';
	foreach(@p in all_players('custom')) {
		if(get_pscoreboard(@p) == 'fw') {
			@score = get_pscore('score', @p, 'fw');
			if(@score > @top) {
				@leader = @p;
				@top = @score;
			}
		}
	}
	return(@leader);
}

proc _fw_msg(@msg) {
	if(is_array(@msg)) {
		@msg = array_get_rand(@msg);
	}
	foreach(@p in all_players('custom')) {
		if(_fw_player(@p)) {
			title(@p, '', @msg, 0, 40, 20);
		}
	}
}

proc _fw_countdown(@c) {
	set_objective_display('score', color(10).color('l').@c, 'fw');
	if(@c < 4 && @c > 0) {
		foreach(@p in all_players('custom')) {
			if(_fw_player(@p)) {
				play_sound(ploc(@p), array(sound: 'UI_BUTTON_CLICK', pitch: 2), @p);
			}
		}
	} else if(@c == 0) {
		foreach(@p in all_players('custom')) {
			if(_fw_player(@p)) {
				play_sound(ploc(@p), array(sound: 'ENTITY_EXPERIENCE_ORB_PICKUP'), @p);
			}
		}
	}
}

proc _fw_random_potion(@potentials, @secs = 20) {
	@potions = array(
		speed: 17,
		jump_boost: 12,
		invisibility: 1,
		blindness: 1,
		darkness: 1
	);
	@potion = array_get_rand(@potentials);
	foreach(@p in all_players('custom')) {
		if(_fw_player(@p)) {
			set_peffect(@p, @potion, array_get(@potions, @potion, 1), @secs);
		}
	}
}

proc _fw_clear_effects() {
	foreach(@p in all_players('custom')) {
		if(_fw_player(@p)) {
			clear_peffects(@p);
		}
	}
}