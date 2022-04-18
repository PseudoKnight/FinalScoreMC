proc _fw_start_task(@secs) {
	_fw_msg(array(
		'Let there be cake!',
		'Tea party!',
		'And now for the gluttony round.',
		'I hope you like cake!',
	));
	if(!rand(4)) {
		_fw_random_potion(array('speed'))
	}
	@blocks = array();
	if(rand(4)) {
		for(@i = 0, @i < max(1, floor(_fw_total_players() / 2)), @i++) {
			@block = _fw_loc();
			set_block(@block, 'CAKE');
			@blocks[] = @block;
		}
	} else {
		for(@i = 0, @i <= _fw_total_players(), @i++) {
			set_blockdata_string(_fw_loc(), 'minecraft:cake[bites=4]');
		}
	}
	bind('player_interact', array(id: 'fwtask'), array(block: 'CAKE'), @e) {
		if(_fw_player(player())
		&& _fw_change_team(player(), 'winners')) {
			play_sound(ploc(), array(sound: 'ENTITY_ZOMBIE_ATTACK_IRON_DOOR'), player());
		}
	}
	if(@blocks && !rand(5)) {
		set_timeout(2000, closure(){
			foreach(@b in @blocks) {
				@velocity = array(rand(), rand(), rand());
				play_sound(@b, array(sound: 'entity_witch_ambient', volume: 4, pitch: 1.2));
				set_block(@b, 'AIR');
				spawn_falling_block(@b, 'CAKE', @velocity);
			}
		});
	}
}

proc _fw_end_task(@secs) {
	_fw_clear_effects();
}