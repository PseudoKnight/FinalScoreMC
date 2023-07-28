queue_push(iclosure(){
	@menu = array(
		array(
			title: 'PVP Arenas',
			item: 'RED_CARPET',
			action: 'Open: pvp',
		),
		array(
			title: 'Other Games and Attractions',
			item: 'LIME_CARPET',
			action: 'Open: other-games'
		),
		array(
			title: 'Easier Solo Courses',
			item: 'LIGHT_BLUE_CARPET',
			action: 'Load: easy-courses',
		),
		array(
			title: 'Harder Solo Courses',
			item: 'PURPLE_CARPET',
			action: 'Load: hard-courses',
		),
		array(
			title: 'Cooperative Courses',
			item: 'ORANGE_CARPET',
			action: 'Load: coop-courses',
		),
		null,
		null,
		null,
		array(
			title: 'Go to Survival Worlds',
			item: 'DIAMOND_PICKAXE',
			action: 'Run: /survival',
		),
	);
	@rows = 4;
	@main = associative_array();
	foreach(@i: @entry in @menu) {
		if(!@entry) {
			continue();
		}
		@main[@rows * 9 + @i] = array(
			name: @entry['item'],
			meta: array(
				display: color('green').@entry['title'],
				lore: array(color('dark_gray').@entry['action']),
				flags: array('HIDE_ATTRIBUTES'),
			)
		)
	}
	delete_virtual_inventory('park');
	create_virtual_inventory('park', @rows * 9 + 9, 'Frog Park Directory', @main);

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
