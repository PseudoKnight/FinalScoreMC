proc _add_player(@player, @golf) {
	@session = _psession(@player);
	if(pmode(@player) === 'CREATIVE' || array_get(@session, 'game', null)) {
		return(false);
	}
	@golf['players'][@player] = array(
		type: array_size(@golf['players']),
		hole: 1,
		id: 0,
		slime: 0,
		velocity: array('x': 0, 'y': 0, 'z': 0),
		swing: false,
	);
	pgive_item(@player, 341, 1);
	set_collides_with_entities(@player, false);
	set_pscoreboard(@player, @golf['name'].'1');
	set_pscore('strokes', @player, 0, @golf['name'].'1');
	@session['game'] = @golf['name'];
	return(true);
}

proc _remove_player(@player, @golf) {
	unbind('golf_swing1_'.@player);
	unbind('golf_swing2_'.@player);
	unbind('golf_hit_'.@player);
	@ball = @golf['players'][@player];
	_remove_ball(@ball, @golf['name']);
	if(ponline(@player)) {
		set_collides_with_entities(@player, true);
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
			set_block_at(@golf[@hole]['loc'], 0);
		} catch(IndexOverflowException @ex) {
			// nothing to reset
		}
	}
	@session = _psession(@player);
	@session['game'] = null;
	array_remove(@golf['players'], @player);
}
