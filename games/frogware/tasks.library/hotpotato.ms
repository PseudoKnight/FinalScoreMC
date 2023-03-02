<! 
	author: PseudoKnight,rivergod
>
proc _fw_start_task(@secs) {
	_fw_msg(array(
		'Hot potato!',
		'Do you smell something burning?',
		'That spud is too hot to eat!'
	));
	@inv = associative_array();
	do {
		@inv[rand(35)] = array(name: 'BAKED_POTATO');
	} while(rand() < 0.5)
	foreach(@p in all_players('custom')) {
		if(_fw_player(@p)) {
			set_pinv(@p, @inv);
		}
	}
	if(!rand(3)) {
		for(@i = 0, @i < rand(50), @i++) {
			drop_item(_fw_loc(@secs + @i), array(name: 'BAKED_POTATO'));
		}
	}
	bind('player_consume', array(id: 'fwtask'), array(itemname: 'BAKED_POTATO'), @e) {
		if(_fw_player(player()) && _fw_change_team(player(), 'losers')) {
			explosion(location_shift(ploc(), 'up', 2), 1, true);
			play_sound(ploc(), array(sound: 'ENTITY_ZOMBIE_VILLAGER_CONVERTED'), player());
		}
	}
	_fw_set_winners();
}

proc _fw_end_task(@secs) {
	foreach(@p in all_players('custom')) {
		if(_fw_player(@p)) {
			@count = ptake_item(@p, array(name: 'BAKED_POTATO'));
			if(@count && _fw_change_team(@p, 'losers')) {
				explosion(location_shift(ploc(@p), 'up', 2), @count, true);
				play_sound(ploc(@p), array(sound: 'ENTITY_ZOMBIE_VILLAGER_CONVERTED'), @p);
			}
		}
	}
}