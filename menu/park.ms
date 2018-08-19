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

queue_push(closure(){
	@main = array(
		56: array(
			'name': 'RED_CARPET',
			'meta': array(
				'display': color('green').'PVP Arenas',
				'lore': array(color('dark_gray').'Open: pvp'),
				'flags': array('HIDE_ATTRIBUTES'),
			),
		),
		57: array(
			'name': 'LIME_CARPET',
			'meta': array(
				'display': color('green').'Other Games',
				'lore': array(color('dark_gray').'Open: other'),
				'flags': array('HIDE_ATTRIBUTES'),
			),
		),
		59: array(
			'name': 'LIGHT_BLUE_CARPET',
			'meta': array(
				'display': color('green').'Solo Courses / Parkour',
				'lore': array(color('dark_gray').'Load: solo'),
			),
		),
		60:array(
			'name': 'ORANGE_CARPET',
			'meta': array(
				'display': color('green').'Coop Courses / Parkour',
				'lore': array(color('dark_gray').'Load: coop'),
			),
		),
	);
	delete_virtual_inventory('main');
	create_virtual_inventory('main', 63, 'Frog Park Directory', @main);

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
