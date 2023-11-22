queue_push(iclosure(){
	@menu = array(
		array(
			title: 'PVP Arenas',
			description: 'Competitive combat games for two or more players.',
			item: 'RED_CARPET',
			action: 'Open: pvp',
		),
		array(
			title: 'Other Games and Attractions',
			description: 'A variety of custom singleplayer and multiplayer games.',
			item: 'LIME_CARPET',
			action: 'Open: other-games'
		),
		array(
			title: 'Easier Solo Courses',
			description: 'Parkour courses that are below average difficulty. Track your progress.',
			item: 'LIGHT_BLUE_CARPET',
			action: 'Load: easy-courses',
		),
		array(
			title: 'Harder Solo Courses',
			description: 'Parkour courses that are above average difficulty. Track your progress.',
			item: 'PURPLE_CARPET',
			action: 'Load: hard-courses',
		),
		array(
			title: 'Cooperative Courses',
			description: 'Parkour and puzzle courses for two players.',
			item: 'ORANGE_CARPET',
			action: 'Load: coop-courses',
		),
		null,
		null,
		null,
		array(
			title: 'Go to Survival Worlds',
			description: 'Teleports you to the survival mode worlds. You can return with the /park command.',
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
		@lore = array();
		if(array_index_exists(@entry, 'description')) {
			foreach(@match in reg_match_all('.*?\\.\\s?', @entry['description'])) {
				@lore[] = color('white').@match[0];
			}
		}
		@lore[] = color('dark_gray').@entry['action'];
		@main[@rows * 9 + @i] = array(
			name: @entry['item'],
			meta: array(
				display: color('green').@entry['title'],
				lore: @lore,
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
