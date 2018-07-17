@menu = @main[];
@menu[57]['name'] = 'WOOL';

@menu[45] = array(
	'name': 'SNOW_BLOCK',
	'meta': array(
		'display': color('yellow').'Spleef',
		'lore': array(
			color('r').'Last man standing (2+ players)',
			color('dark_gray').'Run: /warp spleef',
		),
	),
);
@menu[46] = array(
	'name': 'STAINED_CLAY',
	'data': 2,
	'meta': array(
		'display': color('gold').'Cube'.color('red').'Climber',
		'lore': array(
			color('r').'Players race to the top of randomly placed cubes',
			color('r').'and click certain color blocks to remove them.',
			color('r').'First player to the top wins. (2+ players)',
			color('dark_gray').'Run: /warp cubeclimber',
		),
	),
);
@menu[47] = array(
	'name': 'EMERALD_ORE',
	'meta': array(
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
@menu[48] = array(
	'name': 'EMERALD_BLOCK',
	'meta': array(
		'display': color('green').'FrogWare',
		'lore': array(
			color('r').'Players are given random tasks to complete.',
			color('r').'First to 25 points (1+ players)',
			color('dark_gray').'Run: /warp frogware',
		),
	),
);
@menu[49] = array(
	'name': 'REDSTONE_BLOCK',
	'meta': array(
		'display': color('red').'Snake',
		'lore': array(
			color('r').'Last snake slithering (1 - 9 players)',
			color('r').'Collect powerups. Obliterate other snakes.',
			color('dark_gray').'Run: /warp snake',
		),
	),
);
@menu[50] = array(
	'name': 'PACKED_ICE',
	'meta': array(
		'display': color('aqua').'Hockey',
		'lore': array(
			color('r').'Team slime hockey (4 - 8 players)',
			color('dark_gray').'Run: /warp hockey',
		),
	),
);
@menu[51] = array(
	'name': 'ORANGE_GLAZED_TERRACOTTA',
	'meta': array(
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
@menu[52] = array(
	'name': 'SMOOTH_BRICK',
	'data': 2,
	'meta': array(
		'display': color('yellow').'Gladiator Arena',
		'lore': array(
			color('r').'Survive waves of mobs (1+ players)',
			color('dark_gray').'Run: /warp gladiator',
		),
	),
);
@menu[53] = array(
	'name': 'WOOD',
	'data': 4,
	'meta': array(
		'display': color('gold').'Hoops!',
		'lore': array(
			color('r').'Basketball (1+ players)',
			color('dark_gray').'Run: /warp hoops',
		),
	),
);
@menu[30] = array(
	'name': 'SLIME_BLOCK',
	'meta': array(
		'display': color('green').'Slimey Golf',
		'lore': array(
			color('r').'Minigolf (1 - 4 players)',
			color('dark_gray').'Run: /warp slimeygolf',
		),
	),
);
@menu[31] = array(
	'name': 'PRISMARINE',
	'meta': array(
		'display': color('aqua').'Sunken City Golf',
		'lore': array(
			color('r').'Minigolf (1 - 4 players)',
			color('dark_gray').'Run: /warp sunkencitygolf',
		),
	),
);
@menu[32] = array(
	'name': 'LOG',
	'data': 3,
	'meta': array(
		'display': color('yellow').'Island Golf',
		'lore': array(
			color('r').'Minigolf (1 - 4 players)',
			color('dark_gray').'Run: /warp islandgolf',
		),
	),
);
@menu[39] = array(
	'name': 'ICE',
	'meta': array(
		'display': color('aqua').'Arctic Race',
		'lore': array(
			color('r').'Race boats along treacherous icebergs.',
			color('r').'(2+ players)',
			color('dark_gray').'Run: /warp arctic',
		)
	),
);
@menu[40] = array(
	'name': 'HAY_BLOCK',
	'meta': array(
		'display': color('aqua').'Pig Race',
		'lore': array(
			color('r').'Race finnicky pigs around a pleasant course.',
			color('r').'(2+ players)',
			color('dark_gray').'Run: /warp thatlldo',
		)
	),
);
@menu[41] = array(
	'name': 'STAINED_CLAY',
	'data': 2,
	'meta': array(
		'display': color('aqua').'Gyro Race',
		'lore': array(
			color('r').'A foot race along a short course of obstacles',
			color('r').'at dizzying heights. (2+ players)',
			color('dark_gray').'Run: /warp gyro',
		)
	),
);
delete_virtual_inventory('other');
create_virtual_inventory('other', 63, 'Other Games', @menu);
