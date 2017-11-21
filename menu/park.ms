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
	@main = array(
		'id': 'main',
		'title': 'Frog Park Directory',
		'size': 36,
		27: array('name': 'STONE_BUTTON'),
		28: array('name': 'STONE_BUTTON'),
		29: array(
			'name': 'IRON_SWORD',
			'meta': array(
				'display': color('green').'PVP Arenas',
				'lore': array(color('dark_gray').'Load: pvp'),
				'flags': array('HIDE_ATTRIBUTES'),
			),
		),
		30: array(
			'name': 'SNOW_BALL',
			'meta': array(
				'display': color('green').'Other Games',
				'lore': array(color('dark_gray').'Open: other'),
				'flags': array('HIDE_ATTRIBUTES'),
			),
		),
		31: array(
			'name': 'IRON_BLOCK',
			'meta': array(
				'display': color('green').'Solo Courses / Parkour',
				'lore': array(color('aqua').'Easy - Medium', color('dark_gray').'Open: courses1'),
			),
		),
		32:array(
			'name': 'IRON_BLOCK',
			'meta': array(
				'display': color('green').'Solo Courses / Parkour',
				'lore': array(color('gold').'Medium - Very Hard', color('dark_gray').'Open: courses2'),
			),
		),
		33:array(
			'name': 'IRON_BLOCK',
			'meta': array(
				'display': color('green').'Coop Courses / Parkour',
				'lore': array(color('dark_gray').'Open: courses3'),
			),
		),
		34: array('name': 'STONE_BUTTON'),
		35: array('name': 'STONE_BUTTON'),
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
