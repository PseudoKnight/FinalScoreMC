proc _rule_load(@binds, @value) {}

proc _set_inventory_contents(@loc, @count, @player,
@baseItems = array(
	APPLE: 2,
	ARROW: 16,
	BAKED_POTATO: 11,
	BREAD: 11,
	CAKE: 23,
	CARROT: 10,
	CHORUS_FRUIT: 53,
	COBBLESTONE: 64,
	COMPASS: 1,
	COOKED_BEEF: 5,
	COOKED_CHICKEN: 9,
	COOKED_COD: 11,
	COOKED_MUTTON: 8,
	COOKED_PORKCHOP: 5,
	COOKED_RABBIT: 11,
	COOKED_SALMON: 7,
	DIAMOND: 8,
	ELYTRA: 1,
	EMERALD: 64,
	ENCHANTED_BOOK: 1,
	END_CRYSTAL: 8,
	ENDER_PEARL: 16,
	EXPERIENCE_BOTTLE: 64,
	EXPLOSIVE_MINECART: 4,
	FIREWORK_ROCKET: 32,
	GOLD_INGOT: 32,
	GOLDEN_APPLE: 1,
	GOLDEN_CARROT: 5,
	IRON_INGOT: 24,
	LEATHER: 64,
	LINGERING_POTION: 3,
	MACE: 1,
	NETHERITE_INGOT: 1,
	NETHERITE_UPGRADE_SMITHING_TEMPLATE: 1,
	OAK_PLANKS: 64,
	POTION: 3,
	PUMPKIN_PIE: 14,
	SHIELD: 1,
	SPLASH_POTION: 3,
	TOTEM_OF_UNDYING: 1,
	TRIDENT: 1,
	TIPPED_ARROW: 32,
	TURTLE_HELMET: 1,
	WIND_CHARGE: 8,
	WITHER_SKELETON_SKULL: 8,
)) {
	if(has_metadata(@loc, 'loot')) {
		return();
	}

	if(has_metadata(@loc, 'treasure')) {
		@count *= 5;
	}

	@size = get_inventory_size(@loc);
	@inv = array();
	array_resize(@inv, @size);
	@emptySlots = range(@size);
	
	@c = min(@size, @count);
	while(@c > 0) {
		@item = _random_item(@baseItems);
		if(@item) {
			@randomSlot = array_remove(@emptySlots, rand(array_size(@emptySlots)));
			@inv[@randomSlot] = @item;
			@c--;
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
		@type = get_block(@loc);
		foreach(@dir in array('north', 'south', 'east', 'west')) {
			@checkLoc = location_shift(@loc, @dir);
			if(get_block(@checkLoc) == @type && get_inventory_size(@checkLoc) == 54) {
				_set_inventory_contents(@checkLoc, @count, @player);
			}
		}
	}
}

proc _random_item(@baseItems) {
	@id = array_rand(@baseItems, 1)[0];

	@max = @baseItems[@id];
	if(@max <= 0) {
		return(null);
	}
	
	// Special item handling (eg. meta)
	@meta = null;
	switch(@id){
		case 'ENCHANTED_BOOK':
			@enchants = array(
				'POWER', 'FLAME', 'INFINITY', 'PUNCH', 'SHARPNESS', 'BANE_OF_ARTHROPODS', 'SMITE', 'EFFICIENCY',
				'UNBREAKING', 'FIRE_ASPECT', 'KNOCKBACK', 'FORTUNE', 'LOOTING', 'RESPIRATION', 'PROTECTION',
				'BLAST_PROTECTION', 'FEATHER_FALLING', 'FIRE_PROTECTION', 'PROJECTILE_PROTECTION', 'SILK_TOUCH',
				'THORNS', 'AQUA_AFFINITY', 'DEPTH_STRIDER', 'MENDING', 'FROST_WALKER', 'SWEEPING_EDGE', 'CHANNELING',
				'IMPALING', 'RIPTIDE', 'LOYALTY', 'VANISHING_CURSE', 'BINDING_CURSE', 'SWIFT_SNEAK', 'PIERCING',
				'MULTISHOT', 'QUICK_CHARGE', 'BREACH', 'DENSITY', 'WIND_BURST'
			);
			@meta = array(stored: array());
			do {
				@enchant = array_get_rand(@enchants);
				@meta['stored'][@enchant] = array(elevel: rand(1, 3));
			} while(rand(2))
		case 'POTION':
		case 'SPLASH_POTION':
		case 'TIPPED_ARROW':
		case 'LINGERING_POTION':
			if(rand(2)) {
				@state = rand(3);
				@potionType = array_get_rand(array('INFESTED', 'SWIFTNESS', 'LONG_SWIFTNESS', 'STRONG_SWIFTNESS', 'SLOWNESS', 'LONG_SLOWNESS', 'STRONG_SLOWNESS',
				'STRENGTH', 'LONG_STRENGTH', 'STRONG_STRENGTH', 'HARMING', 'STRONG_HARMING', 'HEALING', 'STRONG_HEALING', 'LEAPING', 'LONG_LEAPING', 'STRONG_LEAPING',
				'OOZING', 'SLOW_FALLING', 'LONG_SLOW_FALLING', 'REGENERATION', 'LONG_REGENERATION', 'STRONG_REGENERATION', 'FIRE_RESISTANCE', 'LONG_FIRE_RESISTANCE',
				'WATER_BREATHING', 'LONG_WATER_BREATHING',  'INVISIBILITY', 'LONG_INVISIBILITY', 'NIGHT_VISION', 'LONG_NIGHT_VISION', 'WEAKNESS', 'LONG_WEAKNESS',
				'WEAVING', 'POISON', 'LONG_POISON', 'STRONG_POISON', 'LUCK', 'TURTLE_MASTER', 'LONG_TURTLE_MASTER', 'STRONG_TURTLE_MASTER', 'WIND_CHARGED'));
				@meta = array(potiontype: @potionType);
			} else {
				@meta = array(potions: array());
				@effects = reflect_pull('enum', 'PotionEffectType');
				do {
					@effect = array_get_rand(@effects);
					@meta['potions'][@effect] = array(seconds: rand(1, 480), strength: rand(3)),
				} while(rand(2))
			}
		case 'COMPASS':
			if(rand(2)) {
				@worldborder = get_world_border('shard');
				@width = max(16, @worldborder['width'] - 32);
				@loc = @worldborder['center'];
				@loc['x'] += rand() * @width - @width / 2;
				@loc['z'] += rand() * @width - @width / 2;
				@loc['y'] = rand(32, 62);
				set_block(@loc, 'CHEST');
				set_metadata(@loc, 'treasure', 1);
				@meta = array(display: 'Treasure Compass', target: @loc, lodestone: false);
			}
	}

	@item = array(
		name: @id,
		qty: rand(1, @max + 1),
		meta: @meta,
	);
	return(@item);
}
