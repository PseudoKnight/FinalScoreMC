bind(player_interact, null, array('item': data_values('book'), 'button': 'right', 'hand': 'main_hand'), @event) {
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
	@main = associative_array(
		'id': 'main',
		'title': 'Frog Park Directory',
		'size': 63,
		57: associative_array(
			'name': 'IRON_SWORD',
			'meta': associative_array(
				'display': color('green').'PVP Arenas',
				'lore': array(color('dark_gray').'Load: pvp'),
				'flags': array('HIDE_ATTRIBUTES'),
			),
		),
		58: associative_array(
			'name': 'IRON_BLOCK',
			'meta': associative_array(
				'display': color('green').'Solo Courses / Parkour',
				'lore': array(color('dark_gray').'Open: courses'),
			),
		),
		59: associative_array(
			'name': 'IRON_LEGGINGS',
			'meta': associative_array(
				'display': color('green').'Other Games',
				'lore': array(color('dark_gray').'Open: other'),
				'flags': array('HIDE_ATTRIBUTES'),
			),
		)
	);
	create_virtualchest(@main);

	queue_push(closure(){
		include('menus.library/other.ms');
		_prepare_menu(@main);
	});
	
	queue_push(closure(){
		include('menus.library/courses.ms');
		_prepare_menu(@main);
	});

	queue_push(closure(){
		include('menus.library/pvp.ms');
		_prepare_menu(@main);
	});
});
