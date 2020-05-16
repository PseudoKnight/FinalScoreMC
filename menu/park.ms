bind('player_interact', null, array('itemname': 'BOOK', 'button': 'right', 'hand': 'main_hand'), @event) {
	if(pworld() === 'custom') {
		@display = _item_meta(pinv(player(), null), 'display');
		if(@display === 'Park Directory') {
			cancel();
			popen_inventory('main');
			play_sound(ploc(), array('sound': 'BLOCK_WOOL_STEP', 'pitch': 1.2), player());
		}
	}
}

queue_push(iclosure(){
	@main = array(
		27: array(
			'name': 'RED_CARPET',
			'meta': array(
				'display': color('green').'PVP Arenas',
				'lore': array(color('dark_gray').'Open: pvp'),
				'flags': array('HIDE_ATTRIBUTES'),
			),
		),
		28: array(
			'name': 'LIME_CARPET',
			'meta': array(
				'display': color('green').'Other Games',
				'lore': array(color('dark_gray').'Open: other'),
				'flags': array('HIDE_ATTRIBUTES'),
			),
		),
		29: array(
			'name': 'LIGHT_BLUE_CARPET',
			'meta': array(
				'display': color('green').'Easier Solo Courses',
				'lore': array(color('dark_gray').'Load: solo1'),
			),
		),
		30: array(
			'name': 'PURPLE_CARPET',
			'meta': array(
				'display': color('green').'Harder Solo Courses',
				'lore': array(color('dark_gray').'Load: solo2'),
			),
		),
		31: array(
			'name': 'ORANGE_CARPET',
			'meta': array(
				'display': color('green').'Coop Courses',
				'lore': array(color('dark_gray').'Load: coop'),
			),
		),
		35: array(
			'name': 'DIAMOND_PICKAXE',
			'meta': array(
				'display': color('green').'Go to Survival Worlds',
				'lore': array(color('dark_gray').'Run: /survival'),
				'flags': array('HIDE_ATTRIBUTES')
			),
		),
	);
	delete_virtual_inventory('main');
	create_virtual_inventory('main', 36, 'Frog Park Directory', @main);

	queue_push(closure(){
		include('menus.library/other.ms');
	});

	queue_push(closure(){
		include('menus.library/courses.ms');
	});

	queue_push(closure(){
		include('menus.library/pvp.ms');
	});
});
