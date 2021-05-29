proc _fw_start_task(@secs) {
	_fw_msg(array(
		'Alls well that falls well.',
		'What goes up, must come down.',
		'Stay on target!',
	));
	foreach(@p in all_players('custom')) {
		if(_fw_player(@p)) {
			set_pvelocity(@p, rand(), 3, rand());
			play_sound(ploc(@p), array(sound: 'ENTITY_GHAST_SHOOT'), @p);
		}
	}
	@region = sk_region_info('frogware', 'custom', 0);
	queue_delay(600, 'fw3');
	if(rand(2)) {
		queue_push(closure(){
			_iterate_cuboid(array(@region[0][0], @region[1][1] + 3, @region[0][2], 'custom'),
				array(@region[1][0], @region[1][1] + 3, @region[1][2], 'custom'),
				'EMERALD_BLOCK', 3);
		}, 'fw3');
	} else {
		_fw_set_winners();
		queue_push(closure(){
			_iterate_cuboid(array(@region[0][0] - 1, @region[1][1] - 1, @region[0][2] - 1, 'custom'),
				array(@region[1][0] + 1, @region[1][1] - 1, @region[1][2] + 1, 'custom'),
				'WATER', 3);
		}, 'fw3');
		bind('entity_damage', array(id: 'fwtask'), array(type: 'PLAYER', cause: 'FALL'), @e) {
			if(_fw_player(@e['player'])) {
				if(_fw_change_team(@e['player'], 'losers')) {
					play_sound(ploc(@e['player']), array(sound: 'ENTITY_ZOMBIE_VILLAGER_CONVERTED'), @e['player']);
				}
			}
		}
	}
}

proc _fw_end_task(@secs) {
	if(has_bind('fwtask')){
		foreach(@p in all_players('custom')) {
			if(_fw_player(@p) && !array_contains(sk_current_regions(@p), 'frogware')) {
				set_ploc(@p, location_shift(ploc(@p), 'up'));
			}
		}
	} else {
		foreach(@p in all_players('custom')) {
			if(_fw_player(@p)
			&& get_block(ploc(@p)) === 'EMERALD_BLOCK'
			&& _fw_change_team(@p, 'winners')) {
				play_sound(ploc(@p), array(sound: 'ENTITY_ZOMBIE_ATTACK_IRON_DOOR'), @p);
			}
		}
	}
}