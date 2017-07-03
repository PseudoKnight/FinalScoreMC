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
				color('r').'Race to the top (2+ players)',
				color('dark_gray').'Run: /warp cubeclimber',
			),
		),
	);
	@menu[11] = associative_array(
		'name': 'EMERALD_ORE',
		'meta': associative_array(
			'display': color('green').'Seven Seconds to Live',
			'lore': array(
				color('r').'Last man not blown up (2 - 8 players)',
				color('dark_gray').'Run: /warp 7',
			),
		),
	);
	@menu[12] = associative_array(
		'name': 'EMERALD_BLOCK',
		'meta': associative_array(
			'display': color('green').'FrogWare',
			'lore': array(
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
