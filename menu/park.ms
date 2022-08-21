queue_push(iclosure(){
	@menu = array(
		array(
			'title': 'PVP Arenas',
			'item': 'RED_CARPET',
			'action': 'Open: pvp',
		),
		null,
		array(
			'title': 'Other Games',
			'item': 'LIME_CARPET',
			'action': 'Open: other'
		),
		null,
		array(
			'title': 'Easier Solo Courses',
			'item': 'LIGHT_BLUE_CARPET',
			'action': 'Load: solo1',
		),
		array(
			'title': 'Harder Solo Courses',
			'item': 'PURPLE_CARPET',
			'action': 'Load: solo2',
		),
		array(
			'title': 'Cooperative Courses',
			'item': 'ORANGE_CARPET',
			'action': 'Load: coop',
		),
		null,
		array(
			'title': 'Go to Survival Worlds',
			'item': 'DIAMOND_PICKAXE',
			'action': 'Run: /survival',
		),
	);
	@rows = 3;
	@main = associative_array();
	foreach(@i: @entry in @menu) {
		if(!@entry) {
			continue();
		}
		@main[@rows * 9 + @i] = array(
			'name': @entry['item'],
			'meta': array(
				'display': color('green').@entry['title'],
				'lore': array(color('dark_gray').@entry['action']),
				'flags': array('HIDE_ATTRIBUTES'),
			)
		)
	}
	delete_virtual_inventory('main');
	create_virtual_inventory('main', @rows * 9 + 9, 'Frog Park Directory', @main);

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
