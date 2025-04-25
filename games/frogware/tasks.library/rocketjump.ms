proc _fw_start_task(@secs) {
	_fw_msg(array(
		'Get on up there!',
	));
	@qty = rand(1, 4);
	foreach(@p in all_players('custom')) {
		if(_fw_player(@p)) {
			pgive_item(@p, array(name: 'WIND_BURST', qty: @qty));
		}
	}
	@region = sk_region_info('frogware', 'custom', 0);
	_iterate_cuboid(array(@region[0][0] - 1, @region[1][1] + 4, @region[0][2] - 1, 'custom'),
		array(@region[1][0] + 1, @region[1][1] + 4, @region[1][2] + 1, 'custom'),
		'EMERALD_BLOCK', 4);
}

proc _fw_end_task(@secs) {
	foreach(@p in all_players('custom')) {
		if(_fw_player(@p)
		&& get_block(ploc(@p)) === 'EMERALD_BLOCK'
		&& _fw_change_team(@p, 'winners')) {
			play_sound(ploc(@p), array(sound: 'ENTITY_ZOMBIE_ATTACK_IRON_DOOR'), @p);
		}
	}
}


