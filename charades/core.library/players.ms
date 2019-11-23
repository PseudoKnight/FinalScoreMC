proc _charades_add_player(@p) {
	team_add_player('guessers', @p, 'charades');
	set_pmode(@p, 'SPECTATOR');
	set_pscoreboard(@p, 'charades');
	_set_pactivity(@p, 'charades');
	@spawn = sk_region_info('charades-beacon', pworld(@p), 0)[0];
	set_ploc(@p, @spawn);
}

proc _charades_remove_player(@p) {
	team_remove_player('guessers', @p, 'charades');
	if(ponline(@p)) {
		set_ploc(@p, get_value('warp.charades'));
		_equip_kit(@p);
		_set_pactivity(@p, null);
	}
}