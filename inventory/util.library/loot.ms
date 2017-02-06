proc _set_random_contents(@loc, @count) {
	try {
		@marker = get_inventory(@loc, 0);
		if(@marker && @marker['name'] == 'CHEST'
		&& @marker['meta'] && @marker['meta']['display'] == 'LOOT CHEST') {
			return();
		}
	} catch(Exception @ex) {
		return();
	}
	
	@limits = array(
		7: 1, // BED_ROCK
		46: 16, // TNT
        52: 0, // MOB_SPAWNER (meta)
		54: 0, // CHEST
		137: 0, // COMMAND
		138: 1, // BEACON
		166: 0, // BARRIER
		210: 0, // COMMAND_REPEATING
		211: 0, // COMMAND_CHAIN
		217: 0, // STRUCTURE_VOID
        260: 2, // APPLE
		297: 8, // BREAD
		319: 16, // PORK
		320: 8, // GRILLED_PORK
		322: 1, // GOLDEN_APPLE
		349: 16, // FISH
		350: 8, // COOKED_FISH
		358: 0, // MAP
		363: 16, // RAW BEEF
		364: 8, // COOKED_BEEF
		365: 16, // RAW_CHICKEN
		366: 8, // COOKED_CHICKEN
		373: 1, // POTION (meta)
		383: 16, // MONSTER_EGG (meta)
		391: 16, // CARROT_ITEM
		392: 16, // POTATO_ITEM
		393: 8, // BAKED_POTATO
		395: 0, // EMPTY_MAP
		396: 8, // GOLDEN_CARROT
		400: 8, // PUMPKIN_PIE
		403: 1, // ENCHANTED_BOOK (meta)
		407: 4, // EXPLOSIVE_MINECART
		411: 16, // RABBIT
		412: 8, // COOKED_RABBIT
		422: 0, // COMMAND_MINECART
		423: 16, // MUTTON
		424: 8, // COOKED_MUTTON
		426: 8, // END_CRYSTAL
		434: 16, // BEETROOT
		438: 1, // SPLASH_POTION (meta)
		440: 16, // TIPPED_ARROW (meta)
		441: 1, // LINGERING_POTION (meta)
	);

	@size = get_inventory_size(@loc);
	@inv = array();
	array_resize(@inv, @size);
	do {
		@inv[rand(1, @size)] = _random_item(@limits);
	} while(@count-- > 0);
	@inv[0] = array('name': 'CHEST', 'meta': array('display': 'LOOT CHEST'));
	try {
		set_inventory(@loc, @inv);
	} catch(FormatException @ex) {
		// probably potion that can't exist
	}
}

proc _random_item(@limits) {
	@id = rand(1, 424); // total materials
	if(@id > 229) { // if item, adjust range to above 255
		@id += 26;
	}
	@max = max_stack_size(@id);
    @meta = null;
	if(array_index_exists(@limits, @id)) {
		@max = @limits[@id];
        // Apply meta
        switch(@id){
            case 52:
            case 383:
                @meta = array('spawntype': array_rand(array(
                    'BAT', 'BLAZE', 'CAVE_SPIDER', 'CHICKEN', 'COW', 'CREEPER', 'ELDER_GUARDIAN', 'ENDERMAN', 'ENDERMITE',
                    'EVOKER', 'GHAST', 'GUARDIAN', 'HORSE', 'IRON_GOLEM', 'LLAMA', 'MAGMA_CUBE', 'MUSHROOM_COW', 'OCELOT',
                    'PIG', 'PIG_ZOMBIE', 'POLAR_BEAR', 'RABBIT', 'SHEEP', 'SHULKER', 'SILVERFISH', 'SKELETON', 'SLIME',
                    'SNOWMAN', 'SPIDER', 'SQUID', 'VEX', 'VILLAGER', 'VINDICATOR', 'WITCH', 'WOLF', 'ZOMBIE'
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
                @meta = array('base': array('extended': boolean(rand(2)), 'upgraded': boolean(rand(2)), 'type': array_rand(array(
                    'SPEED', 'SLOWNESS', 'STRENGTH', 'INSTANT_HEAL', 'INSTANT_DAMAGE', 'JUMP', 'REGEN', 'FIRE_RESISTANCE',
                    'WATER_BREATHING', 'INVISIBILITY', 'NIGHT_VISION', 'WEAKNESS', 'POISON', 'LUCK'
                ), 1, false)[0]));
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
