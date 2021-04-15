proc _fw_start_task(@secs) {
	_fw_msg(array(
		'Get on up there!',
		'How good is your aim?',
	));
	foreach(@p in all_players('custom')) {
		if(_fw_player(@p)) {
			pgive_item(@p, array(name: 'ENDER_PEARL'));
		}
	}
	@region = sk_region_info('frogware', 'custom', 0);
	_iterate_cuboid(array(@region[0][0] - 1, @region[1][1] + 20, @region[0][2] - 1, 'custom'),
		array(@region[1][0] + 1, @region[1][1] + 20, @region[1][2] + 1, 'custom'),
		'EMERALD_BLOCK', 5);
	bind('player_teleport', array(id: 'fwtask', priority: 'high'), array(type: 'ENDER_PEARL'), @e) {
		if(_fw_player(player())) {
			consume();
		}
	}
}

proc _fw_end_task(@secs) {
	foreach(@p in all_players('custom')) {
		if(_fw_player(@p)
		&& get_block(ploc(@p)) === 'EMERALD_BLOCK'
		&& _fw_changeteam(@p, 'winners')) {
			play_sound(ploc(@p), array(sound: 'ENTITY_ZOMBIE_ATTACK_IRON_DOOR'), @p);
		}
	}
}