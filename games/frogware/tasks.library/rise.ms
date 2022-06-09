proc _fw_start_task(@secs) {
	_fw_msg(array(
		'Don\'t float away!',
		'A real head scratcher.',
	));
	@region = sk_region_info('frogware', 'custom', 0);
	@height = @secs * 2;
	_iterate_cuboid(array(@region[0][0] - 1, @region[1][1] + @height, @region[0][2] - 1, 'custom'),
		array(@region[1][0] + 1, @region[1][1] + @height, @region[1][2] + 1, 'custom'),
		'EMERALD_BLOCK', 2);
	foreach(@p in all_players('custom')) {
		if(_fw_player(@p)) {
			set_peffect(@p, 'levitation', 2, @secs + 1, true, false);
		}
	}
}

proc _fw_end_task(@secs) {
	foreach(@p in all_players('custom')) {
		if(_fw_player(@p)
		&& get_block(location_shift(ploc(@p), 'up', 3)) === 'EMERALD_BLOCK'
		&& _fw_change_team(@p, 'winners')) {
			play_sound(ploc(@p), array(sound: 'ENTITY_ZOMBIE_ATTACK_IRON_DOOR'), @p);
		}
	}
}