proc _add_player(@player, @golf) {
	if(pmode(@player) === 'CREATIVE') {
		return(false);
	}
	@golf['players'][@player] = array(
		type: array_size(@golf['players']),
		hole: 1,
		id: 0,
		velocity: array('x': 0, 'y': 0, 'z': 0),
		swing: false,
	);
	_clear_pinv(@player);
	set_pinv(@player, array(
		0: array(type: 341),
	));
    set_collides_with_entities(@player, false);
	return(true);
}

proc _remove_player(@player, @golf) {
	unbind('golf_swing_'.@player);
	unbind('golf_hit_'.@player);
	@ball = @golf['players'][@player];
	_remove_ball(@ball['id'], @golf['name']);
	if(ponline(@player)) {
		if(pworld(@player) == @golf['world']) {
			_clear_pinv(@player);
		}
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
	array_remove(@golf['players'], @player);
}
