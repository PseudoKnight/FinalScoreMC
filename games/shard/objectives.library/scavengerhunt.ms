proc _objective_load(@binds, @rules) {
	// A list of reasonably obtainable items.
	// DO NOT include items only found in chests.
	// DO NOT include blocks that require silk touch.
	// DO NOT include shiny items. (can be confused with obtained/locked items)

	// Common items include blocks or items that can be obtained or crafted from common natural overworld blocks/entities in 1.7.2.
	@commonItems = array(
		'ACACIA_BOAT',
		'ACACIA_BUTTON',
		'ACACIA_CHEST_BOAT',
		'ACACIA_DOOR',
		'ACACIA_FENCE',
		'ACACIA_FENCE_GATE',
		'ACACIA_HANGING_SIGN',
		'ACACIA_LEAVES',
		'ACACIA_LOG',
		'ACACIA_PLANKS',
		'ACACIA_PRESSURE_PLATE',
		'ACACIA_SAPLING',
		'ACACIA_SHELF',
		'ACACIA_SIGN',
		'ACACIA_SLAB',
		'ACACIA_STAIRS',
		'ACACIA_TRAPDOOR',
		'ACACIA_WOOD',
		'ACTIVATOR_RAIL',
		'ALLIUM',
		'ANVIL',
		'APPLE',
		'ARMADILLO_SCUTE',
		'ARMOR_STAND',
		'ARROW',
		'AXOLOTL_BUCKET',
		'AZURE_BLUET',
		'BAKED_POTATO',
		'BARREL',
		'BEACON',
		'BEEF',
		'BIRCH_BOAT',
		'BIRCH_BUTTON',
		'BIRCH_CHEST_BOAT',
		'BIRCH_DOOR',
		'BIRCH_FENCE',
		'BIRCH_FENCE_GATE',
		'BIRCH_HANGING_SIGN',
		'BIRCH_LEAVES',
		'BIRCH_LOG',
		'BIRCH_PLANKS',
		'BIRCH_PRESSURE_PLATE',
		'BIRCH_SAPLING',
		'BIRCH_SHELF',
		'BIRCH_SIGN',
		'BIRCH_SLAB',
		'BIRCH_STAIRS',
		'BIRCH_TRAPDOOR',
		'BIRCH_WOOD',
		'BLACK_BANNER',
		'BLACK_BED',
		'BLACK_BUNDLE',
		'BLACK_CARPET',
		'BLACK_CONCRETE',
		'BLACK_CONCRETE_POWDER',
		'BLACK_DYE',
		'BLACK_GLAZED_TERRACOTTA',
		'BLACK_HARNESS',
		'BLACK_STAINED_GLASS',
		'BLACK_TERRACOTTA',
		'BLACK_WOOL',
		'BLAST_FURNACE',
		'BLUE_BANNER',
		'BLUE_BED',
		'BLUE_BUNDLE',
		'BLUE_CARPET',
		'BLUE_CONCRETE',
		'BLUE_CONCRETE_POWDER',
		'BLUE_DYE',
		'BLUE_GLAZED_TERRACOTTA',
		'BLUE_HARNESS',
		'BLUE_ICE',
		'BLUE_ORCHID',
		'BLUE_STAINED_GLASS',
		'BLUE_TERRACOTTA',
		'BLUE_WOOL',
		'BONE',
		'BONE_BLOCK',
		'BONE_MEAL',
		'BOOK',
		'BOOKSHELF',
		'BORDURE_INDENTED_BANNER_PATTERN',
		'BOW',
		'BOWL',
		'BREAD',
		'BREWING_STAND',
		'BRICK',
		'BRICKS',
		'BRICK_SLAB',
		'BRICK_STAIRS',
		'BRICK_WALL',
		'BROWN_BANNER',
		'BROWN_BED',
		'BROWN_BUNDLE',
		'BROWN_CARPET',
		'BROWN_CONCRETE',
		'BROWN_CONCRETE_POWDER',
		'BROWN_DYE',
		'BROWN_GLAZED_TERRACOTTA',
		'BROWN_HARNESS',
		'BROWN_MUSHROOM',
		'BROWN_STAINED_GLASS',
		'BROWN_TERRACOTTA',
		'BROWN_WOOL',
		'BRUSH',
		'BUCKET',
		'BUNDLE',
		'CACTUS',
		'CAKE',
		'CAMPFIRE',
		'CARROT',
		'CARROT_ON_A_STICK',
		'CARTOGRAPHY_TABLE',
		'CARVED_PUMPKIN',
		'CAULDRON',
		'CHARCOAL',
		'CHEST',
		'CHEST_MINECART',
		'CHICKEN',
		'CHIPPED_ANVIL',
		'CHISELED_COPPER',
		'CHISELED_BOOKSHELF',
		'CHISELED_DEEPSLATE',
		'CHISELED_NETHER_BRICKS',
		'CHISELED_RED_SANDSTONE',
		'CHISELED_SANDSTONE',
		'CHISELED_STONE_BRICKS',
		'CLAY',
		'CLAY_BALL',
		'CLOCK',
		'COAL',
		'COAL_BLOCK',
		'COARSE_DIRT',
		'COBBLED_DEEPSLATE',
		'COBBLED_DEEPSLATE_WALL',
		'COBBLED_DEEPSLATE_SLAB',
		'COBBLED_DEEPSLATE_STAIRS',
		'COBBLESTONE',
		'COBBLESTONE_SLAB',
		'COBBLESTONE_STAIRS',
		'COBBLESTONE_WALL',
		'COBWEB',
		'COCOA_BEANS',
		'COD',
		'COD_BUCKET',
		'COMPARATOR',
		'COMPASS',
		'COMPOSTER',
		'COOKED_BEEF',
		'COOKED_CHICKEN',
		'COOKED_COD',
		'COOKED_MUTTON',
		'COOKED_PORKCHOP',
		'COOKED_RABBIT',
		'COOKED_SALMON',
		'COOKIE',
		'COPPER_AXE',
		'COPPER_BARS',
		'COPPER_BOOTS',
		'COPPER_BLOCK',
		'COPPER_BULB',
		'COPPER_CHAIN',
		'COPPER_CHEST',
		'COPPER_CHESTPLATE',
		'COPPER_DOOR',
		'COPPER_GRATE',
		'COPPER_HELMET',
		'COPPER_HOE',
		'COPPER_INGOT',
		'COPPER_LANTERN',
		'COPPER_LEGGINGS',
		'COPPER_NUGGET',
		'COPPER_ORE',
		'COPPER_PICKAXE',
		'COPPER_SHOVEL',
		'COPPER_SWORD',
		'COPPER_TORCH',
		'COPPER_TRAPDOOR',
		'CRACKED_STONE_BRICKS',
		'CRAFTER',
		'CRAFTING_TABLE',
		'CREEPER_HEAD',
		'CROSSBOW',
		'CUT_COPPER',
		'CUT_COPPER_SLAB',
		'CUT_COPPER_STAIRS',
		'CUT_RED_SANDSTONE',
		'CUT_RED_SANDSTONE_SLAB',
		'CUT_SANDSTONE',
		'CUT_SANDSTONE_SLAB',
		'CYAN_BANNER',
		'CYAN_BED',
		'CYAN_BUNDLE',
		'CYAN_CARPET',
		'CYAN_CONCRETE',
		'CYAN_CONCRETE_POWDER',
		'CYAN_DYE',
		'CYAN_GLAZED_TERRACOTTA',
		'CYAN_HARNESS',
		'CYAN_STAINED_GLASS',
		'CYAN_TERRACOTTA',
		'CYAN_WOOL',
		'CRACKED_NETHER_BRICKS',
		'CRACKED_DEEPSLATE_BRICKS',
		'CRACKED_DEEPSLATE_TILES',
		'DAMAGED_ANVIL',
		'DANDELION',
		'DARK_OAK_BOAT',
		'DARK_OAK_BUTTON',
		'DARK_OAK_CHEST_BOAT',
		'DARK_OAK_DOOR',
		'DARK_OAK_FENCE',
		'DARK_OAK_FENCE_GATE',
		'DARK_OAK_HANGING_SIGN',
		'DARK_OAK_LEAVES',
		'DARK_OAK_LOG',
		'DARK_OAK_PLANKS',
		'DARK_OAK_PRESSURE_PLATE',
		'DARK_OAK_SAPLING',
		'DARK_OAK_SHELF',
		'DARK_OAK_SIGN',
		'DARK_OAK_SLAB',
		'DARK_OAK_STAIRS',
		'DARK_OAK_TRAPDOOR',
		'DARK_OAK_WOOD',
		'DAYLIGHT_DETECTOR',
		'DEAD_BUSH',
		'DECORATED_POT',
		'DEEPSLATE',
		'DEEPSLATE_BRICK_WALL',
		'DEEPSLATE_BRICK_SLAB',
		'DEEPSLATE_BRICK_STAIRS',
		'DEEPSLATE_BRICKS',
		'DEEPSLATE_TILE_WALL',
		'DEEPSLATE_TILE_SLAB',
		'DEEPSLATE_TILE_STAIRS',
		'DEEPSLATE_TILES',
		'DETECTOR_RAIL',
		'DIAMOND',
		'DIAMOND_AXE',
		'DIAMOND_BLOCK',
		'DIAMOND_BOOTS',
		'DIAMOND_CHESTPLATE',
		'DIAMOND_HELMET',
		'DIAMOND_HOE',
		'DIAMOND_HORSE_ARMOR',
		'DIAMOND_LEGGINGS',
		'DIAMOND_PICKAXE',
		'DIAMOND_SHOVEL',
		'DIAMOND_SWORD',
		'DIRT',
		'DISPENSER',
		'DRIED_KELP',
		'DRIED_KELP_BLOCK',
		'DRIPSTONE_BLOCK',
		'DROPPER',
		'EGG',
		'EMERALD',
		'EMERALD_BLOCK',
		'ENCHANTING_TABLE',
		'ENDER_PEARL',
		'EXPERIENCE_BOTTLE',
		'FEATHER',
		'FERMENTED_SPIDER_EYE',
		'FERN',
		'FIELD_MASONED_BANNER_PATTERN',
		'FIREWORK_ROCKET',
		'FIREWORK_STAR',
		'FISHING_ROD',
		'FLETCHING_TABLE',
		'FLINT',
		'FLINT_AND_STEEL',
		'FLOWER_BANNER_PATTERN',
		'FLOWER_POT',
		'FURNACE',
		'FURNACE_MINECART',
		'GLASS',
		'GLASS_BOTTLE',
		'GLASS_PANE',
		'GLISTERING_MELON_SLICE',
		'GLOBE_BANNER_PATTERN',
		'GLOW_BERRIES',
		'GLOW_INK_SAC',
		'GLOW_LICHEN',
		'GOLDEN_APPLE',
		'GOLDEN_AXE',
		'GOLDEN_BOOTS',
		'GOLDEN_CARROT',
		'GOLDEN_CHESTPLATE',
		'GOLDEN_HELMET',
		'GOLDEN_HOE',
		'GOLDEN_HORSE_ARMOR',
		'GOLDEN_LEGGINGS',
		'GOLDEN_PICKAXE',
		'GOLDEN_SHOVEL',
		'GOLDEN_SWORD',
		'GOLD_BLOCK',
		'GOLD_INGOT',
		'GOLD_NUGGET',
		'SHORT_GRASS',
		'GRAVEL',
		'GRAY_BANNER',
		'GRAY_BED',
		'GRAY_BUNDLE',
		'GRAY_CARPET',
		'GRAY_CONCRETE',
		'GRAY_CONCRETE_POWDER',
		'GRAY_DYE',
		'GRAY_GLAZED_TERRACOTTA',
		'GRAY_HARNESS',
		'GRAY_STAINED_GLASS',
		'GRAY_TERRACOTTA',
		'GRAY_WOOL',
		'GREEN_BANNER',
		'GREEN_BED',
		'GREEN_BUNDLE',
		'GREEN_CARPET',
		'GREEN_CONCRETE',
		'GREEN_CONCRETE_POWDER',
		'GREEN_DYE',
		'GREEN_GLAZED_TERRACOTTA',
		'GREEN_HARNESS',
		'GREEN_STAINED_GLASS',
		'GREEN_TERRACOTTA',
		'GREEN_WOOL',
		'GRINDSTONE',
		'GUNPOWDER',
		'HAY_BLOCK',
		'HEAVY_WEIGHTED_PRESSURE_PLATE',
		'HOPPER',
		'HOPPER_MINECART',
		'INK_SAC',
		'IRON_AXE',
		'IRON_BARS',
		'IRON_BLOCK',
		'IRON_BOOTS',
		'IRON_CHAIN',
		'IRON_CHESTPLATE',
		'IRON_DOOR',
		'IRON_HELMET',
		'IRON_HOE',
		'IRON_HORSE_ARMOR',
		'IRON_INGOT',
		'IRON_LEGGINGS',
		'IRON_NUGGET',
		'IRON_PICKAXE',
		'IRON_SHOVEL',
		'IRON_SWORD',
		'IRON_TRAPDOOR',
		'ITEM_FRAME',
		'JACK_O_LANTERN',
		'JUKEBOX',
		'JUNGLE_BOAT',
		'JUNGLE_BUTTON',
		'JUNGLE_CHEST_BOAT',
		'JUNGLE_DOOR',
		'JUNGLE_FENCE',
		'JUNGLE_FENCE_GATE',
		'JUNGLE_HANGING_SIGN',
		'JUNGLE_LEAVES',
		'JUNGLE_LOG',
		'JUNGLE_PLANKS',
		'JUNGLE_PRESSURE_PLATE',
		'JUNGLE_SAPLING',
		'JUNGLE_SHELF',
		'JUNGLE_SIGN',
		'JUNGLE_SLAB',
		'JUNGLE_STAIRS',
		'JUNGLE_TRAPDOOR',
		'JUNGLE_WOOD',
		'LADDER',
		'LANTERN',
		'LAPIS_BLOCK',
		'LAPIS_LAZULI',
		'LAVA_BUCKET',
		'LEAD',
		'LEATHER',
		'LEATHER_BOOTS',
		'LEATHER_CHESTPLATE',
		'LEATHER_HELMET',
		'LEATHER_HORSE_ARMOR',
		'LEATHER_LEGGINGS',
		'LECTERN',
		'LEVER',
		'LIGHT_BLUE_BANNER',
		'LIGHT_BLUE_BED',
		'LIGHT_BLUE_BUNDLE',
		'LIGHT_BLUE_CARPET',
		'LIGHT_BLUE_CONCRETE',
		'LIGHT_BLUE_CONCRETE_POWDER',
		'LIGHT_BLUE_DYE',
		'LIGHT_BLUE_GLAZED_TERRACOTTA',
		'LIGHT_BLUE_HARNESS',
		'LIGHT_BLUE_STAINED_GLASS',
		'LIGHT_BLUE_TERRACOTTA',
		'LIGHT_BLUE_WOOL',
		'LIGHT_GRAY_BANNER',
		'LIGHT_GRAY_BED',
		'LIGHT_GRAY_BUNDLE',
		'LIGHT_GRAY_CARPET',
		'LIGHT_GRAY_CONCRETE',
		'LIGHT_GRAY_CONCRETE_POWDER',
		'LIGHT_GRAY_DYE',
		'LIGHT_GRAY_GLAZED_TERRACOTTA',
		'LIGHT_GRAY_HARNESS',
		'LIGHT_GRAY_STAINED_GLASS',
		'LIGHT_GRAY_TERRACOTTA',
		'LIGHT_GRAY_WOOL',
		'LIGHT_WEIGHTED_PRESSURE_PLATE',
		'LILAC',
		'LILY_PAD',
		'LIME_BANNER',
		'LIME_BED',
		'LIME_BUNDLE',
		'LIME_CARPET',
		'LIME_CONCRETE',
		'LIME_CONCRETE_POWDER',
		'LIME_DYE',
		'LIME_GLAZED_TERRACOTTA',
		'LIME_HARNESS',
		'LIME_STAINED_GLASS',
		'LIME_TERRACOTTA',
		'LIME_WOOL',
		'LODESTONE',
		'LODESTONE_COMPASS',
		'LOOM',
		'MAGENTA_BANNER',
		'MAGENTA_BED',
		'MAGENTA_BUNDLE',
		'MAGENTA_CARPET',
		'MAGENTA_CONCRETE',
		'MAGENTA_CONCRETE_POWDER',
		'MAGENTA_DYE',
		'MAGENTA_GLAZED_TERRACOTTA',
		'MAGENTA_HARNESS',
		'MAGENTA_STAINED_GLASS',
		'MAGENTA_TERRACOTTA',
		'MAGENTA_WOOL',
		'MAGMA_BLOCK',
		'MELON',
		'MELON_SEEDS',
		'MELON_SLICE',
		'MILK_BUCKET',
		'MINECART',
		'MOSS_BLOCK',
		'MOSS_CARPET',
		'MOSSY_COBBLESTONE',
		'MOSSY_COBBLESTONE_SLAB',
		'MOSSY_COBBLESTONE_STAIRS',
		'MOSSY_STONE_BRICK_SLAB',
		'MOSSY_STONE_BRICK_STAIRS',
		'MOSSY_STONE_BRICK_WALL',
		'MOSSY_STONE_BRICKS',
		'MUSHROOM_STEW',
		'MUTTON',
		'NOTE_BLOCK',
		'OAK_BOAT',
		'OAK_BUTTON',
		'OAK_CHEST_BOAT',
		'OAK_DOOR',
		'OAK_FENCE',
		'OAK_FENCE_GATE',
		'OAK_HANGING_SIGN',
		'OAK_LEAVES',
		'OAK_LOG',
		'OAK_PLANKS',
		'OAK_PRESSURE_PLATE',
		'OAK_SAPLING',
		'OAK_SHELF',
		'OAK_SIGN',
		'OAK_SLAB',
		'OAK_STAIRS',
		'OAK_TRAPDOOR',
		'OAK_WOOD',
		'OBSERVER',
		'OBSIDIAN',
		'ORANGE_BANNER',
		'ORANGE_BED',
		'ORANGE_BUNDLE',
		'ORANGE_CARPET',
		'ORANGE_CONCRETE',
		'ORANGE_CONCRETE_POWDER',
		'ORANGE_DYE',
		'ORANGE_GLAZED_TERRACOTTA',
		'ORANGE_HARNESS',
		'ORANGE_STAINED_GLASS',
		'ORANGE_TERRACOTTA',
		'ORANGE_TULIP',
		'ORANGE_WOOL',
		'OXEYE_DAISY',
		'PACKED_ICE',
		'PAINTING',
		'PAPER',
		'PEONY',
		'PHANTOM_MEMBRANE',
		'PINK_BANNER',
		'PINK_BED',
		'PINK_BUNDLE',
		'PINK_CARPET',
		'PINK_CONCRETE',
		'PINK_CONCRETE_POWDER',
		'PINK_DYE',
		'PINK_GLAZED_TERRACOTTA',
		'PINK_HARNESS',
		'PINK_PETALS',
		'PINK_STAINED_GLASS',
		'PINK_TERRACOTTA',
		'PINK_TULIP',
		'PINK_WOOL',
		'PISTON',
		'PLAYER_HEAD',
		'POINTED_DRIPSTONE',
		'POISONOUS_POTATO',
		'POLISHED_DEEPSLATE',
		'POLISHED_DEEPSLATE_SLAB',
		'POLISHED_DEEPSLATE_STAIRS',
		'POLISHED_DEEPSLATE_WALL',
		'POPPY',
		'PORKCHOP',
		'POTATO',
		'POTION',
		'POWDER_SNOW_BUCKET',
		'POWERED_RAIL',
		'PUFFERFISH',
		'PUFFERFISH_BUCKET',
		'PUMPKIN',
		'PUMPKIN_PIE',
		'PUMPKIN_SEEDS',
		'PURPLE_BANNER',
		'PURPLE_BED',
		'PURPLE_BUNDLE',
		'PURPLE_CARPET',
		'PURPLE_CONCRETE',
		'PURPLE_CONCRETE_POWDER',
		'PURPLE_DYE',
		'PURPLE_GLAZED_TERRACOTTA',
		'PURPLE_HARNESS',
		'PURPLE_STAINED_GLASS',
		'PURPLE_TERRACOTTA',
		'PURPLE_WOOL',
		'PURPUR_BLOCK',
		'PURPUR_PILLAR',
		'PURPUR_SLAB',
		'PURPUR_STAIRS',
		'RABBIT',
		'RABBIT_FOOT',
		'RABBIT_HIDE',
		'RABBIT_STEW',
		'RAIL',
		'RAW_COPPER',
		'RAW_COPPER_BLOCK',
		'RAW_GOLD',
		'RAW_GOLD_BLOCK',
		'RAW_IRON',
		'RAW_IRON_BLOCK',
		'REDSTONE',
		'REDSTONE_BLOCK',
		'REDSTONE_LAMP',
		'REDSTONE_TORCH',
		'RED_BANNER',
		'RED_BED',
		'RED_BUNDLE',
		'RED_CARPET',
		'RED_CONCRETE',
		'RED_CONCRETE_POWDER',
		'RED_DYE',
		'RED_GLAZED_TERRACOTTA',
		'RED_HARNESS',
		'RED_MUSHROOM',
		'RED_SAND',
		'RED_SANDSTONE',
		'RED_SANDSTONE_SLAB',
		'RED_SANDSTONE_STAIRS',
		'RED_SANDSTONE_WALL',
		'RED_STAINED_GLASS',
		'RED_TERRACOTTA',
		'RED_TULIP',
		'RED_WOOL',
		'REPEATER',
		'ROOTED_DIRT',
		'ROSE_BUSH',
		'ROTTEN_FLESH',
		'SADDLE',
		'SALMON',
		'SALMON_BUCKET',
		'SAND',
		'SANDSTONE',
		'SANDSTONE_SLAB',
		'SANDSTONE_STAIRS',
		'SANDSTONE_WALL',
		'SCAFFOLDING',
		'SHEARS',
		'SHIELD',
		'SKULL_BANNER_PATTERN',
		'SLIME_BALL',
		'SLIME_BLOCK',
		'SMITHING_TABLE',
		'SMOKER',
		'SMOOTH_RED_SANDSTONE_SLAB',
		'SMOOTH_RED_SANDSTONE_STAIRS',
		'SMOOTH_SANDSTONE_SLAB',
		'SMOOTH_SANDSTONE_STAIRS',
		'SMOOTH_STONE',
		'SMOOTH_STONE_SLAB',
		'SNOW',
		'SNOWBALL',
		'SNOW_BLOCK',
		'SOUL_SAND',
		'SPIDER_EYE',
		'SPLASH_POTION',
		'SPRUCE_BOAT',
		'SPRUCE_BUTTON',
		'SPRUCE_CHEST_BOAT',
		'SPRUCE_DOOR',
		'SPRUCE_FENCE',
		'SPRUCE_FENCE_GATE',
		'SPRUCE_HANGING_SIGN',
		'SPRUCE_LEAVES',
		'SPRUCE_LOG',
		'SPRUCE_PLANKS',
		'SPRUCE_PRESSURE_PLATE',
		'SPRUCE_SAPLING',
		'SPRUCE_SHELF',
		'SPRUCE_SIGN',
		'SPRUCE_SLAB',
		'SPRUCE_STAIRS',
		'SPRUCE_TRAPDOOR',
		'SPRUCE_WOOD',
		'STICK',
		'STICKY_PISTON',
		'STONE',
		'STONE_AXE',
		'STONE_BRICK_WALL',
		'STONE_BRICKS',
		'STONE_BRICK_SLAB',
		'STONE_BRICK_STAIRS',
		'STONE_BUTTON',
		'STONE_HOE',
		'STONE_PICKAXE',
		'STONE_PRESSURE_PLATE',
		'STONE_SHOVEL',
		'STONE_SLAB',
		'STONE_STAIRS',
		'STONE_SWORD',
		'STONECUTTER',
		'STRING',
		'STRIPPED_ACACIA_LOG',
		'STRIPPED_ACACIA_WOOD',
		'STRIPPED_BIRCH_LOG',
		'STRIPPED_BIRCH_WOOD',
		'STRIPPED_DARK_OAK_LOG',
		'STRIPPED_DARK_OAK_WOOD',
		'STRIPPED_JUNGLE_LOG',
		'STRIPPED_JUNGLE_WOOD',
		'STRIPPED_OAK_LOG',
		'STRIPPED_OAK_WOOD',
		'STRIPPED_SPRUCE_LOG',
		'STRIPPED_SPRUCE_WOOD',
		'SUGAR',
		'SUGAR_CANE',
		'SUNFLOWER',
		'SUSPICIOUS_STEW',
		'TARGET',
		'TADPOLE_BUCKET',
		'TERRACOTTA',
		'TINTED_GLASS',
		'TIPPED_ARROW',
		'TNT',
		'TNT_MINECART',
		'TORCH',
		'TRAPPED_CHEST',
		'TRIPWIRE_HOOK',
		'TROPICAL_FISH',
		'TROPICAL_FISH_BUCKET',
		'VINE',
		'WATER_BUCKET',
		'WHEAT',
		'WHEAT_SEEDS',
		'WHITE_BANNER',
		'WHITE_BED',
		'WHITE_BUNDLE',
		'WHITE_CARPET',
		'WHITE_CONCRETE',
		'WHITE_CONCRETE_POWDER',
		'WHITE_DYE',
		'WHITE_GLAZED_TERRACOTTA',
		'WHITE_HARNESS',
		'WHITE_STAINED_GLASS',
		'WHITE_TERRACOTTA',
		'WHITE_TULIP',
		'WHITE_WOOL',
		'WOLF_ARMOR',
		'WOODEN_AXE',
		'WOODEN_HOE',
		'WOODEN_PICKAXE',
		'WOODEN_SHOVEL',
		'WOODEN_SWORD',
		'WRITABLE_BOOK',
		'WRITTEN_BOOK',
		'YELLOW_BANNER',
		'YELLOW_BED',
		'YELLOW_BUNDLE',
		'YELLOW_CANDLE',
		'YELLOW_CARPET',
		'YELLOW_CONCRETE',
		'YELLOW_CONCRETE_POWDER',
		'YELLOW_DYE',
		'YELLOW_GLAZED_TERRACOTTA',
		'YELLOW_HARNESS',
		'YELLOW_STAINED_GLASS',
		'YELLOW_TERRACOTTA',
		'YELLOW_WOOL',
	);

	// Items obtained or crafted from blocks placed in omega prior to 1.16
	@uncommonItems = array(
		'AMETHYST_BLOCK',
		'AMETHYST_SHARD',
		'ANDESITE',
		'ANDESITE_SLAB',
		'ANDESITE_STAIRS',
		'ANDESITE_WALL',
		'BAMBOO',
		'BAMBOO_BOAT',
		'BAMBOO_BUTTON',
		'BAMBOO_BLOCK',
		'BAMBOO_CHEST_RAFT',
		'BAMBOO_DOOR',
		'BAMBOO_FENCE',
		'BAMBOO_FENCE_GATE',
		'BAMBOO_HANGING_SIGN',
		'BAMBOO_MOSAIC',
		'BAMBOO_MOSAIC_SLAB',
		'BAMBOO_MOSAIC_STAIRS',
		'BAMBOO_PLANKS',
		'BAMBOO_PRESSURE_PLATE',
		'BAMBOO_RAFT',
		'BAMBOO_SHELF',
		'BAMBOO_SIGN',
		'BAMBOO_SLAB',
		'BAMBOO_STAIRS',
		'BAMBOO_TRAPDOOR',
		'BEETROOT',
		'BEETROOT_SEEDS',
		'BEETROOT_SOUP',
		'BELL',
		'BIG_DRIPLEAF',
		'BLACK_SHULKER_BOX',
		'BLUE_SHULKER_BOX',
		'BROWN_SHULKER_BOX',
		'CALCITE',
		'CANDLE',
		'CHISELED_QUARTZ_BLOCK',
		'CHISELED_TUFF',
		'CHISELED_TUFF_BRICKS',
		'CHORUS_FLOWER',
		'CHORUS_FRUIT',
		'CORNFLOWER',
		'CYAN_SHULKER_BOX',
		'DARK_PRISMARINE',
		'DARK_PRISMARINE_SLAB',
		'DARK_PRISMARINE_STAIRS',
		'DEAD_BRAIN_CORAL_BLOCK',
		'DEAD_BUBBLE_CORAL_BLOCK',
		'DEAD_FIRE_CORAL_BLOCK',
		'DEAD_HORN_CORAL_BLOCK',
		'DEAD_TUBE_CORAL_BLOCK',
		'DIORITE',
		'DIORITE_SLAB',
		'DIORITE_STAIRS',
		'DIORITE_WALL',
		'DRAGON_EGG',
		'DRAGON_HEAD',
		'END_ROD',
		'END_STONE',
		'END_STONE_BRICK_SLAB',
		'END_STONE_BRICK_STAIRS',
		'END_STONE_BRICK_WALL',
		'END_STONE_BRICKS',
		'GLOWSTONE',
		'GLOWSTONE_DUST',
		'GRANITE',
		'GRANITE_SLAB',
		'GRANITE_STAIRS',
		'GRANITE_WALL',
		'GRAY_SHULKER_BOX',
		'GREEN_SHULKER_BOX',
		'KELP',
		'LIGHT_BLUE_SHULKER_BOX',
		'LIGHT_GRAY_SHULKER_BOX',
		'LIGHTNING_ROD',
		'LILY_OF_THE_VALLEY',
		'LIME_SHULKER_BOX',
		'MAGENTA_SHULKER_BOX',
		'NETHERRACK',
		'NETHER_BRICK',
		'NETHER_BRICKS',
		'NETHER_BRICK_FENCE',
		'NETHER_BRICK_SLAB',
		'NETHER_BRICK_STAIRS',
		'NETHER_BRICK_WALL',
		'NETHER_WART',
		'POLISHED_ANDESITE',
		'POLISHED_ANDESITE_SLAB',
		'POLISHED_ANDESITE_STAIRS',
		'POLISHED_DIORITE',
		'POLISHED_DIORITE_SLAB',
		'POLISHED_DIORITE_STAIRS',
		'POLISHED_GRANITE',
		'POLISHED_GRANITE_SLAB',
		'POLISHED_GRANITE_STAIRS',
		'ORANGE_SHULKER_BOX',
		'PINK_SHULKER_BOX',
		'POLISHED_TUFF',
		'POLISHED_TUFF_STAIRS',
		'POLISHED_TUFF_WALL',
		'POPPED_CHORUS_FRUIT',
		'PRISMARINE',
		'PRISMARINE_BRICKS',
		'PRISMARINE_BRICK_SLAB',
		'PRISMARINE_BRICK_STAIRS',
		'PRISMARINE_CRYSTALS',
		'PRISMARINE_SHARD',
		'PRISMARINE_SLAB',
		'PRISMARINE_STAIRS',
		'PRISMARINE_WALL',
		'PURPLE_SHULKER_BOX',
		'QUARTZ',
		'QUARTZ_BLOCK',
		'QUARTZ_BRICKS',
		'QUARTZ_PILLAR',
		'QUARTZ_SLAB',
		'QUARTZ_STAIRS',
		'RED_NETHER_BRICK_SLAB',
		'RED_NETHER_BRICK_STAIRS',
		'RED_NETHER_BRICK_WALL',
		'RED_NETHER_BRICKS',
		'RED_SHULKER_BOX',
		'SEAGRASS',
		'SEA_LANTERN',
		'SEA_PICKLE',
		'SHULKER_BOX',
		'SMALL_DRIPLEAF',
		'SMOOTH_QUARTZ_SLAB',
		'SMOOTH_QUARTZ_STAIRS',
		'SPECTRAL_ARROW',
		'SPONGE',
		'SPYGLASS',
		'TUFF',
		'TUFF_BRICK_SLAB',
		'TUFF_BRICK_STAIRS',
		'TUFF_BRICK_WALL',
		'TUFF_BRICKS',
		'TUFF_SLAB',
		'TUFF_STAIRS',
		'TUFF_WALL',
		'YELLOW_SHULKER_BOX',
		'WET_SPONGE',
		'WHITE_SHULKER_BOX',
		'WITHER_ROSE',
		'WITHER_SKELETON_SKULL',
		'ZOMBIE_HEAD',
	);

	// All other possible items
	@rareItems = array(
		'ANCIENT_DEBRIS',
		'AZALEA',
		'AZALEA_LEAVES',
		'BASALT',
		'BEEHIVE',
		'BLACK_CANDLE',
		'BLACKSTONE',
		'BLACKSTONE_SLAB',
		'BLACKSTONE_STAIRS',
		'BLUE_CANDLE',
		'BLUE_EGG',
		'BROWN_CANDLE',
		'BROWN_EGG',
		'BUSH',
		'CACTUS_FLOWER',
		'CHERRY_BOAT',
		'CHERRY_BUTTON',
		'CHERRY_CHEST_BOAT',
		'CHERRY_DOOR',
		'CHERRY_FENCE',
		'CHERRY_FENCE_GATE',
		'CHERRY_HANGING_SIGN',
		'CHERRY_LEAVES',
		'CHERRY_LOG',
		'CHERRY_PLANKS',
		'CHERRY_PRESSURE_PLATE',
		'CHERRY_SAPLING',
		'CHERRY_SHELF',
		'CHERRY_SIGN',
		'CHERRY_SLAB',
		'CHERRY_STAIRS',
		'CHERRY_TRAPDOOR',
		'CHERRY_WOOD',
		'CHISELED_RESIN_BRICKS',
		'CHISELED_POLISHED_BLACKSTONE',
		'CLOSED_EYEBLOSSOM',
		'COPPER_GOLEM_STATUE',
		'COPPER_HORSE_ARMOR',
		'CRACKED_POLISHED_BLACKSTONE_BRICKS',
		'CREAKING_HEART',
		'CREEPER_BANNER_PATTERN',
		'CRIMSON_BUTTON',
		'CRIMSON_DOOR',
		'CRIMSON_FENCE',
		'CRIMSON_FENCE_GATE',
		'CRIMSON_FUNGUS',
		'CRIMSON_HANGING_SIGN',
		'CRIMSON_HYPHAE',
		'CRIMSON_PLANKS',
		'CRIMSON_PRESSURE_PLATE',
		'CRIMSON_ROOTS',
		'CRIMSON_SHELF',
		'CRIMSON_SIGN',
		'CRIMSON_SLAB',
		'CRIMSON_STAIRS',
		'CRIMSON_STEM',
		'CRIMSON_TRAPDOOR',
		'CYAN_CANDLE',
		'EXPOSED_CHISELED_COPPER',
		'EXPOSED_COPPER',
		'EXPOSED_COPPER_BARS',
		'EXPOSED_COPPER_BULB',
		'EXPOSED_COPPER_CHAIN',
		'EXPOSED_COPPER_CHEST',
		'EXPOSED_COPPER_DOOR',
		'EXPOSED_COPPER_GOLEM_STATUE',
		'EXPOSED_COPPER_GRATE',
		'EXPOSED_COPPER_LANTERN',
		'EXPOSED_COPPER_TRAPDOOR',
		'EXPOSED_CUT_COPPER',
		'EXPOSED_CUT_COPPER_SLAB',
		'EXPOSED_CUT_COPPER_STAIRS',
		'EXPOSED_LIGHTNING_ROD',
		'FIREFLY_BUSH',
		'FLOWERING_AZALEA',
		'FLOWERING_AZALEA_LEAVES',
		'GILDED_BLACKSTONE',
		'GRAY_CANDLE',
		'GREEN_CANDLE',
		'HANGING_ROOTS',
		'HONEYCOMB',
		'HONEYCOMB_BLOCK',
		'HONEY_BLOCK',
		'HONEY_BOTTLE',
		'LEAF_LITTER',
		'LIGHT_BLUE_CANDLE',
		'LIGHT_GRAY_CANDLE',
		'LIME_CANDLE',
		'MAGENTA_CANDLE',
		'MANGROVE_BOAT',
		'MANGROVE_BUTTON',
		'MANGROVE_CHEST_BOAT',
		'MANGROVE_DOOR',
		'MANGROVE_FENCE',
		'MANGROVE_FENCE_GATE',
		'MANGROVE_HANGING_SIGN',
		'MANGROVE_LEAVES',
		'MANGROVE_LOG',
		'MANGROVE_PLANKS',
		'MANGROVE_PRESSURE_PLATE',
		'MANGROVE_PROPAGULE',
		'MANGROVE_ROOTS',
		'MANGROVE_SLAB',
		'MANGROVE_SHELF',
		'MANGROVE_SIGN',
		'MANGROVE_STAIRS',
		'MANGROVE_TRAPDOOR',
		'MANGROVE_WOOD',
		'MUDDY_MANGROVE_ROOTS',
		'MUD',
		'MUD_BRICK_SLAB',
		'MUD_BRICK_STAIRS',
		'MUD_BRICK_WALL',
		'MUD_BRICKS',
		'OCHRE_FROGLIGHT',
		'OPEN_EYEBLOSSOM',
		'ORANGE_CANDLE',
		'OXIDIZED_CHISELED_COPPER',
		'OXIDIZED_COPPER_BARS',
		'OXIDIZED_COPPER_BULB',
		'OXIDIZED_COPPER_CHAIN',
		'OXIDIZED_COPPER_CHEST',
		'OXIDIZED_COPPER_DOOR',
		'OXIDIZED_COPPER_GOLEM_STATUE',
		'OXIDIZED_COPPER_GRATE',
		'OXIDIZED_COPPER_LANTERN',
		'OXIDIZED_COPPER_TRAPDOOR',
		'OXIDIZED_CUT_COPPER',
		'OXIDIZED_CUT_COPPER_SLAB',
		'OXIDIZED_CUT_COPPER_STAIRS',
		'OXIDIZED_COPPER',
		'OXIDIZED_LANTERN',
		'PACKED_MUD',
		'PALE_HANGING_MOSS',
		'PALE_MOSS_BLOCK',
		'PALE_MOSS_CARPET',
		'PALE_OAK_BOAT',
		'PALE_OAK_BUTTON',
		'PALE_OAK_CHEST_BOAT',
		'PALE_OAK_DOOR',
		'PALE_OAK_FENCE',
		'PALE_OAK_FENCE_GATE',
		'PALE_OAK_HANGING_SIGN',
		'PALE_OAK_LEAVES',
		'PALE_OAK_LOG',
		'PALE_OAK_PLANKS',
		'PALE_OAK_PRESSURE_PLATE',
		'PALE_OAK_SAPLING',
		'PALE_OAK_SHELF',
		'PALE_OAK_SIGN',
		'PALE_OAK_SLAB',
		'PALE_OAK_STAIRS',
		'PALE_OAK_TRAPDOOR',
		'PALE_OAK_WOOD',
		'PEARLESCENT_FROGLIGHT',
		'PETRIFIED_OAK_SLAB',
		'PIGLIN_HEAD',
		'PINK_CANDLE',
		'PITCHER_PLANT',
		'PITCHER_POD',
		'POLISHED_BASALT',
		'POLISHED_BLACKSTONE',
		'POLISHED_BLACKSTONE_BRICK_SLAB',
		'POLISHED_BLACKSTONE_BRICK_STAIRS',
		'POLISHED_BLACKSTONE_BRICKS',
		'POLISHED_BLACKSTONE_SLAB',
		'POLISHED_BLACKSTONE_STAIRS',
		'PURPLE_CANDLE',
		'RED_CANDLE',
		'RESIN_BLOCK',
		'RESIN_BRICK',
		'RESIN_BRICKS',
		'RESIN_BRICK_SLAB',
		'RESIN_BRICK_STAIRS',
		'RESIN_BRICK_WALL',
		'RESIN_CLUMP',
		'RESPAWN_ANCHOR',
		'SHORT_DRY_GRASS',
		'SHROOMLIGHT',
		'SKELETON_SKULL',
		'SMOOTH_BASALT',
		'STRIPPED_BAMBOO_BLOCK',
		'STRIPPED_CHERRY_LOG',
		'STRIPPED_CHERRY_WOOD',
		'STRIPPED_CRIMSON_HYPHAE',
		'STRIPPED_CRIMSON_STEM',
		'STRIPPED_PALE_OAK_LOG',
		'STRIPPED_PALE_OAK_WOOD',
		'STRIPPED_WARPED_HYPHAE',
		'STRIPPED_WARPED_STEM',
		'STRIPPED_MANGROVE_LOG',
		'STRIPPED_MANGROVE_WOOD',
		'SOUL_CAMPFIRE',
		'SOUL_LANTERN',
		'SOUL_TORCH',
		'SWEET_BERRIES',
		'TALL_DRY_GRASS',
		'TORCHFLOWER',
		'TORCHFLOWER_SEEDS',
		'TRIDENT',
		'TURTLE_HELMET',
		'TURTLE_SCUTE',
		'TWISTING_VINES',
		'VERDANT_FROGLIGHT',
		'WARPED_BUTTON',
		'WARPED_DOOR',
		'WARPED_FENCE',
		'WARPED_FENCE_GATE',
		'WARPED_FUNGUS',
		'WARPED_FUNGUS_ON_A_STICK',
		'WARPED_HANGING_SIGN',
		'WARPED_HYPHAE',
		'WARPED_PLANKS',
		'WARPED_PRESSURE_PLATE',
		'WARPED_ROOTS',
		'WARPED_SHELF',
		'WARPED_SIGN',
		'WARPED_SLAB',
		'WARPED_STAIRS',
		'WARPED_STEM',
		'WARPED_TRAPDOOR',
		'WARPED_WART_BLOCK',
		'WAXED_CHISELED_COPPER',
		'WAXED_COPPER_BARS',
		'WAXED_COPPER_BULB',
		'WAXED_COPPER_CHAIN',
		'WAXED_COPPER_CHEST',
		'WAXED_COPPER_DOOR',
		'WAXED_COPPER_GOLEM_STATUE',
		'WAXED_COPPER_GRATE',
		'WAXED_COPPER_LANTERN',
		'WAXED_COPPER_TRAPDOOR',
		'WAXED_CUT_COPPER',
		'WAXED_CUT_COPPER_SLAB',
		'WAXED_CUT_COPPER_STAIRS',
		'WAXED_COPPER_BLOCK',
		'WAXED_EXPOSED_CHISELED_COPPER',
		'WAXED_EXPOSED_COPPER_BARS',
		'WAXED_EXPOSED_COPPER_BULB',
		'WAXED_EXPOSED_COPPER_CHAIN',
		'WAXED_EXPOSED_COPPER_CHEST',
		'WAXED_EXPOSED_COPPER_DOOR',
		'WAXED_EXPOSED_COPPER_GOLEM_STATUE',
		'WAXED_EXPOSED_COPPER_GRATE',
		'WAXED_EXPOSED_COPPER_LANTERN',
		'WAXED_EXPOSED_COPPER_TRAPDOOR',
		'WAXED_EXPOSED_CUT_COPPER',
		'WAXED_EXPOSED_CUT_COPPER_SLAB',
		'WAXED_EXPOSED_CUT_COPPER_STAIRS',
		'WAXED_EXPOSED_COPPER',
		'WAXED_EXPOSED_LIGHTNING_ROD',
		'WAXED_LIGHTNING_ROD',
		'WAXED_OXIDIZED_CHISELED_COPPER',
		'WAXED_OXIDIZED_COPPER_BARS',
		'WAXED_OXIDIZED_COPPER_BULB',
		'WAXED_OXIDIZED_COPPER_CHAIN',
		'WAXED_OXIDIZED_COPPER_CHEST',
		'WAXED_OXIDIZED_COPPER_DOOR',
		'WAXED_OXIDIZED_COPPER_GOLEM_STATUE',
		'WAXED_OXIDIZED_COPPER_GRATE',
		'WAXED_OXIDIZED_COPPER_LANTERN',
		'WAXED_OXIDIZED_COPPER_TRAPDOOR',
		'WAXED_OXIDIZED_CUT_COPPER',
		'WAXED_OXIDIZED_CUT_COPPER_SLAB',
		'WAXED_OXIDIZED_CUT_COPPER_STAIRS',
		'WAXED_OXIDIZED_COPPER',
		'WAXED_OXIDIZED_LIGHTNING_ROD',
		'WAXED_WEATHERED_CHISELED_COPPER',
		'WAXED_WEATHERED_COPPER',
		'WAXED_WEATHERED_COPPER_BARS',
		'WAXED_WEATHERED_COPPER_BULB',
		'WAXED_WEATHERED_COPPER_CHAIN',
		'WAXED_WEATHERED_COPPER_CHEST',
		'WAXED_WEATHERED_COPPER_DOOR',
		'WAXED_WEATHERED_COPPER_GOLEM_STATUE',
		'WAXED_WEATHERED_COPPER_GRATE',
		'WAXED_WEATHERED_COPPER_LANTERN',
		'WAXED_WEATHERED_COPPER_TRAPDOOR',
		'WAXED_WEATHERED_CUT_COPPER',
		'WAXED_WEATHERED_CUT_COPPER_SLAB',
		'WAXED_WEATHERED_CUT_COPPER_STAIRS',
		'WAXED_WEATHERED_LIGHTNING_ROD',
		'WEATHERED_CHISELED_COPPER',
		'WEATHERED_COPPER_BULB',
		'WEATHERED_COPPER_DOOR',
		'WEATHERED_COPPER_GRATE',
		'WEATHERED_COPPER_TRAPDOOR',
		'WEATHERED_CUT_COPPER',
		'WEATHERED_CUT_COPPER_SLAB',
		'WEATHERED_CUT_COPPER_STAIRS',
		'WEATHERED_COPPER',
		'WEEPING_VINES',
		'WHITE_CANDLE',
		'WILDFLOWERS',
	);

	@letters = array(
		A: array(meta: array(patterns: array(array(color: 'WHITE', shape: 'STRIPE_RIGHT'), array(color: 'WHITE', shape: 'STRIPE_LEFT'), array(color: 'WHITE', shape: 'STRIPE_MIDDLE'), array(color: 'WHITE', shape: 'STRIPE_TOP'), array(color: 'BLACK', shape: 'BORDER'))), name: 'BLACK_BANNER'),
		B: array(meta: array(patterns: array(array(color: 'WHITE', shape: 'STRIPE_RIGHT'), array(color: 'WHITE', shape: 'STRIPE_BOTTOM'), array(color: 'WHITE', shape: 'STRIPE_TOP'), array(color: 'BLACK', shape: 'CURLY_BORDER'), array(color: 'WHITE', shape: 'STRIPE_LEFT'), array(color: 'WHITE', shape: 'STRIPE_MIDDLE'), array(color: 'BLACK', shape: 'BORDER'))), name: 'BLACK_BANNER'),
		C: array(meta: array(patterns: array(array(color: 'WHITE', shape: 'STRIPE_TOP'), array(color: 'WHITE', shape: 'STRIPE_BOTTOM'), array(color: 'WHITE', shape: 'STRIPE_RIGHT'), array(color: 'BLACK', shape: 'STRIPE_MIDDLE'), array(color: 'WHITE', shape: 'STRIPE_LEFT'), array(color: 'BLACK', shape: 'BORDER'))), name: 'BLACK_BANNER'),
		D: array(meta: array(patterns: array(array(color: 'WHITE', shape: 'STRIPE_RIGHT'), array(color: 'WHITE', shape: 'STRIPE_BOTTOM'), array(color: 'WHITE', shape: 'STRIPE_TOP'), array(color: 'BLACK', shape: 'CURLY_BORDER'), array(color: 'WHITE', shape: 'STRIPE_LEFT'), array(color: 'BLACK', shape: 'BORDER'))), name: 'BLACK_BANNER'),
		E: array(meta: array(patterns: array(array(color: 'WHITE', shape: 'STRIPE_LEFT'), array(color: 'WHITE', shape: 'STRIPE_TOP'), array(color: 'WHITE', shape: 'STRIPE_MIDDLE'), array(color: 'WHITE', shape: 'STRIPE_BOTTOM'), array(color: 'BLACK', shape: 'BORDER'))), name: 'BLACK_BANNER'),
		F: array(meta: array(patterns: array(array(color: 'WHITE', shape: 'STRIPE_MIDDLE'), array(color: 'BLACK', shape: 'STRIPE_RIGHT'), array(color: 'WHITE', shape: 'STRIPE_TOP'), array(color: 'WHITE', shape: 'STRIPE_LEFT'), array(color: 'BLACK', shape: 'BORDER'))), name: 'BLACK_BANNER'),
		G: array(meta: array(patterns: array(array(color: 'WHITE', shape: 'STRIPE_RIGHT'), array(color: 'BLACK', shape: 'HALF_HORIZONTAL'), array(color: 'WHITE', shape: 'STRIPE_BOTTOM'), array(color: 'WHITE', shape: 'STRIPE_LEFT'), array(color: 'WHITE', shape: 'STRIPE_TOP'), array(color: 'BLACK', shape: 'BORDER'))), name: 'BLACK_BANNER'),
		H: array(meta: array(patterns: array(array(color: 'BLACK', shape: 'STRIPE_TOP'), array(color: 'BLACK', shape: 'STRIPE_BOTTOM'), array(color: 'WHITE', shape: 'STRIPE_LEFT'), array(color: 'WHITE', shape: 'STRIPE_RIGHT'), array(color: 'BLACK', shape: 'BORDER'))), name: 'WHITE_BANNER'),
		I: array(meta: array(patterns: array(array(color: 'WHITE', shape: 'STRIPE_CENTER'), array(color: 'WHITE', shape: 'STRIPE_TOP'), array(color: 'WHITE', shape: 'STRIPE_BOTTOM'), array(color: 'BLACK', shape: 'BORDER'))), name: 'BLACK_BANNER'),
		J: array(meta: array(patterns: array(array(color: 'WHITE', shape: 'STRIPE_LEFT'), array(color: 'BLACK', shape: 'HALF_HORIZONTAL'), array(color: 'WHITE', shape: 'STRIPE_BOTTOM'), array(color: 'WHITE', shape: 'STRIPE_RIGHT'), array(color: 'BLACK', shape: 'BORDER'))), name: 'BLACK_BANNER'),
		K: array(meta: array(patterns: array(array(color: 'WHITE', shape: 'STRIPE_DOWNRIGHT'), array(color: 'BLACK', shape: 'HALF_HORIZONTAL'), array(color: 'WHITE', shape: 'STRIPE_DOWNLEFT'), array(color: 'WHITE', shape: 'STRIPE_LEFT'), array(color: 'BLACK', shape: 'BORDER'))), name: 'BLACK_BANNER'),
		L: array(meta: array(patterns: array(array(color: 'WHITE', shape: 'STRIPE_BOTTOM'), array(color: 'WHITE', shape: 'STRIPE_LEFT'), array(color: 'BLACK', shape: 'BORDER'))), name: 'BLACK_BANNER'),
		M: array(meta: array(patterns: array(array(color: 'WHITE', shape: 'TRIANGLE_TOP'), array(color: 'BLACK', shape: 'TRIANGLES_TOP'), array(color: 'WHITE', shape: 'STRIPE_LEFT'), array(color: 'WHITE', shape: 'STRIPE_RIGHT'), array(color: 'BLACK', shape: 'BORDER'))), name: 'BLACK_BANNER'),
		N: array(meta: array(patterns: array(array(color: 'WHITE', shape: 'STRIPE_LEFT'), array(color: 'BLACK', shape: 'TRIANGLE_TOP'), array(color: 'WHITE', shape: 'STRIPE_DOWNRIGHT'), array(color: 'WHITE', shape: 'STRIPE_RIGHT'), array(color: 'BLACK', shape: 'BORDER'))), name: 'BLACK_BANNER'),
		O: array(meta: array(patterns: array(array(color: 'WHITE', shape: 'STRIPE_LEFT'), array(color: 'WHITE', shape: 'STRIPE_RIGHT'), array(color: 'WHITE', shape: 'STRIPE_BOTTOM'), array(color: 'WHITE', shape: 'STRIPE_TOP'), array(color: 'BLACK', shape: 'BORDER'))), name: 'BLACK_BANNER'),
		P: array(meta: array(patterns: array(array(color: 'WHITE', shape: 'STRIPE_RIGHT'), array(color: 'BLACK', shape: 'HALF_HORIZONTAL_MIRROR'), array(color: 'WHITE', shape: 'STRIPE_MIDDLE'), array(color: 'WHITE', shape: 'STRIPE_TOP'), array(color: 'WHITE', shape: 'STRIPE_LEFT'), array(color: 'BLACK', shape: 'BORDER'))), name: 'BLACK_BANNER'),
		Q: array(meta: array(patterns: array(array(color: 'BLACK', shape: 'RHOMBUS_MIDDLE'), array(color: 'WHITE', shape: 'STRIPE_RIGHT'), array(color: 'WHITE', shape: 'STRIPE_LEFT'), array(color: 'WHITE', shape: 'SQUARE_BOTTOM_RIGHT'), array(color: 'BLACK', shape: 'BORDER'))), name: 'WHITE_BANNER'),
		R: array(meta: array(patterns: array(array(color: 'WHITE', shape: 'HALF_HORIZONTAL'), array(color: 'BLACK', shape: 'STRIPE_CENTER'), array(color: 'WHITE', shape: 'STRIPE_TOP'), array(color: 'WHITE', shape: 'STRIPE_LEFT'), array(color: 'WHITE', shape: 'STRIPE_DOWNRIGHT'), array(color: 'BLACK', shape: 'BORDER'))), name: 'BLACK_BANNER'),
		S: array(meta: array(patterns: array(array(color: 'BLACK', shape: 'RHOMBUS_MIDDLE'), array(color: 'BLACK', shape: 'STRIPE_MIDDLE'), array(color: 'WHITE', shape: 'STRIPE_DOWNRIGHT'), array(color: 'BLACK', shape: 'BORDER'))), name: 'WHITE_BANNER'),
		T: array(meta: array(patterns: array(array(color: 'WHITE', shape: 'STRIPE_TOP'), array(color: 'WHITE', shape: 'STRIPE_CENTER'), array(color: 'BLACK', shape: 'BORDER'))), name: 'BLACK_BANNER'),
		V: array(meta: array(patterns: array(array(color: 'WHITE', shape: 'STRIPE_DOWNLEFT'), array(color: 'WHITE', shape: 'STRIPE_LEFT'), array(color: 'BLACK', shape: 'TRIANGLE_BOTTOM'), array(color: 'WHITE', shape: 'STRIPE_DOWNLEFT'), array(color: 'BLACK', shape: 'BORDER'))), name: 'BLACK_BANNER'),
		W: array(meta: array(patterns: array(array(color: 'WHITE', shape: 'TRIANGLE_BOTTOM'), array(color: 'BLACK', shape: 'TRIANGLES_BOTTOM'), array(color: 'WHITE', shape: 'STRIPE_LEFT'), array(color: 'WHITE', shape: 'STRIPE_RIGHT'), array(color: 'BLACK', shape: 'BORDER'))), name: 'BLACK_BANNER'),
		Y: array(meta: array(patterns: array(array(color: 'WHITE', shape: 'STRIPE_DOWNRIGHT'), array(color: 'BLACK', shape: 'HALF_HORIZONTAL_MIRROR'), array(color: 'WHITE', shape: 'STRIPE_DOWNLEFT'), array(color: 'BLACK', shape: 'BORDER'))), name: 'BLACK_BANNER'),
		Z: array(meta: array(patterns: array(array(color: 'WHITE', shape: 'STRIPE_TOP'), array(color: 'WHITE', shape: 'STRIPE_DOWNLEFT'), array(color: 'WHITE', shape: 'STRIPE_BOTTOM'), array(color: 'BLACK', shape: 'BORDER'))), name: 'BLACK_BANNER'),
	);

	// grid of random items
	@card = array();
	@size = @rules['cardsize'];
	@width = if(@size, @size, 9);
	@height = if(@size, @size, 6);
	@selectedItems = array_rand(@commonItems, @width * @height - 3, false);
	@multiple = array_get_rand(@selectedItems);

	// less common items
	array_insert(@selectedItems, array_get_rand(@uncommonItems), rand(@width * @height - 2));
	array_insert(@selectedItems, array_get_rand(@rareItems), rand(@width * @height - 1));

	// random character banner
	@index = array_rand(@letters, 1)[0];
	@letter = @letters[@index];
	@letter['players'] = array();
	@letter['material'] = @letter['name'];
	@letter['qty'] = 1;
	@letter['meta']['display'] = 'Starts with letter '.@index;
	array_insert(@selectedItems, @letter, rand(@width * @height));

	for(@i = 0, @i < @height, @i++) {
		@card[@i] = array();
		for(@j = 0, @j < @width, @j++) {
			@selectedItem = @selectedItems[@i * @height + @j];
			if(is_array(@selectedItem)) {
				@card[@i][@j] = @selectedItem;
			} else {
				@card[@i][@j] = array(players: array(), material: @selectedItem, qty: if(@selectedItem === @multiple, rand(1, 65), 1));
			}
		}
	}
	export('shard.card', @card);

	// Scoreboard
	create_objective('inarow', 'DUMMY', 'shard');
	create_objective('reroll', 'DUMMY', 'shard');
	create_objective('total', 'DUMMY', 'shard');
	if(@size) {
		set_objective_display('inarow', array(slot: 'SIDEBAR', displayname: 'In a Row ('.@size.')'), 'shard');
	} else {
		set_objective_display('total', array(slot: 'SIDEBAR', displayname: 'In a Row (4)'), 'shard');
	}

	// Player colors
	@colors = array(
		array('ORANGE_STAINED_GLASS_PANE', 'GOLD'),
		array('MAGENTA_STAINED_GLASS_PANE', 'LIGHT_PURPLE'),
		array('LIGHT_BLUE_STAINED_GLASS_PANE', 'BLUE'),
		array('YELLOW_STAINED_GLASS_PANE', 'YELLOW'),
		array('LIME_STAINED_GLASS_PANE', 'GREEN'),
		array('PINK_STAINED_GLASS_PANE', 'RED'),
		array('CYAN_STAINED_GLASS_PANE', 'AQUA'),
		array('BLUE_STAINED_GLASS_PANE', 'DARK_BLUE'),
		array('GREEN_STAINED_GLASS_PANE', 'DARK_GREEN'),
		array('RED_STAINED_GLASS_PANE', 'DARK_RED'),
	);
	@colorMap = associative_array();
	export('shard.colors', @colorMap);

	// Procedures
	proc _scavengerhunt_win(@player) {
		broadcast(color('green').@player.' wins!', all_players('shard'));
		launch_firework(ploc(@player), array(strength: 3, type: 'BALL_LARGE', flicker: true));
		set_timeout(20000, closure(){
			if(array_contains(get_worlds(), 'shard') && time() - get_metadata('shard', 'created', 'CommandHelper') > 20000) {
				_unload_shard();
			}
		});
	}

	if(@size) {
		proc _refresh_card(@cardSize = @size) {
			@card = import('shard.card');
			@chest = associative_array();
			@size = 54;
			@offset = 2;
			@chestWidth = 9;
			if(@cardSize == 3) {
				@size = 'DROPPER';
				@offset = 0;
				@chestWidth = 3;
			} else {
				@size = 9 * @cardSize;
			}
			// Personalize virtual chest per player
			foreach(@p in all_players('shard')) {
				for(@i = 0, @i < @cardSize, @i++) {
					for(@j = 0, @j < @cardSize, @j++) {
						@item = @card[@i][@j];
						@itemStack = null;
						if(array_contains(@item['players'], @p)) {
							@itemStack = array(name: 'RED_STAINED_GLASS_PANE');
						} else if(array_size(@item['players'])) {
							@itemStack = array(name: @item['material'], qty: @item['qty'], meta: array(enchants:
									array(sharpness: 1), flags: array('HIDE_ENCHANTS', 'HIDE_POTION_EFFECTS')));
							if(array_index_exists(@item, 'meta')) {
								@itemStack['meta'] = array_merge(@itemStack['meta'], @item['meta']);
							}
						} else {
							@itemStack = array(name: @item['material'], qty: @item['qty'], meta: array(lore:
									array('Click to re-roll this item.'), flags: array('HIDE_ENCHANTS', 'HIDE_POTION_EFFECTS')));
							if(array_index_exists(@item, 'meta')) {
								@itemStack['meta'] = array_merge(@itemStack['meta'], @item['meta']);
							}
						}
						@chest[@offset + @j + @i * @chestWidth] = @itemStack;
					}
				}
				if(has_inventory(@p.'card')) {
					set_inventory(@p.'card', @chest);
				} else {
					create_virtual_inventory(@p.'card', @size, @p.'\'s Card', @chest);
				}
			}
		}

		proc _check_card(@player, @row, @column, @cardSize = @size) {
			@card = import('shard.card');
			@range = range(@cardSize);
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
				if(array_contains(@card[@i][@cardSize - 1 - @i]['players'], @player)) {
					@foundDiagUp++;
				}
			}
			@score = max(@foundRow, @foundColumn, @foundDiagDown, @foundDiagUp);
			set_pscore('inarow', @player, @score, 'shard');
			if(@score == @cardSize) {
				_scavengerhunt_win(@player);
			}
		}

	} else {
		proc _refresh_card() {
			@card = import('shard.card');
			@colorMap = import('shard.colors');
			@chest = associative_array();
			@offset = 2;
			@chestWidth = 9;
			for(@i = 0, @i < 6, @i++) {
				for(@j = 0, @j < 9, @j++) {
					@item = @card[@i][@j];
					if(string_ends_with(@item['material'], '_STAINED_GLASS_PANE')) {
						continue();
					}
					@itemStack = null;
					if(@item['players']) {
						@firstPlayer = @item['players'][0];
						@itemStack = array(name: @colorMap[@firstPlayer][0],
								meta: array(display: @firstPlayer), flags: array('HIDE_ENCHANTS', 'HIDE_POTION_EFFECTS'));
						@item['material'] = 'WHITE_STAINED_GLASS_PANE';
					} else {
						@itemStack = array(name: @item['material'], qty: @item['qty'], meta: array(lore:
								array('Click to re-roll this item.'), flags: array('HIDE_ENCHANTS', 'HIDE_POTION_EFFECTS')));
						if(array_index_exists(@item, 'meta')) {
							@itemStack['meta'] = array_merge(@itemStack['meta'], @item['meta']);
						}
					}
					@chest[@j + @i * @chestWidth] = @itemStack;
				}
			}
			if(has_inventory('shardcard')) {
				set_inventory('shardcard', @chest);
			} else {
				create_virtual_inventory('shardcard', 54, 'Get 4 In A Row', @chest);
			}
		}
		_refresh_card();

		proc _check_card(@player, @row, @column) {
			@card = import('shard.card');
			@range = range(4);
			// Check horizontal/vertical
			@maxRow = min(6, @row + 4) - 3;
			@contiguous = 0;
			for(@i = max(0, @row - 3), @i < @maxRow + @contiguous, @i++) {
				if(array_contains(@card[@i][@column]['players'], @player)) {
					@contiguous++;
					if(@contiguous == 4) {
						_scavengerhunt_win(@player);
						return();
					}
				} else {
					@contiguous = 0;
				}
			}
			@maxColumn = min(9, @column + 4) - 3;
			@contiguous = 0;
			for(@i = max(0, @column - 3), @i < @maxColumn + @contiguous, @i++) {
				if(array_contains(@card[@row][@i]['players'], @player)) {
					@contiguous++;
					if(@contiguous == 4) {
						_scavengerhunt_win(@player);
						return();
					}
				} else {
					@contiguous = 0;
				}
			}
			// Check diagonal
			if(@column - @row < 6 && @row - @column < 4) {
				@offset = @column - @row;
				@contiguous = 0;
				for(@i = @row - 3, @i < @row + 1 + @contiguous, @i++) {
					@j = @i + @offset;
					if(@i > -1 && @j > -1
					&& @i < 6 && @j < 9
					&& array_contains(@card[@i][@j]['players'], @player)) {
						@contiguous++;
						if(@contiguous == 4) {
							_scavengerhunt_win(@player);
							return();
						}
					} else {
						@contiguous = 0;
					}
				}
			}
			@total = @column + @row;
			if(@total > 2 && @total < 11) {
				@offset = 8 - @column - @row;
				@contiguous = 0;
				for(@i = @row - 3, @i < @row + 1 + @contiguous, @i++) {
					@j = 8 - @i - @offset;
					if(@i > -1 && @j > -1
					&& @i < 6 && @j < 9
					&& array_contains(@card[@i][8 - @i - @offset]['players'], @player)) {
						@contiguous++;
						if(@contiguous == 4) {
							_scavengerhunt_win(@player);
							return();
						}
					} else {
						@contiguous = 0;
					}
				}
			}
		}
	}

	// Timer task
	if(@rules['timelimit']) {
		export('shard.countdown', @rules['timelimit'] * 60);
		set_interval(1000, closure(){
			try {
				@secondsLeft = import('shard.countdown')--;
				@minutes = integer(abs(@secondsLeft) / 60);
				@seconds = abs(@secondsLeft) - @minutes * 60;
				@displayTime = 'Time Left: '.if(@secondsLeft < 0, '-').@minutes.':'.if(@seconds < 10, '0').@seconds;
				if(@size) {
					set_objective_display('inarow', array(displayname: @displayTime), 'shard');
				} else {
					set_objective_display('total', array(displayname: @displayTime), 'shard');
				}
				if(@secondsLeft <= 0) {
					@bestScore = 0;
					@winner = '';
					foreach(@p in all_players()) {
						if(pworld(@p) == 'shard') {
							@score = get_pscore('total', @p, 'shard');
							if(@score > @bestScore) {
								@bestScore = @score;
								@winner = @p;
							}
						}
					}
					if(@winner) {
						clear_task();
						_scavengerhunt_win(@winner);
					}
				}
				export('shard.countdown', @secondsLeft);
			} catch(Exception @gameEnded) {
				clear_task();
				export('shard.countdown', null);
			}
		});
	}

	// Events
	@binds[] = 'shard-scavenger-worldchanged';
	bind('world_changed', array(id: 'shard-scavenger-worldchanged', priority: 'LOW'), array(to: 'shard'), @event, @size, @colors, @colorMap) {
		queue_push(closure(){
			try {
				@index = array_rand(@colors, 1)[0];
				@colorMap[player()] = @colors[@index];
				array_remove(@colors, @index);
				create_team(player(), 'shard');
				team_add_player(player(), player(), 'shard');
				set_team_display(player(), array(color: @colorMap[player()][1]), 'shard');
				pgive_item(player(), array(name: 'MAP', meta: array(display: 'Scavenger Hunt Card')));
				if(@size) {
					_refresh_card();
				}
			} catch(IndexOverflowException @ex) {
				set_pmode('SPECTATOR');
			}
		}, 'shard');
	}

	@binds[] = 'shard-scavenger-playerinteract';
	bind('player_interact', array(id: 'shard-scavenger-playerinteract'), array(itemname: 'MAP', button: 'right'), @event, @size) {
		if(pworld() == 'shard') {
			cancel();
			if(@size) {
				popen_inventory(player().'card');
			} else {
				popen_inventory('shardcard');
			}
		}
	}

	@binds[] = 'shard-scavenger-inventoryclick';
	bind('inventory_click', array(id: 'shard-scavenger-inventoryclick'), array(clicktype: 'LEFT', virtual: true), @event,
		@card, @commonItems, @width, @height) {

		if(@event['slotitem'] && @event['rawslot'] < @event['inventorysize']) {
			@menu = pinventory_holder();
			if(@menu == 'shardcard' || @menu == player().'card') {
				if(get_pscore('reroll', player(), 'shard')) {
					die('You\'ve re-rolled an item already.');
				}
				@material = @event['slotitem']['name'];
				if(string_ends_with(@material, '_STAINED_GLASS_PANE')) {
					die();
				}
				for(@i = 0, @i < @height, @i++) {
					for(@j = 0, @j < @width, @j++) {
						@item = @card[@i][@j];
						if(@item['material'] == @material && !@item['players']) {
							@newmaterial = array_get_rand(@commonItems);
							@card[@i][@j] = array(players: array(), material: @newmaterial, qty: @item['qty']);
							set_pscore('reroll', player(), 1, 'shard');
							_refresh_card();
							broadcast(player().' re-rolled '.@material.' and got '.@newmaterial.'.', all_players('shard'));
							die();
						}
					}
				}
				msg('Someone already got that item!');
			}
		}
	}

	@binds[] = 'shard-scavenger-crafting';
	bind('inventory_click', array(id: 'shard-scavenger-crafting'), array(slottype: 'RESULT'), @event, @card, @width, @height) {
		if(pworld() == 'shard' && @event['slotitem']) {
			@thisMaterial = @event['slotitem']['name'];
			@bannerSlot = null;
			for(@i = 0, @i < @height, @i++) {
				for(@j = 0, @j < @width, @j++) {
					@item = @card[@i][@j];
					if(array_contains(@item['players'], player())) {
						continue();
					}
					if(@item['material'] == @thisMaterial) {
						@resultQty = @event['slotitem']['qty'];
						if(@event['shiftclick']) {
							@minIngredientQty = 64;
							for(@slot = 1, @slot < array_size(@event['inventory']), @slot++) {
								@ingredientItem = @event['inventory'][@slot];
								if(@ingredientItem) {
									if(@ingredientItem['qty'] < @minIngredientQty) {
										@minIngredientQty = @ingredientItem['qty'];
									}
								}
							}
							@resultQty *= @minIngredientQty;
						}
						if(@item['qty'] < 2 || phas_item(array(name: @item['material'])) + @resultQty >= @item['qty']) {
							@item['players'][] = player();
							set_pscore('total', player(), get_pscore('total', player(), 'shard') + 1, 'shard');
							launch_firework(ploc());
							broadcast(player().' found '.color('green').'['.@thisMaterial.']', all_players('shard'));
							_refresh_card();
							_check_card(player(), @i, @j);
							break(2);
						}
					} else if(string_ends_with(@item['material'], '_BANNER')
					&& array_index_exists(@item, 'meta')
					&& @item['meta']['patterns']) {
						@bannerSlot = array(@i, @j);
					}
				}
			}
			if(@bannerSlot) {
				@item = @card[@bannerSlot[0]][@bannerSlot[1]];
				if(@thisMaterial[0] == @item['meta']['display'][length(@item['meta']['display']) - 1]) {
					@item['players'][] = player();
					set_pscore('total', player(), get_pscore('total', player(), 'shard') + 1, 'shard');
					launch_firework(ploc());
					broadcast(player().' found '.color('green').'['.@thisMaterial.']'
							.color('white').' for '.@item['meta']['display'], all_players('shard'));
					_refresh_card();
					_check_card(player(), @bannerSlot[0], @bannerSlot[1]);
				}
			}
		}
	}

	@binds[] = 'shard-scavenger-itempickup';
	bind('item_pickup', array(id: 'shard-scavenger-itempickup'), null, @event, @card, @width, @height) {
		if(pworld() == 'shard') {
			@thisMaterial = @event['item']['name'];
			if(string_ends_with(@thisMaterial, '_STAINED_GLASS_PANE')) {
				die();
			} else if(@thisMaterial == 'MAP') {
				modify_event('item', array(name: 'MAP', meta: array(display: 'Scavenger Hunt Card')));
				die();
			}
			@thisQty = @event['item']['qty'];
			@bannerSlot = null;
			for(@i = 0, @i < @height, @i++) {
				for(@j = 0, @j < @width, @j++) {
					@item = @card[@i][@j];
					if(array_contains(@item['players'], player())) {
						continue();
					}
					if(@item['material'] == @thisMaterial 
					&& (@item['qty'] < 2 || phas_item(array(name: @item['material'])) + @thisQty >= @item['qty'])) {
						@item['players'][] = player();
						set_pscore('total', player(), get_pscore('total', player(), 'shard') + 1, 'shard');
						launch_firework(ploc());
						broadcast(player().' found '.color('green').'['.@thisMaterial.']', all_players('shard'));
						_refresh_card();
						_check_card(player(), @i, @j);
						break(2);
					} else if(string_ends_with(@item['material'], '_BANNER')
					&& array_index_exists(@item, 'meta')
					&& @item['meta']['patterns']) {
						@bannerSlot = array(@i, @j);
					}
				}
			}
			if(@bannerSlot) {
				@item = @card[@bannerSlot[0]][@bannerSlot[1]];
				if(@thisMaterial[0] == @item['meta']['display'][length(@item['meta']['display']) - 1]) {
					@item['players'][] = player();
					set_pscore('total', player(), get_pscore('total', player(), 'shard') + 1, 'shard');
					launch_firework(ploc());
					broadcast(player().' found '.color('green').'['.@thisMaterial.']'
							.color('white').' for '.@item['meta']['display'], all_players('shard'));
					_refresh_card();
					_check_card(player(), @bannerSlot[0], @bannerSlot[1]);
				}
			}
		}
	}
}
