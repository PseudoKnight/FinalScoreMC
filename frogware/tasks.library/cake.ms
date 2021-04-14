proc _fw_start_task(@secs) {
	_fw_msg(array(
		'Let there be cake!',
		'Tea party!',
		'And now for the gluttony round.',
		'I hope you like cake!',
	));
	if(!rand(4)) {
		_fw_randompotion(array('speed'))
	}
	if(rand(4)) {
		for(@i = 0, @i < max(1, floor(_fw_totalplayers() / 2)), @i++) {
			set_block(_fw_loc(), 'CAKE');
		}
	} else {
		for(@i = 0, @i <= _fw_totalplayers(), @i++) {
			set_blockdata_string(_fw_loc(), 'minecraft:cake[bites=4]');
		}
	}
	bind('player_interact', array(id: 'fwtask'), array(block: 'CAKE'), @e) {
		if(_fw_player(player())
		&& _fw_changeteam(player(), 'winners')) {
			play_sound(ploc(), array(sound: 'ENTITY_ZOMBIE_ATTACK_IRON_DOOR'), player());
		}
	}
}

proc _fw_end_task(@secs) {
	_fw_clear_effects();
}