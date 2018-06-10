bind('player_interact', null, array('item': data_values('book'), 'button': 'right', 'hand': 'main_hand'), @event) {
	if(pworld() === 'custom') {
		@display = _item_meta(pinv(player(), null), 'display');
		if(@display === 'Park Directory') {
			cancel();
			popen_virtualchest('main');
			play_sound(ploc(), array('sound': 'STEP_WOOL', 'pitch': 1.2), player());
		}
	}
}

queue_push(closure(){
	@main = array(
		'id': 'main',
		'title': 'Frog Park Directory',
		'size': 63,
		56: array(
			'name': 'CARPET',
			'data': 14,
			'meta': array(
				'display': color('green').'PVP Arenas',
				'lore': array(color('dark_gray').'Open: pvp'),
				'flags': array('HIDE_ATTRIBUTES'),
			),
		),
		57: array(
			'name': 'CARPET',
			'data': 5,
			'meta': array(
				'display': color('green').'Other Games',
				'lore': array(color('dark_gray').'Open: other'),
				'flags': array('HIDE_ATTRIBUTES'),
			),
		),
		59: array(
			'name': 'CARPET',
			'data': 3,
			'meta': array(
				'display': color('green').'Solo Courses / Parkour',
				'lore': array(color('dark_gray').'Load: solo'),
			),
		),
		60:array(
			'name': 'CARPET',
			'data': 1,
			'meta': array(
				'display': color('green').'Coop Courses / Parkour',
				'lore': array(color('dark_gray').'Load: coop'),
			),
		),
	);
	create_virtualchest(@main);

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
