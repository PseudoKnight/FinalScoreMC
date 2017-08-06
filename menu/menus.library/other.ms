proc _prepare_menu(@template) {
	@menu = @template[];
	@menu['id'] = 'other';
	@menu['title'] = 'Other Games';
	@menu[59]['name'] = 'DIAMOND_LEGGINGS';
	
	@menu[9] = associative_array(
		'name': 'SNOW_BLOCK',
		'meta': associative_array(
			'display': color('yellow').'Spleef',
			'lore': array(
				color('r').'Last man standing (2+ players)',
				color('dark_gray').'Run: /warp spleef',
			),
		),
	);
	@menu[10] = associative_array(
		'name': 'STAINED_CLAY',
		'data': 2,
		'meta': associative_array(
			'display': color('gold').'Cube'.color('red').'Climber',
			'lore': array(
				color('r').'Players race to the top of randomly placed cubes',
				color('r').'and click certain color blocks to remove them.',
				color('r').'First player to the top wins. (2+ players)',
				color('dark_gray').'Run: /warp cubeclimber',
			),
		),
	);
	@menu[11] = associative_array(
		'name': 'EMERALD_ORE',
		'meta': associative_array(
			'display': color('green').'Seven Seconds to Live',
			'lore': array(
				color('r').'Players have seven seconds to live...',
				color('r').'but they can add time by collecting ores!',
				color('r').'The rarer the ore, the more time added.',
				color('r').'Last man not blown up wins. (2 - 8 players)',
				color('dark_gray').'Run: /warp 7',
			),
		),
	);
	@menu[12] = associative_array(
		'name': 'EMERALD_BLOCK',
		'meta': associative_array(
			'display': color('green').'FrogWare',
			'lore': array(
				color('r').'Players are given random tasks to complete in seconds.',
				color('r').'First to 25 points (1+ players)',
				color('dark_gray').'Run: /warp frogware',
			),
		),
	);
	@menu[13] = associative_array(
		'name': 'REDSTONE_BLOCK',
		'meta': associative_array(
			'display': color('red').'Snake',
			'lore': array(
				color('r').'Last snake slithering (1 - 9 players)',
				color('r').'Collect powerups. Obliterate other snakes.',
				color('dark_gray').'Run: /warp snake',
			),
		),
	);
	@menu[14] = associative_array(
		'name': 'PACKED_ICE',
		'meta': associative_array(
			'display': color('aqua').'Hockey',
			'lore': array(
				color('r').'Team slime hockey (4 - 8 players)',
				color('dark_gray').'Run: /warp hockey',
			),
		),
	);
	@menu[15] = associative_array(
		'name': 'ORANGE_GLAZED_TERRACOTTA',
		'meta': associative_array(
			'display': color('aqua').'Charades',
			'lore': array(
				color('r').'Builders are given something random to build.',
				color('r').'Others guess the answer within the alloted time.',
				color('r').'Points are awarded for guessing and being guessed.',
				color('r').'It continues until everyone has had a turn building.',
				color('r').'(3+ Players)',
				color('dark_gray').'Run: /warp charades',
			),
		),
	);
	@menu[18] = associative_array(
		'name': 'SLIME_BLOCK',
		'meta': associative_array(
			'display': color('green').'Slimey Golf',
			'lore': array(
				color('r').'Minigolf (1 - 4 players)',
				color('dark_gray').'Run: /warp slimeygolf',
			),
		),
	);
	@menu[19] = associative_array(
		'type': 168,
		'meta': associative_array(
			'display': color('aqua').'Sunken City Golf',
			'lore': array(
				color('r').'Minigolf (1 - 4 players)',
				color('dark_gray').'Run: /warp sunkencitygolf',
			),
		),
	);
	@menu[20] = associative_array(
		'name': 'LOG',
		'data': 3,
		'meta': associative_array(
			'display': color('yellow').'Island Golf',
			'lore': array(
				color('r').'Minigolf (1 - 4 players)',
				color('dark_gray').'Run: /warp islandgolf',
			),
		),
	);
	@menu[27] = associative_array(
		'name': 'SMOOTH_BRICK',
		'data': 2,
		'meta': associative_array(
			'display': color('yellow').'Gladiator Arena',
			'lore': array(
				color('r').'Survive waves of mobs (1+ players)',
				color('dark_gray').'Run: /warp gladiator',
			),
		),
	);
	
	create_virtualchest(@menu);
}
