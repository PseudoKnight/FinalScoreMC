proc _fw_start_task(@secs) {
	_fw_msg(array(
		'Pop the frog egg!',
		'That ain\'t no dragon egg!',
		'That\'s no obsidian! It\'s a thing to right-click!',
		'Let\'s make an omellete.',
	));
	@loc = _fw_loc();
	set_block(@loc, 'DRAGON_EGG');
	if(!rand(4)) {
		_fw_mobs();
	}
	if(!rand(4)) {
		for(@i = 0, @i < 16, @i++) {
			set_block(_fw_loc(), 'OBSIDIAN');
		}
	}
	play_sound(@loc, array(sound: 'ENTITY_CHICKEN_EGG', volume: 3));
	bind('player_interact', array(id: 'fwtask', priority: 'HIGH'), array(block: 'DRAGON_EGG'), @e) {
		if(_fw_player(player())) {
			play_sound(@e['location'], array(sound: 'ENTITY_CHICKEN_EGG', volume: 3));
			consume();
			if(_fw_change_team(player(), 'winners')) {
				play_sound(ploc(), array(sound: 'ENTITY_ZOMBIE_ATTACK_IRON_DOOR'), player());
			}
		}
	}
}

proc _fw_end_task(@secs) {
	_remove_region_entities('frogware');
	_fw_clear_blocks(1);
}