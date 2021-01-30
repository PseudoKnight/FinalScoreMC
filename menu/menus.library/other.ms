@menu = @main[];
@menu[@rows * 9 + 1]['name'] = 'LIME_WOOL';

@menu[18] = array(
	'name': 'SNOW_BLOCK',
	'meta': array(
		'display': color('yellow').'Spleef',
		'lore': array(
			color('white').'Last man standing (2+ players)',
			color('dark_gray').'Run: /warp spleef',
		),
	),
);
@menu[19] = array(
	'name': 'MAGENTA_TERRACOTTA',
	'meta': array(
		'display': color('gold').'Cube'.color('red').'Climber',
		'lore': array(
			color('white').'Players race to the top of randomly placed cubes',
			color('white').'and click certain color blocks to remove them.',
			color('white').'First player to the top wins. (2+ players)',
			color('dark_gray').'Run: /warp cubeclimber',
		),
	),
);
@menu[20] = array(
	'name': 'EMERALD_ORE',
	'meta': array(
		'display': color('green').'Seven Seconds to Live',
		'lore': array(
			color('white').'Players have seven seconds to live...',
			color('white').'but they can add time by collecting ores!',
			color('white').'The rarer the ore, the more time added.',
			color('white').'Last man not blown up wins. (2 - 8 players)',
			color('dark_gray').'Run: /warp 7',
		),
	),
);
@menu[21] = array(
	'name': 'EMERALD_BLOCK',
	'meta': array(
		'display': color('green').'FrogWare',
		'lore': array(
			color('white').'Players are given random tasks to complete.',
			color('white').'First to 25 points (1+ players)',
			color('dark_gray').'Run: /warp frogware',
		),
	),
);
@menu[22] = array(
	'name': 'REDSTONE_BLOCK',
	'meta': array(
		'display': color('red').'Snake',
		'lore': array(
			color('white').'Last snake slithering (1 - 9 players)',
			color('white').'Collect powerups. Obliterate other snakes.',
			color('dark_gray').'Run: /warp snake',
		),
	),
);
@menu[23] = array(
	'name': 'PACKED_ICE',
	'meta': array(
		'display': color('aqua').'Hockey',
		'lore': array(
			color('white').'Team slime hockey (4 - 8 players)',
			color('dark_gray').'Run: /warp hockey',
		),
	),
);
@menu[24] = array(
	'name': 'ORANGE_GLAZED_TERRACOTTA',
	'meta': array(
		'display': color('aqua').'Charades',
		'lore': array(
			color('white').'Builders are given something random to build.',
			color('white').'Others guess the answer within the alloted time.',
			color('white').'Points are awarded for guessing and being guessed.',
			color('white').'It continues until everyone has had a turn building.',
			color('white').'(3+ Players)',
			color('dark_gray').'Run: /warp charades',
		),
	),
);
@menu[25] = array(
	'name': 'CRACKED_STONE_BRICKS',
	'meta': array(
		'display': color('yellow').'Gladiator Arena',
		'lore': array(
			color('white').'Survive waves of mobs (1+ players)',
			color('dark_gray').'Run: /warp gladiator',
		),
	),
);
@menu[26] = array(
	'name': 'ACACIA_PLANKS',
	'meta': array(
		'display': color('gold').'Hoops!',
		'lore': array(
			color('white').'Basketball (1+ players)',
			color('dark_gray').'Run: /warp hoops',
		),
	),
);
@menu[0] = array(
	'name': 'SLIME_BLOCK',
	'meta': array(
		'display': color('green').'Slimey Golf',
		'lore': array(
			color('white').'Minigolf (1 - 4 players)',
			color('dark_gray').'Run: /warp slimeygolf',
		),
	),
);
@menu[1] = array(
	'name': 'PRISMARINE',
	'meta': array(
		'display': color('aqua').'Sunken City Golf',
		'lore': array(
			color('white').'Minigolf (1 - 4 players)',
			color('dark_gray').'Run: /warp sunkencitygolf',
		),
	),
);
@menu[2] = array(
	'name': 'JUNGLE_LOG',
	'meta': array(
		'display': color('yellow').'Island Golf',
		'lore': array(
			color('white').'Minigolf (1 - 4 players)',
			color('dark_gray').'Run: /warp islandgolf',
		),
	),
);
@menu[9] = array(
	'name': 'ICE',
	'meta': array(
		'display': color('aqua').'Arctic Race',
		'lore': array(
			color('white').'Race boats along treacherous icebergs.',
			color('white').'(2+ players)',
			color('dark_gray').'Run: /warp arctic',
		)
	),
);
@menu[10] = array(
	'name': 'HAY_BLOCK',
	'meta': array(
		'display': color('aqua').'Pig Race',
		'lore': array(
			color('white').'Race finnicky pigs around a pleasant course.',
			color('white').'(2+ players)',
			color('dark_gray').'Run: /warp thatlldo',
		)
	),
);
delete_virtual_inventory('other');
create_virtual_inventory('other', @rows * 9 + 9, 'Other Games', @menu);
