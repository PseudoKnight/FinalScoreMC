proc _fw_start_task(@secs) {
	_fw_msg(array(
		'King of the Hill',
		'Be the Emerald King, Lord Frog Hill',
		'This hill\'s only big enough for one of you!',
		'The others are disrespecting your hill. Fight!',
	));
	if(!rand(4)) {
		_fw_mobs();
	}
	if(!rand(4)) {
		foreach(@p in all_players('custom')) {
			if(_fw_player(@p)) {
				# knockback mushroom
				pgive_item(@p, array(name: 'RED_MUSHROOM', meta: array(enchants: array(knockback: 10))));
			}
		}
	}
	if(!rand(4)) {
		@region = sk_region_info('frogware', 'custom', 0);
		_iterate_cuboid(array(@region[0][0], @region[1][1], @region[0][2], 'custom'),
			array(@region[1][0], @region[1][1], @region[1][2], 'custom'),
			'WATER', 100);
		@count = _fw_total_players() * 2;
		for(@i = 0, @i < @count, @i++) {
			drop_item(_fw_loc(), array(name: 'IRON_BOOTS', meta: array(enchants: array(depth_strider: 3))));
		}
	} else if(!rand(4)) {
		_fw_random_potion(array('speed', 'jump_boost'));
	}
	@loc = _fw_loc();
	# platform
	_iterate_cuboid(array(@loc[0] + 2, @loc[1], @loc[2] + 2, 'custom'),
		array(@loc[0] - 2, @loc[1], @loc[2] - 2, 'custom'),
		'QUARTZ_BLOCK', 100);
	_iterate_cuboid(array(@loc[0] + 1, @loc[1] + 1, @loc[2] + 1, 'custom'),
		array(@loc[0] - 1, @loc[1] + 1, @loc[2] - 1, 'custom'),
		'EMERALD_BLOCK', 100);
}

proc _fw_end_task(@secs) {
	foreach(@p in all_players('custom')) {
		if(_fw_player(@p)) {
			clear_peffects(@p);
			if(get_block(ploc(@p)) === 'EMERALD_BLOCK'
			&& _fw_change_team(@p, 'winners')) {
				play_sound(ploc(@p), array(sound: 'ENTITY_ZOMBIE_ATTACK_IRON_DOOR'), @p);
			}
		}
	}
	_remove_region_entities('frogware');
}