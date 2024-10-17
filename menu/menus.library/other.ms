@menu = @main[];
@menu[@rows * 9 + 1]['name'] = 'LIME_WOOL';

@menu[0] = array(
	name: 'SNOW_BLOCK',
	meta: array(
		display: color('yellow').'Spleef',
		lore: array(
			color('white').'Last man standing (2+ players)',
			color('dark_gray').'Run: /warp spleef',
		),
	),
);
@menu[1] = array(
	name: 'MAGENTA_CONCRETE',
	meta: array(
		display: color('gold').'Cube'.color('red').'Climber',
		lore: array(
			color('white').'Players race to the top of randomly placed cubes.',
			color('white').'Click certain color blocks to remove them.',
			color('white').'First player to the top wins. (1+ players)',
			color('white').'Get a high score for fastest climb!',
			color('dark_gray').'Run: /warp cubeclimber',
		),
	),
);
@menu[2] = array(
	name: 'EMERALD_ORE',
	meta: array(
		display: color('green').'Seven Seconds to Live',
		lore: array(
			color('white').'Players have seven seconds to live...',
			color('white').'but they can add time by collecting ores!',
			color('white').'The rarer the ore, the more time added.',
			color('white').'Last man not blown up wins. (2 - 8 players)',
			color('dark_gray').'Run: /warp 7',
		),
	),
);
@menu[3] = array(
	name: 'EMERALD_BLOCK',
	meta: array(
		display: color('green').'FrogWare',
		lore: array(
			color('white').'Players are given random tasks to complete.',
			color('white').'Be crowned best frog on the server! (1+ players)',
			color('dark_gray').'Run: /warp frogware',
		),
	),
);
@menu[4] = array(
	name: 'REDSTONE_BLOCK',
	meta: array(
		display: color('red').'Snake Pit',
		lore: array(
			color('white').'Various snake modes (1 - 9 players)',
			color('white').'Collect powerups. Obliterate other players and bots.',
			color('white').'Play with friends in a capture the flag mode.',
			color('white').'Get a high score in endless or classic modes!',
			color('dark_gray').'Run: /warp snake',
		),
	),
);
@menu[5] = array(
	name: 'PACKED_ICE',
	meta: array(
		display: color('aqua').'Hockey',
		lore: array(
			color('white').'Team slime hockey (2+ players)',
			color('dark_gray').'Run: /warp hockey',
		),
	),
);
@menu[6] = array(
	name: 'ORANGE_GLAZED_TERRACOTTA',
	meta: array(
		display: color('aqua').'Charades',
		lore: array(
			color('white').'Builders are given something random to build.',
			color('white').'Others guess the answer within the alloted time.',
			color('white').'Points are awarded for guessing and being guessed.',
			color('white').'It continues until everyone has had a turn building.',
			color('white').'(3+ Players)',
			color('dark_gray').'Run: /warp charades',
		),
	),
);
@menu[7] = array(
	name: 'ACACIA_PLANKS',
	meta: array(
		display: color('gold').'Hoops!',
		lore: array(
			color('white').'Regular slimey basketball (1+ players)',
			color('white').'Practice by yourself or play a team game.',
			color('dark_gray').'Run: /warp hoops',
		),
	),
);
@menu[8] = array(
	name: 'SCAFFOLDING',
	meta: array(
		display: color('gold').'Hazard!',
		lore: array(
			color('white').'Build an obstacle course together and run it. (2+ players)',
			color('white').'Either by skill or guise, reach the end each round',
			color('white').'but prevent others from doing the same.',
			color('white').'Create challenging obstacles, secret shortcuts or clever traps.',
			color('dark_gray').'Run: /warp hazard',
		),
	),
);
@menu[9] = array(
	name: 'CRACKED_STONE_BRICKS',
	meta: array(
		display: color('yellow').'Gladiator Arena',
		lore: array(
			color('white').'Survive waves of mobs (1+ players)',
			color('white').'Buy and sell equipment in a shop using exp levels.',
			color('dark_gray').'Run: /warp gladiator',
		),
	),
);
@menu[10] = array(
	name: 'HAY_BLOCK',
	meta: array(
		display: color('yellow').'Cluck',
		lore: array(
			color('white').'A good ol\' chicken shoot (1 player)',
			color('white').'Get a high score!',
			color('dark_gray').'Run: /warp cluck',
		),
	),
);
@menu[11] = array(
	name: 'LIME_CONCRETE',
	meta: array(
		display: color('green').'Life',
		lore: array(
			color('white').'Multiplayer free-build game of life (1+ players)',
			color('dark_gray').'Run: /warp life',
		),
	),
);
@menu[12] = array(
	name: 'WHITE_STAINED_GLASS',
	meta: array(
		display: color('yellow').'Stairway to Heaven',
		lore: array(
			color('white').'Climb the stairway to heaven (1+ players)',
			color('dark_gray').'Run: /warp stairway',
		),
	),
);
@menu[13] = array(
	name: 'RED_CONCRETE_POWDER',
	meta: array(
		display: color('red').'Connect 4',
		lore: array(
			color('white').'Classic game of Connect 4 (2 players)',
			color('white').'Discover its secret.',
			color('dark_gray').'Run: /warp connect4',
		),
	),
);
@menu[18] = array(
	name: 'SLIME_BLOCK',
	meta: array(
		display: color('green').'Slimey Golf',
		lore: array(
			color('white').'The original minigolf course (1 - 4 players)',
			color('dark_gray').'Run: /warp slimeygolf',
		),
	),
);
@menu[19] = array(
	name: 'PRISMARINE',
	meta: array(
		display: color('aqua').'Sunken City Golf',
		lore: array(
			color('white').'Minigolf in an underwater structure (1 - 4 players)',
			color('dark_gray').'Run: /warp sunkencitygolf',
		),
	),
);
@menu[20] = array(
	name: 'JUNGLE_LOG',
	meta: array(
		display: color('yellow').'Island Golf',
		lore: array(
			color('white').'Minigolf course across many biomes (1 - 4 players)',
			color('dark_gray').'Run: /warp islandgolf',
		),
	),
);
@menu[21] = array(
	name: 'RED_SANDSTONE',
	meta: array(
		display: color('gold').'FrostBurn Golf',
		lore: array(
			color('white').'Minigolf course in a badlands fort (1 - 4 players)',
			color('dark_gray').'Run: /warp frostburn',
		),
	),
);
@menu[27] = array(
	name: 'ICE',
	meta: array(
		display: color('aqua').'Arctic Race',
		lore: array(
			color('white').'Race boats along treacherous icebergs.',
			color('white').'(2+ players)',
			color('dark_gray').'Run: /warp arctic',
		)
	),
);
@menu[28] = array(
	name: 'HAY_BLOCK',
	meta: array(
		display: color('aqua').'Pig Race',
		lore: array(
			color('white').'Race finnicky pigs around a small course.',
			color('white').'(2+ players)',
			color('dark_gray').'Run: /warp pigrace',
		)
	),
);
delete_virtual_inventory('other-games');
create_virtual_inventory('other-games', @rows * 9 + 9, 'Other Games and Attractions', @menu);
