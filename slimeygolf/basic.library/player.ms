proc _add_player(@player, @golf) {
	if(pmode(@player) == 'CREATIVE') {
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
	if(function_exists('set_collides_with_entities')) {
		set_collides_with_entities(@player, false);
	}
	set_pscoreboard(@player, @golf['course']['name']);
	set_pscore('strokes', @player, 1, @golf['course']['name']);
	set_pscore('strokes', @player, 0, @golf['course']['name']);
	return(true);
}

proc _remove_player(@player, @golf) {
	unbind('golf_swing_'.@player);
	unbind('golf_hit_'.@player);
	try(entity_remove(@golf['players'][@player]['id']));
	if(ponline(@player)) {
		if(function_exists('set_collides_with_entities')) {
			set_collides_with_entities(@player, true);
		}
		if(pworld(@player) == @golf['course']['loc'][3]) {
			_clear_pinv(@player);
		}
		reset_all_pscores(@player, @golf['course']['name']);
		set_pscoreboard(@player);
	}
	array_remove(@golf['players'], @player);
}