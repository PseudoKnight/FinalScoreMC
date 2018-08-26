proc _get_options() {
	return(array(
		'level': 9,
		'maxRoomHeight': 9,
	));
}

proc _set_locations(@start, @end, @spawns){
	set_ploc(@start);
	
	set_block(@end, 'BEACON', false);
}

proc _get_loot(@level, @random, @loot = array(

	array('chance': 0.60, 'item': array('name': 'TORCH', 'qty': array(1, 16))),
	array('chance': 0.40, 'item': array('name': 'BREAD', 'qty': array(1, 4))),
	array('chance': 0.35, 'item': array('name': 'GOLDEN_APPLE')),
	array('chance': 0.15, 'item': array('name': 'ARROW', 'qty': array(1, 6))),
	array('chance': 0.07, 'item': array('name': 'WOODEN_SWORD')),
	array('chance': 0.05, 'item': array('name': 'STONE_SWORD'), 'data': 132),
	array('chance': 0.03, 'item': array('name': 'GOLDEN_SWORD'), 'data': 33),
	array('chance': -0.01, 'item': array('name': 'IRON_SWORD'), 'data': 251),
	array('chance': -0.02, 'item': array('name': 'DIAMOND_SWORD'), 'data': 1562),
	array('chance': 0.07, 'item': array('name': 'WOODEN_AXE')),
	array('chance': 0.05, 'item': array('name': 'STONE_AXE'), 'data': 132),
	array('chance': -0.01, 'item': array('name': 'IRON_AXE'), 'data': 251),
	array('chance': -0.02, 'item': array('name': 'DIAMOND_AXE'), 'data': 1562),
	array('chance': 0.03, 'item': array('name': 'BOW'), 'data': 385),
	array('chance': 0.06, 'item': array('name': 'LEATHER_HELMET')),
	array('chance': 0.06, 'item': array('name': 'LEATHER_CHESTPLATE')),
	array('chance': 0.06, 'item': array('name': 'LEATHER_LEGGINGS')),
	array('chance': 0.06, 'item': array('name': 'LEATHER_BOOTS')),
	array('chance': 0.04, 'item': array('name': 'GOLDEN_HELMET')),
	array('chance': 0.04, 'item': array('name': 'GOLDEN_CHESTPLATE')),
	array('chance': 0.04, 'item': array('name': 'GOLDEN_LEGGINGS')),
	array('chance': 0.04, 'item': array('name': 'GOLDEN_BOOTS')),
	array('chance': 0.02, 'item': array('name': 'CHAINMAIL_HELMET'), 'data': 166),
	array('chance': 0.02, 'item': array('name': 'CHAINMAIL_CHESTPLATE'), 'data': 241),
	array('chance': 0.02, 'item': array('name': 'CHAINMAIL_LEGGINGS'), 'data': 226),
	array('chance': 0.02, 'item': array('name': 'CHAINMAIL_BOOTS'), 'data': 196),
	array('chance': -0.00, 'item': array('name': 'IRON_HELMET'), 'data': 166),
	array('chance': -0.00, 'item': array('name': 'IRON_CHESTPLATE'), 'data': 241),
	array('chance': -0.00, 'item': array('name': 'IRON_LEGGINGS'), 'data': 226),
	array('chance': -0.00, 'item': array('name': 'IRON_BOOTS'), 'data': 166),
	array('chance': -0.02, 'item': array('name': 'DIAMOND_HELMET'), 'data': 364),
	array('chance': -0.02, 'item': array('name': 'DIAMOND_CHESTPLATE'), 'data': 529),
	array('chance': -0.02, 'item': array('name': 'DIAMOND_LEGGINGS'), 'data': 496),
	array('chance': -0.02, 'item': array('name': 'DIAMOND_BOOTS'), 'data': 430),
	array('chance': 0.00, 'item': array('name': 'TOTEM_OF_UNDYING')),
	array('chance': 0.01, 'item': array('name': 'GOLDEN_CARROT', 'qty': array(1, 4))),
	array('chance': 0.01, 'item': array('name': 'SHIELD'), 'data': 336),
	array('chance': 0.01, 'item': array('name': 'LAPIS_LAZULI', 'qty': array(1, 4))),
)) {
	@inv = array();
	foreach(@weightedLoot in @loot){
		if(srand(@random) < @weightedLoot['chance'] + @level * 0.01){
			@item = @weightedLoot['item'][];
			if(array_index_exists(@item, 'qty') && is_array(@item['qty'])) {
				@item['qty'] = integer(srand(@random) * (@item['qty'][1] - @item['qty'][0]) + @item['qty'][0]);
			}
			if(array_index_exists(@weightedLoot, 'data')) {
				@item['meta'] = array('damage': integer(srand(@random) * @weightedLoot['data']));
			}
			@inv[] = @item;
		}
	}
	return(@inv);
}

proc _materials(@level) {
	switch(@level) {
		case 0:
			return(array(
				'empty': 'BEDROCK',
				'wall': array('STONE', 'STONE', 'STONE', 'STONE', 'STONE', 'STONE', 'STONE', 'STONE', 'ANDESITE', 'ANDESITE', 'ANDESITE', 'IRON_ORE'),
				'room': 'AIR',
				'door': 'AIR',
				'column': 'STONE',
				'ladder': 'LADDER',
				'ceiling': array('STONE', 'STONE', 'STONE', 'STONE', 'STONE', 'STONE', 'STONE', 'STONE', 'ANDESITE', 'ANDESITE', 'ANDESITE', 'IRON_ORE'),
				'floor': array('STONE', 'STONE', 'STONE', 'STONE', 'STONE', 'STONE', 'STONE', 'STONE', 'ANDESITE', 'ANDESITE', 'ANDESITE', 'IRON_ORE'),
				'utility': array('GOLD_ORE'),
				'decor': array('STONE'),
				'edge': array('STONE', 'STONE', 'STONE', 'STONE'),
			));
		case 1:
			return(array(
				'empty': 'BEDROCK',
				'wall': array('ACACIA_LOG'),
				'room': 'AIR',
				'door': 'AIR',
				'column': 'DARK_OAK_LOG',
				'ladder': 'LADDER',
				'ceiling': array('BIRCH_LEAVES', 'DARK_OAK_LEAVES'),
				'floor': array('GRASS_BLOCK', 'PODZOL'),
				'utility': array('CRAFTING_TABLE'),
				'decor': array('BIRCH_LEAVES', 'COBWEB'),
				'edge': array('ACACIA_LEAVES', 'ACACIA_LEAVES', 'ACACIA_LEAVES', 'ACACIA_LEAVES'),
			));
		case 2:
			return(array(
				'empty': 'BEDROCK',
				'wall': array('SANDSTONE', 'SMOOTH_SANDSTONE'),
				'room': 'AIR',
				'door': 'AIR',
				'column': 'CHISELED_SANDSTONE',
				'ladder': 'LADDER',
				'ceiling': array('SANDSTONE'),
				'floor': array('TERRACOTTA'),
				'utility': array('CRAFTING_TABLE'),
				'decor': array('DEAD_BUSH'),
				'edge': array('SANDSTONE_STAIRS', 'SANDSTONE_STAIRS', 'SANDSTONE_STAIRS', 'SANDSTONE_STAIRS'),
			));
		case 3:
			return(array(
				'empty': 'BEDROCK',
				'wall': array('SNOW_BLOCK', 'PACKED_ICE'),
				'room': 'AIR',
				'door': 'AIR',
				'column': 'PACKED_ICE',
				'ladder': 'LADDER',
				'ceiling': array('SNOW_BLOCK', 'PACKED_ICE'),
				'floor': array('SNOW_BLOCK', 'PACKED_ICE'),
				'utility': array('CRAFTING_TABLE'),
				'decor': array('PACKED_ICE'),
				'edge': array('SNOW_BLOCK', 'SNOW_BLOCK', 'SNOW_BLOCK', 'SNOW_BLOCK'),
			));
		case 4:
			return(array(
				'empty': 'BEDROCK',
				'wall': array('NETHER_BRICKS'),
				'room': 'AIR',
				'door': 'AIR',
				'column': 'NETHER_BRICK_FENCE',
				'ladder': 'LADDER',
				'ceiling': array('NETHER_BRICKS'),
				'floor': array('NETHER_BRICKS', 'NETHER_BRICKS', 'NETHER_BRICKS', 'NETHER_BRICKS', 'NETHER_BRICKS', 'NETHER_BRICKS', 'MAGMA_BLOCK', 'SOUL_SAND'),
				'utility': array('FURNACE', 'DAMAGED_ANVIL'),
				'decor': array('CAULDRON'),
				'edge': array('NETHER_BRICK_STAIRS', 'NETHER_BRICK_STAIRS', 'NETHER_BRICK_STAIRS', 'NETHER_BRICK_STAIRS'),
			));
		case 5:
			return(array(
				'empty': 'BEDROCK',
				'wall': array('POLISHED_ANDESITE', 'STONE_BRICKS', 'MOSSY_STONE_BRICKS', 'CRACKED_STONE_BRICKS', 'INFESTED_CRACKED_STONE_BRICKS'),
				'room': 'AIR',
				'door': 'AIR',
				'column': 'BOOKSHELF',
				'ladder': 'LADDER',
				'ceiling': array('STONE_BRICKS'),
				'floor': array('MOSSY_STONE_BRICKS', 'MOSSY_STONE_BRICKS', 'MOSSY_STONE_BRICKS', 'MOSSY_STONE_BRICKS', 'MOSSY_STONE_BRICKS', 'MOSSY_STONE_BRICKS', 'CRACKED_STONE_BRICKS', 'CRACKED_STONE_BRICKS', 'WATER'),
				'utility': array('CRAFTING_TABLE', 'ENCHANTING_TABLE', 'BREWING_STAND', 'CAULDRON'),
				'decor': array('RAIL'),
				'edge': array('STONE_BRICK_STAIRS', 'STONE_BRICK_STAIRS', 'STONE_BRICK_STAIRS', 'STONE_BRICK_STAIRS'),
			));
		case 6:
			return(array(
				'empty': 'BEDROCK',
				'wall': array('PRISMARINE_BRICKS'),
				'room': 'WATER',
				'door': 'WATER',
				'column': 'PRISMARINE_BRICKS',
				'ladder': 'LADDER',
				'ceiling': array('PRISMARINE'),
				'floor': array('DARK_PRISMARINE'),
				'utility': array('SEA_LANTERN'),
				'decor': array('SEA_LANTERN'),
				'edge': array('DARK_PRISMARINE_STAIRS', 'DARK_PRISMARINE_STAIRS', 'DARK_PRISMARINE_STAIRS', 'DARK_PRISMARINE_STAIRS'),
			));
		case 7:
			return(array(
				'empty': 'BEDROCK',
				'wall': array('DARK_OAK_PLANKS'),
				'room': 'AIR',
				'door': 'AIR',
				'column': 'COBBLSTONE_WALL',
				'ladder': 'LADDER',
				'ceiling': array('BIRCH_PLANKS'),
				'floor': array('BIRCH_PLANKS'),
				'utility': array('ENCHANTING_TABLE'),
				'decor': array('BOOKSHELF'),
				'edge': array('BIRCH_STAIRS', 'BIRCH_STAIRS', 'BIRCH_STAIRS', 'BIRCH_STAIRS'),
			));
		default:
			return(array(
				'empty': 'BEDROCK',
				'wall': array('PURPUR_BLOCK'),
				'room': 'AIR',
				'door': 'AIR',
				'column': 'PURPUR_PILLAR',
				'ladder': 'LADDER',
				'ceiling': array('PURPUR_BLOCK'),
				'floor': array('END_STONE'),
				'utility': array('ENCHANTING_TABLE'),
				'decor': array('CHORUS_PLANT'),
				'edge': array('PURPUR_STAIRS', 'PURPUR_STAIRS', 'PURPUR_STAIRS', 'PURPUR_STAIRS'),
			));
	}
}

proc _level_mobs(@level) {
	switch(@level) {
		case 0:
			return(array());
		case 1:
			return(array('CAVE_SPIDER', 'SPIDER'));
		case 2:
			return(array('ENDER_CRYSTAL', 'ZOMBIE_VILLAGER'));
		case 3:
			return(array());
		case 4:
			return(array('PIG_ZOMBIE', 'MAGMA_CUBE', 'BLAZE'));
		case 5:
			return(array('ENDER_CRYSTAL', 'SKELETON', 'WITCH', 'CREEPER'));
		case 6:
			return(array('GUARDIAN'));
		case 7:
			return(array('VINDICATOR'));
		default:
			return(array('ENDER_CRYSTAL', 'ENDERMITE', 'ENDERMAN', 'SHULKER'));
	}
}

proc _spawn_entity(@loc, @level) {
	noop();
}
