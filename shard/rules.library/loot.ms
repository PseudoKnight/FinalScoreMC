proc _set_inventory_contents(@loc, @count,
@baseItems = array(
	'APPLE': 2,
	'DIAMOND': 16,
	'BREAD': 8,
	'PORK': 16,
	'GRILLED_PORK': 8,
	'GOLDEN_APPLE': 1,
	'COD': 16,
	'COOKED_COD': 8,
	'BEEF': 16,
	'COOKED_BEEF': 8,
	'CHICKEN': 16,
	'COOKED_CHICKEN': 8,
	'ENDER_PEARL': 16,
	'POTION': 3,
	'CARROT': 16,
	'POTATO': 16,
	'BAKED_POTATO': 8,
	'GOLDEN_CARROT': 8,
	'WITHER_SKELETON_SKULL': 8,
	'PUMPKIN_PIE': 8,
	'ENCHANTED_BOOK': 1,
	'EXPLOSIVE_MINECART': 4,
	'RABBIT': 16,
	'COOKED_RABBIT': 8,
	'MUTTON': 16,
	'COOKED_MUTTON': 8,
	'END_CRYSTAL': 8,
	'BEETROOT': 16,
	'SPLASH_POTION': 3,
	'TIPPED_ARROW': 32,
	'LINGERING_POTION': 3,
	// TODO: more here, possibly tier upgrades or some other design change
)) {
	if(has_metadata(@loc, 'loot')) {
		return();
	}

	@size = get_inventory_size(@loc);
	@inv = array();
	array_resize(@inv, @size);
	while(@count > 0) {
		@item = _random_item(@baseItems);
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
		@type = get_block(@loc);
		foreach(@dir in array('north', 'south', 'east', 'west')) {
			@checkLoc = location_shift(@loc, @dir);
			if(get_block(@checkLoc) == @type && get_inventory_size(@checkLoc) == 54
			&& @inv == get_inventory(@checkLoc)) {
				set_metadata(@checkLoc, 'loot', 1);
				break();
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
			@meta = array('stored': array(array('elevel': 1, 'etype': array_rand(array(
				'POWER', 'FLAME', 'INFINITY', 'PUNCH', 'SHARPNESS', 'BANE_OF_ARTHROPODS',
				'SMITE', 'EFFICIENCY', 'UNBREAKING', 'FIRE_ASPECT', 'KNOCKBACK', 'FORTUNE',
				'LOOTING', 'RESPIRATION', 'PROTECTION', 'BLAST_PROTECTION', 'FEATHER_FALLING',
				'FIRE_PROTECTION', 'PROJECTILE_PROTECTION', 'SILK_TOUCH', 'THORNS', 'AQUA_AFFINITY', 'DEPTH_STRIDER',
				'MENDING', 'FROST_WALKER', 'SWEEPING_EDGE'
			), 1, false)[0])));
		case 'POTION':
		case 'SPLASH_POTION':
		case 'TIPPED_ARROW':
		case 'LINGERING_POTION':
			if(rand(2)) {
				@state = rand(3);
				@meta = array('base': array('extended': (@state == 1), 'upgraded': (@state == 2), 'type':
					array_rand(array('SPEED', 'SLOWNESS', 'STRENGTH', 'INSTANT_HEAL', 'INSTANT_DAMAGE', 'JUMP',
					'REGEN', 'FIRE_RESISTANCE', 'WATER_BREATHING', 'INVISIBILITY', 'NIGHT_VISION', 'WEAKNESS',
					'POISON', 'LUCK'), 1, false)[0]
				));
			} else {
				@meta = array('potions': array());
				do {
					@meta['potions'][] = array('id': rand(28), 'seconds': rand(1, 480), 'strength': rand(3)),
				} while(rand(2));
			}
	}
	
	@item = array(
		'name': @id,
		'qty': rand(1, @max + 1),
		'meta': @meta,
	);
	return(@item);
}
