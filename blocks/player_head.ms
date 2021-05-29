# Player head effects
bind('player_interact', null, array('block': 'PLAYER_HEAD', 'button': 'right'), @event) {
	@loc = @event['location'];
	@owner = get_skull_owner(@loc);
	if(!@owner) {
		die();
	}
	@uuid = @owner['uuid'];

	// BURGER (Burger_guy)
	if(@uuid == '8e3d7b63-2a47-4c09-86c4-780e672b7af5') {
		@loc['x'] += 0.5;
		@loc['y'] += 0.2;
		@loc['z'] += 0.5;
		spawn_particle(@loc, array(
			'particle': 'ITEM_CRACK',
			'item': 'ROSE_BUSH',
			'count': 3,
			'xoffset': 0.75,
			'zoffset': 0.75,
		));
		play_sound(@loc, array('sound': 'ENTITY_GENERIC_EAT'));
	}

	// BEER (Thanauser)
	if(@uuid == '69bcc186-fe80-4635-a085-9cec311d8d9f') {
		@loc['x'] += 0.5;
		@loc['y'] += 0.6;
		@loc['z'] += 0.5;
		spawn_particle(@loc, array(
			'particle': 'BUBBLE_POP',
			'count': 2,
			'xoffset': 0.5,
			'zoffset': 0.5,
		));
		play_sound(@loc, array('sound': 'ENTITY_GENERIC_DRINK'));
		set_peffect(player(), 'nausea', 0, 4);
	}
}