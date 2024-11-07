proc _add_player(@player, @golf) {
	if(pmode(@player) === 'CREATIVE' || pmode(@player) === 'SPECTATOR' || !_set_pactivity(@player, @golf['name'])) {
		return(false);
	}
	@golf['players'][@player] = array(
		type: array_size(@golf['players']),
		hole: @golf['lowestHole'],
		id: 0,
		slime: 0,
		velocity: array('x': 0, 'y': 0, 'z': 0),
		swing: false,
		cooldown: 0,
	);
	set_pinv(@player, 0, array(name: 'SLIME_BALL'));
	set_pscoreboard(@player, @golf['name']);
	set_pscore('strokes', @player, 0, @golf['name']);
	team_add_player('everyone', @player, @golf['name']);
	return(true);
}

proc _remove_player(@player, @golf) {
	unbind('golf_swing1_'.@player);
	unbind('golf_swing2_'.@player);
	unbind('golf_hit_'.@player);
	@ball = @golf['players'][@player];
	_remove_ball(@ball, @golf['name']);
	if(ponline(@player)) {
		set_pscoreboard(@player);
	}
	@hole = @ball['hole'];
	@lastplayer = true;
	foreach(@p: @b in @golf['players']) {
		if(@p != @player
		&& @b['hole'] <= @hole) {
			@lastplayer = false;
			break();
		}
	}
	if(@lastplayer) {
		try {
			set_block(@golf[@hole]['loc'], 'AIR');
		} catch(IndexOverflowException @ex) {
			// nothing to reset
		}
	}
	_set_pactivity(@player, null);
	array_remove(@golf['players'], @player);
}
