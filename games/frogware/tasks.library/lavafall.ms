proc _fw_start_task(@secs) {
	_fw_msg(array(
		'The lava is lava',
		'Do you smell something burning?',
		'Frogs don\'t like lava. Just sayin\'.',
	));
	if(!rand(4)) {
		_fw_random_potion(array('speed', 'blindness'));
	}
	if(!rand(4)) {
		_fw_mobs();
	}
	if(!rand(4)) {
		foreach(@p in all_players('custom')) {
			if(_fw_player(@p)) {
				pgive_item(@p, array(name: 'BUCKET'));
			}
		}
	}
	@region = sk_region_info('frogware', 'custom', 0);
	_iterate_cuboid(array(@region[0][0], @region[1][1] + 2, @region[0][2], 'custom'),
		array(@region[1][0], @region[1][1] + 2, @region[1][2], 'custom'),
		'LAVA', 3);
	bind('entity_damage', array(id: 'fwtask'), array(type: 'PLAYER', cause: 'LAVA', world: 'custom'), @e) {
		if(_fw_player(@e['player'])) {
			if(_fw_change_team(@e['player'], 'losers')) {
				play_sound(ploc(@e['player']), array(sound: 'ENTITY_ZOMBIE_VILLAGER_CONVERTED'), @e['player']);
			}
		}
	}
	_fw_set_winners();
}

proc _fw_end_task(@secs) {
	_remove_region_entities('frogware');
	_fw_clear_effects();
}