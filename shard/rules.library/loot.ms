proc _set_inventory_contents(@loc, @count) {
	if(has_metadata(@loc, 'loot')) {
		return();
	}
	
	@limits = array(
		260: 2, // APPLE
		264: 16, // DIAMOND
		295: 0, // SEEDS
		297: 8, // BREAD
		319: 16, // PORK
		320: 8, // GRILLED_PORK
		321: 0, // PAINTING
		322: 1, // GOLDEN_APPLE
		323: 0, // SIGN
		324: 0, // WOOD_DOOR
		330: 0, // IRON_DOOR
		336: 0, // CLAY_BRICK
		337: 0, // CLAY_BALL
		342: 0, // STORAGE_MINECART
		343: 0, // POWERED_MINECART
		349: 16, // FISH
		350: 8, // COOKED_FISH
		358: 0, // MAP
		359: 0, // SHEARS
		361: 0, // PUMPKIN_SEEDS
		362: 0, // MELON_SEEDS
		363: 16, // RAW BEEF
		364: 8, // COOKED_BEEF
		365: 16, // RAW_CHICKEN
		366: 8, // COOKED_CHICKEN
		373: 1, // POTION (meta)
		380: 0, // CAULDRON
		383: 16, // MONSTER_EGG (meta)
		389: 0, // ITEM_FRAME
		390: 0, // FLOWER_POT_ITEM
		391: 16, // CARROT_ITEM
		392: 16, // POTATO_ITEM
		393: 8, // BAKED_POTATO
		395: 0, // EMPTY_MAP
		396: 8, // GOLDEN_CARROT
		397: 8, // SKULL_ITEM
		400: 8, // PUMPKIN_PIE
		403: 1, // ENCHANTED_BOOK (meta)
		405: 0, // NETHER_BRICK_ITEM
		406: 0, // QUARTZ
		407: 4, // EXPLOSIVE_MINECART
		408: 0, // HOPPER_MINECART
		411: 16, // RABBIT
		412: 8, // COOKED_RABBIT
		422: 0, // COMMAND_MINECART
		423: 16, // MUTTON
		424: 8, // COOKED_MUTTON
		426: 8, // END_CRYSTAL
		427: 0, // SPRUCE_DOOR_ITEM
		428: 0, // BIRCH_DOOR_ITEM
		429: 0, // JUNGLE_DOOR_ITEM
		430: 0, // ACACIA_DOOR_ITEM
		431: 0, // DARK_OAK_DOOR_ITEM
		433: 0, // CHORUS_FRUIT_POPPED
		434: 16, // BEETROOT
		435: 0, // BEETROOT_SEEDS
		438: 1, // SPLASH_POTION (meta)
		440: 16, // TIPPED_ARROW (meta)
		441: 1, // LINGERING_POTION (meta)
	);

	@size = get_inventory_size(@loc);
	@inv = array();
	array_resize(@inv, @size);
	while(@count > 0) {
		@item = _random_item(@limits);
		if(@item) {
			@inv[rand(0, @size)] = @item;
			@count--;
		}
	}
	try {
		set_inventory(@loc, @inv);
	} catch(FormatException @ex) {
		@inv = array();
		array_resize(@inv, @size);
		set_inventory(@loc, @inv);
	}
	set_metadata(@loc, 'loot', 1);
	if(@size == 54) {
		@type = get_block_at(@loc);
		foreach(@dir in array('north', 'south', 'east', 'west')) {
			@checkLoc = _relative(@loc, @dir);
			if(get_block_at(@checkLoc) == @type) {
				set_metadata(@checkLoc, 'loot', 1);
				break();
			}
		}
	}
}

proc _random_item(@limits) {
	@id = rand(256, 450); // total materials
	@max = ceil(max_stack_size(@id) / 2);
	@meta = null;
	if(array_index_exists(@limits, @id)) {
		@max = @limits[@id];
		// Special item handling (eg. meta)
		switch(@id){
			case 397:
				@id = @id.':1'; // set to wither skull
			case 383:
				@meta = array('spawntype': array_rand(array(
					'BAT', 'BLAZE', 'CAVE_SPIDER', 'CHICKEN', 'COW', 'CREEPER', 'ELDER_GUARDIAN', 'ENDERMAN', 'ENDERMITE',
					'EVOKER', 'GHAST', 'GUARDIAN', 'HORSE', 'IRON_GOLEM', 'LLAMA', 'MAGMA_CUBE', 'MUSHROOM_COW', 'OCELOT',
					'PARROT', 'PIG', 'PIG_ZOMBIE', 'POLAR_BEAR', 'RABBIT', 'SHEEP', 'SHULKER', 'SILVERFISH', 'SKELETON',
					'SLIME', 'SNOWMAN', 'SPIDER', 'SQUID', 'VEX', 'VILLAGER', 'VINDICATOR', 'WITCH', 'WOLF', 'ZOMBIE'
				), 1, false)[0]);
			case 403:
				@meta = array('stored': array(array('elevel': 1, 'etype': array_rand(array(
					'ARROW_DAMAGE', 'ARROW_FIRE', 'ARROW_INFINITE', 'ARROW_KNOCKBACK', 'DAMAGE_ALL', 'DAMAGE_ARTHROPODS',
					'DAMAGE_UNDEAD', 'DIG_SPEED', 'DURABILITY', 'FIRE_ASPECT', 'KNOCKBACK', 'LOOT_BONUS_BLOCKS',
					'LOOT_BONUS_MOBS', 'OXYGEN', 'PROTECTION_ENVIRONMENTAL', 'PROTECTION_EXPLOSIONS', 'PROTECTION_FALL',
					'PROTECTION_FIRE', 'PROTECTION_PROJECTILE', 'SILK_TOUCH', 'THORNS', 'WATER_WORKER', 'DEPTH_STRIDER',
					'MENDING', 'FROST_WALKER', 'SWEEPING_EDGE'
				), 1, false)[0])));
			case 373:
			case 438:
			case 440:
			case 441:
				@state = rand(3);
				if(rand(2)) {
					@meta = array('base': array('extended': (@state == 1), 'upgraded': (@state == 2), 'type':
						array_rand(array('SPEED', 'SLOWNESS', 'STRENGTH', 'INSTANT_HEAL', 'INSTANT_DAMAGE', 'JUMP',
						'REGEN', 'FIRE_RESISTANCE', 'WATER_BREATHING', 'INVISIBILITY', 'NIGHT_VISION', 'WEAKNESS',
						'POISON', 'LUCK'), 1, false)[0]
					));
				} else {
					@types = array(
						array('id': 3, 'seconds': 300, 'strength': 0),
						array('id': 4, 'seconds': 180, 'strength': 0),
						array('id': 9, 'seconds': 30, 'strength': 0),
						array('id': 11, 'seconds': 180, 'strength': 0),
						array('id': 15, 'seconds': 30, 'strength': 0),
						array('id': 17, 'seconds': 60, 'strength': 0),
						array('id': 20, 'seconds': 15, 'strength': 0),
						array('id': 21, 'seconds': 300, 'strength': 0),
						array('id': 22, 'seconds': 300, 'strength': 0),
						array('id': 23, 'seconds': 60, 'strength': 0),
						array('id': 24, 'seconds': 60, 'strength': 0),
						array('id': 25, 'seconds': 15, 'strength': 0),
						array('id': 27, 'seconds': 180, 'strength': 0),
					);
					@meta = array('potions': array(array_rand(@types, 1, false)[0]));
				}
		}
	}
	if(@max <= 0) {
		return(null);
	}
	@item = array(
		'type': @id,
		'qty': rand(1, @max + 1),
		'meta': @meta,
	);
	return(@item);
}
