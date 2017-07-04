// A list of reasonably obtainable items in the overworld.
// This means it can't depend on mobs spawned in the nether/end, or items in chests.
// It does include any blocks that may have been placed in the overworld.
// Do not include blocks that require silk touch.
// Do not include confusing variants with the same material. (eg. ACACIA_DOOR_ITEM)
@items = array(
	'WORKBENCH',
	'DIRT',
	'COBBLESTONE',
	'SAND',
	'GRAVEL',
	'GOLD_ORE',
	'IRON_ORE',
	'SPONGE',
	'GLASS',
	'LAPIS_BLOCK',
	'DISPENSER',
	'SANDSTONE',
	'NOTE_BLOCK',
	'POWERED_RAIL',
	'DETECTOR_RAIL',
	'PISTON_STICKY_BASE',
	'WEB',
	'DEAD_BUSH',
	'PISTON_BASE',
	'WOOL',
	'YELLOW_FLOWER',
	'BROWN_MUSHROOM',
	'RED_MUSHROOM',
	'GOLD_BLOCK',
	'IRON_BLOCK',
	'BRICK',
	'TNT',
	'BOOKSHELF',
	'MOSSY_COBBLESTONE',
	'OBSIDIAN',
	'TORCH',
	'WOOD_STAIRS',
	'CHEST',
	'DIAMOND_BLOCK',
	'FURNACE',
	'LADDER',
	'RAILS',
	'COBBLESTONE_STAIRS',
	'LEVER',
	'STONE_PLATE',
	'WOOD_PLATE',
	'REDSTONE_TORCH_ON',
	'STONE_BUTTON',
	'SNOW',
	'SNOW_BLOCK',
	'CACTUS',
	'CLAY',
	'JUKEBOX',
	'FENCE',
	'PUMPKIN',
	'NETHERRACK',
	'SOUL_SAND',
	'GLOWSTONE',
	'JACK_O_LANTERN',
	'TRAP_DOOR',
	'SMOOTH_BRICK',
	'IRON_FENCE',
	'THIN_GLASS',
	'MELON_BLOCK',
	'VINE',
	'FENCE_GATE',
	'BRICK_STAIRS',
	'SMOOTH_STAIRS',
	'WATER_LILY',
	'NETHER_BRICK',
	'NETHER_FENCE',
	'NETHER_BRICK_STAIRS',
	'ENCHANTMENT_TABLE',
	'ENDER_STONE',
	'DRAGON_EGG',
	'REDSTONE_LAMP_OFF',
	'SANDSTONE_STAIRS',
	'TRIPWIRE_HOOK',
	'EMERALD_BLOCK',
	'SPRUCE_WOOD_STAIRS',
	'BIRCH_WOOD_STAIRS',
	'JUNGLE_WOOD_STAIRS',
	'BEACON',
	'COBBLE_WALL',
	'WOOD_BUTTON',
	'ANVIL',
	'TRAPPED_CHEST',
	'GOLD_PLATE',
	'IRON_PLATE',
	'DAYLIGHT_DETECTOR',
	'REDSTONE_BLOCK',
	'HOPPER',
	'QUARTZ_BLOCK',
	'QUARTZ_STAIRS',
	'ACTIVATOR_RAIL',
	'DROPPER',
	'ACACIA_STAIRS',
	'DARK_OAK_STAIRS',
	'SLIME_BLOCK',
	'IRON_TRAPDOOR',
	'PRISMARINE',
	'HAY_BLOCK',
	'HARD_CLAY',
	'COAL_BLOCK',
	'RED_SANDSTONE',
	'RED_SANDSTONE_STAIRS',
	'SPRUCE_FENCE_GATE',
	'BIRCH_FENCE_GATE',
	'JUNGLE_FENCE_GATE',
	'DARK_OAK_FENCE_GATE',
	'ACACIA_FENCE_GATE',
	'SPRUCE_FENCE',
	'BIRCH_FENCE',
	'JUNGLE_FENCE',
	'DARK_OAK_FENCE',
	'ACACIA_FENCE',
	'END_ROD',
	'CHORUS_FLOWER',
	'PURPUR_BLOCK',
	'PURPUR_PILLAR',
	'PURPUR_STAIRS',
	'PURPUR_SLAB',
	'END_BRICKS',
	'MAGMA',
	'NETHER_WART_BLOCK',
	'RED_NETHER_BRICK',
	'BONE_BLOCK',
	'OBSERVER',
	'WHITE_GLAZED_TERRACOTTA',
	'ORANGE_GLAZED_TERRACOTTA',
	'MAGENTA_GLAZED_TERRACOTTA',
	'LIGHT_BLUE_GLAZED_TERRACOTTA',
	'YELLOW_GLAZED_TERRACOTTA',
	'LIME_GLAZED_TERRACOTTA',
	'PINK_GLAZED_TERRACOTTA',
	'GRAY_GLAZED_TERRACOTTA',
	'SILVER_GLAZED_TERRACOTTA',
	'CYAN_GLAZED_TERRACOTTA',
	'PURPLE_GLAZED_TERRACOTTA',
	'BLUE_GLAZED_TERRACOTTA',
	'BROWN_GLAZED_TERRACOTTA',
	'GREEN_GLAZED_TERRACOTTA',
	'RED_GLAZED_TERRACOTTA',
	'BLACK_GLAZED_TERRACOTTA',
	'CONCRETE',
	'CONCRETE_POWDER',
	'IRON_SPADE',
	'IRON_PICKAXE',
	'IRON_AXE',
	'FLINT_AND_STEEL',
	'APPLE',
	'BOW',
	'ARROW',
	'COAL',
	'DIAMOND',
	'IRON_INGOT',
	'GOLD_INGOT',
	'IRON_SWORD',
	'WOOD_SWORD',
	'WOOD_SPADE',
	'WOOD_PICKAXE',
	'WOOD_AXE',
	'STONE_SWORD',
	'STONE_SPADE',
	'STONE_PICKAXE',
	'STONE_AXE',
	'DIAMOND_SWORD',
	'DIAMOND_SPADE',
	'DIAMOND_PICKAXE',
	'DIAMOND_AXE',
	'STICK',
	'BOWL',
	'MUSHROOM_SOUP',
	'GOLD_SWORD',
	'GOLD_SPADE',
	'GOLD_PICKAXE',
	'GOLD_AXE',
	'STRING',
	'FEATHER',
	'SULPHUR',
	'WOOD_HOE',
	'STONE_HOE',
	'IRON_HOE',
	'DIAMOND_HOE',
	'GOLD_HOE',
	'SEEDS',
	'WHEAT',
	'BREAD',
	'LEATHER_HELMET',
	'LEATHER_CHESTPLATE',
	'LEATHER_LEGGINGS',
	'LEATHER_BOOTS',
	'IRON_HELMET',
	'IRON_CHESTPLATE',
	'IRON_LEGGINGS',
	'IRON_BOOTS',
	'DIAMOND_HELMET',
	'DIAMOND_CHESTPLATE',
	'DIAMOND_LEGGINGS',
	'DIAMOND_BOOTS',
	'GOLD_HELMET',
	'GOLD_CHESTPLATE',
	'GOLD_LEGGINGS',
	'GOLD_BOOTS',
	'FLINT',
	'PORK',
	'GRILLED_PORK',
	'PAINTING',
	'GOLDEN_APPLE',
	'SIGN',
	'WOOD_DOOR',
	'BUCKET',
	'WATER_BUCKET',
	'EXP_BOTTLE',
	'LAVA_BUCKET',
	'MINECART',
	'SADDLE',
	'IRON_DOOR',
	'REDSTONE',
	'SNOW_BALL',
	'BOAT',
	'LEATHER',
	'MILK_BUCKET',
	'CLAY_BRICK',
	'CLAY_BALL',
	'SUGAR_CANE',
	'PAPER',
	'BOOK',
	'SLIME_BALL',
	'STORAGE_MINECART',
	'POWERED_MINECART',
	'EGG',
	'COMPASS',
	'FISHING_ROD',
	'WATCH',
	'GLOWSTONE_DUST',
	'RAW_FISH',
	'COOKED_FISH',
	'BONE',
	'SUGAR',
	'CAKE',
	'BED',
	'DIODE',
	'COOKIE',
	'MAP',
	'SHEARS',
	'MELON',
	'PUMPKIN_SEEDS',
	'MELON_SEEDS',
	'RAW_BEEF',
	'COOKED_BEEF',
	'RAW_CHICKEN',
	'COOKED_CHICKEN',
	'ROTTEN_FLESH',
	'ENDER_PEARL',
	'GOLD_NUGGET',
	'NETHER_STALK',
	'POTION',
	'GLASS_BOTTLE',
	'SPIDER_EYE',
	'FERMENTED_SPIDER_EYE',
	'BREWING_STAND_ITEM',
	'CAULDRON_ITEM',
	'SPECKLED_MELON',
	'BOOK_AND_QUILL',
	'WRITTEN_BOOK',
	'EMERALD',
	'ITEM_FRAME',
	'FLOWER_POT_ITEM',
	'CARROT_ITEM',
	'POTATO_ITEM',
	'BAKED_POTATO',
	'POISONOUS_POTATO',
	'GOLDEN_CARROT',
	'SKULL_ITEM',
	'CARROT_STICK',
	'PUMPKIN_PIE',
	'FIREWORK',
	'FIREWORK_CHARGE',
	'REDSTONE_COMPARATOR',
	'NETHER_BRICK_ITEM',
	'EXPLOSIVE_MINECART',
	'HOPPER_MINECART',
	'PRISMARINE_CRYSTALS',
	'RABBIT',
	'COOKED_RABBIT',
	'RABBIT_STEW',
	'RABBIT_FOOT',
	'RABBIT_HIDE',
	'ARMOR_STAND',
	'LEASH',
	'NAME_TAG',
	'MUTTON',
	'COOKED_MUTTON',
	'SPRUCE_DOOR_ITEM',
	'BIRCH_DOOR_ITEM',
	'JUNGLE_DOOR_ITEM',
	'ACACIA_DOOR_ITEM',
	'DARK_OAK_DOOR_ITEM',
	'CHORUS_FRUIT',
	'CHORUS_FRUIT_POPPED',
	'BEETROOT',
	'BEETROOT_SEEDS',
	'BEETROOT_SOUP',
	'SPLASH_POTION',
	'SPECTRAL_ARROW',
	'TIPPED_ARROW',
	'SHIELD',
	'BOAT_SPRUCE',
	'BOAT_BIRCH',
	'BOAT_JUNGLE',
	'BOAT_ACACIA',
	'BOAT_DARK_OAK',
	'IRON_NUGGET',
);

// 5x5 grid of random items
@card = array();
for(@i = 0, @i < 5, @i++) {
	@card[@i] = array();
	for(@j = 0, @j < 5, @j++) {
		@index = array_rand(@items, 1)[0];
		@card[@i][@j] = array('players': array(), 'material': @items[@index]);
		array_remove(@items, @index);
	}
}
export('shard.bingocard', @card);

// Scoreboard
create_objective('inarow', 'DUMMY', 'shard');
set_objective_display('inarow', array('slot': 'SIDEBAR', 'displayname': 'In a Row (5)'), 'shard');
create_objective('reroll', 'DUMMY', 'shard');

proc _bingo_win(@player) {
	_worldmsg('shard', color('green').@player.' wins!');
	launch_firework(ploc(@player), array('strength': 3, 'type': 'BALL_LARGE', 'flicker': true));
	set_timeout(20000, closure(){
		_unload_shard();
	});
}

proc _refresh_card() {
	@card = import('shard.bingocard');
	@chest = array(
		'title': 'Bingo Card',
		'size': 45,
	);
	
	// Personalize chests per player
	foreach(@p in all_players('shard')) {
		for(@i = 0, @i < 5, @i++) {
			for(@j = 0, @j < 5, @j++) {
				@item = @card[@i][@j];
				@size = array_size(@item['players']);
				if(array_contains(@item['players'], @p)) {
					@chest[2 + @i + (@j * 9)] = array('name': 'STAINED_GLASS_PANE', 'data': 14,
							'qty': array_size(@item['players']), 'meta': array('display': 'ACHIEVED'));
				} else if(@size == 1) {
					@chest[2 + @i + (@j * 9)] = array('name': @item['material'], 'meta': array(
							'enchants': array(array('elevel': 1, 'etype': 'DAMAGE_ALL')), 'flags': array('HIDE_ENCHANTS')));
				} else if(@size == 0) {
					@chest[2 + @i + (@j * 9)] = array('name': @item['material']);
				} else {
					@chest[2 + @i + (@j * 9)] = array('name': @item['material'], 'qty': array_size(@item['players']));
				}
			}
		}
		@chest['id'] = @p.'bingo';
		create_virtualchest(@chest);
	}
}

proc _check_card(@player, @row, @column) {
	@card = import('shard.bingocard');
	@range = range(5);
	// Check horizontal/vertical
	@foundRow = 0;
	foreach(@i in @range) {
		if(array_contains(@card[@row][@i]['players'], @player)) {
			@foundRow++;
		}
	}
	@foundColumn = 0;
	foreach(@i in @range) {
		if(array_contains(@card[@i][@column]['players'], @player)) {
			@foundColumn++;
		}
	}
	// Check diagonal
	@foundDiagDown = 0;
	foreach(@i in @range) {
		if(array_contains(@card[@i][@i]['players'], @player)) {
			@foundDiagDown++;
		}
	}
	@foundDiagUp = 0;
	foreach(@i in @range) {
		if(array_contains(@card[@i][4 - @i]['players'], @player)) {
			@foundDiagUp++;
		}
	}
	@score = max(@foundRow, @foundColumn, @foundDiagDown, @foundDiagUp);
	set_pscore('inarow', @player, @score, 'shard');
	if(@score == 5) {
		_bingo_win(@player);
	}
}

@binds[] = 'shard-bingo-worldchanged';
bind(world_changed, array('id': 'shard-bingo-worldchanged', 'priority': 'LOW'), array('to': 'shard'), @event) {
	queue_push(closure(){
		pgive_item(player(), 395, 1, array('display': 'Bingo Card'));
		_refresh_card();
	}, 'shard');
}

@binds[] = 'shard-bingo-playerinteract';
bind(player_interact, array('id': 'shard-bingo-playerinteract'), array('item': 395, 'button': 'right'), @event) {
	if(pworld() == 'shard') {
		cancel();
		popen_virtualchest(player().'bingo');
	}
}

@binds[] = 'shard-bingo-inventoryclick';
bind(inventory_click, array('id': 'shard-bingo-inventoryclick'), null, @event, @items) {
	if(pget_virtualchest() == player().'bingo' && @event['slotitem'])
	 	if(!get_pscore('reroll', player(), 'shard')) {
			die('You\'ve re-rolled an item already.');
		}
		@material = @event['slotitem']['name'];
		@card = import('shard.bingocard');
		for(@i = 0, @i < 5, @i++) {
			for(@j = 0, @j < 5, @j++) {
				if(@card[@i][@j]['material'] == @material && array_size(@card[@i][@j]['players']) == 0) {
					@newmaterial = array_rand(@items, 1, false)[0];
					@card[@i][@j] = array('players': array(), 'material': @newmaterial);
					set_pscore('reroll', player(), 1, 'shard');
					_refresh_card();
					_worldmsg('shard', player().' re-rolled '.@material.' and got '.@newmaterial.'.');
					die();
				}
			}
		}
		msg('Someone already got that item!');
	}
}

@binds[] = 'shard-bingo-itempickup';
bind(item_pickup, array('id': 'shard-bingo-itempickup'), null, @event, @card) {
	if(pworld() == 'shard') {
		@thisMaterial = @event['item']['name'];
		for(@i = 0, @i < 5, @i++) {
			for(@j = 0, @j < 5, @j++) {
				@item = @card[@i][@j];
				if(@item['material'] == @thisMaterial && !array_contains(@item['players'], player())) {
					if(@event['item']['qty'] > 1) {
						@event['item']['qty']--;
						modify_event('item', @event['item']);
					} else {
						modify_event('item', null);
					}
					@item['players'][] = player();
					launch_firework(ploc());
					_worldmsg('shard', player().' found 'color('green').'['.@event['item']['name'].']');
					_refresh_card();
					_check_card(player(), @i, @j);
				}
			}
		}
	}
}
