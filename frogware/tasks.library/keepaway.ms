proc _fw_start_task(@secs) {
	_fw_msg(array(
		'Don\'t take damage from mobs!',
		'Watch out!',
		'Everything\'s out to get you!',
		'Be safe.',
	));
	if(!rand(4)) {
		_fw_random_potion(array('speed', 'jump_boost', 'blindness'));
	}
	_fw_mobs();
	if(!rand(4)) {
		_fw_mobs('random', 25);
	}
	foreach(@p in all_players()) {
		if(_fw_player(@p)) {
			set_ponfire(@p, 0);
		}
	}
	bind('entity_damage', array(id: 'fwtask'), array(type: 'PLAYER', world: 'custom'), @e) {
		if(_fw_player(@e['player'])
		&& (!array_index_exists(@e, 'damager') || !ponline(@e['damager']))) {
			if(_fw_change_team(@e['player'], 'losers')) {
				play_sound(ploc(@e['player']), array(sound: 'ENTITY_ZOMBIE_VILLAGER_CONVERTED'), @e['player']);
			}
		}
	}
	if(rand(2)) {
		bind('target_player', array(id: 'fwtargetplayer'), null, @e) {
			if(rand(2)) {
				@leader = _fw_leader();
				if(_fw_player(@e['player']) && @e['player'] != @leader) {
					modify_event('player', @leader);
				}
			}
		}
	}
	_fw_set_winners();
}

proc _fw_end_task(@secs) {
	_fw_clear_effects();
	_remove_region_entities('frogware');
	unbind('fwtargetplayer');
}