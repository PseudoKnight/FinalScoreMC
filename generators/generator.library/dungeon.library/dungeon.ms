proc _get_loot(@floor, @random, @loot = array(
	array('chance': 0.50, 'item': 'TORCH', 'qty': array(1, 16)),
	array('chance': 0.08, 'item': 'APPLE', 'qty': array(1, 16)),
	array('chance': 0.04, 'item': 'BREAD', 'qty': array(1, 16)),
	array('chance': 0.02, 'item': 'COOKED_MUTTON', 'qty': array(1, 16)),
	array('chance': 0.01, 'item': 'GOLDEN_CARROT', 'qty': array(1, 16)),
	array('chance': 0.30, 'item': 'GOLDEN_APPLE'),
	array('chance': 0.15, 'item': 'ARROW', 'qty': array(1, 6)),
	array('chance': 0.07, 'item': 'WOODEN_SWORD'),
	array('chance': 0.05, 'item': 'STONE_SWORD', 'damage': 132),
	array('chance': 0.03, 'item': 'GOLDEN_SWORD', 'damage': 33),
	array('chance': -0.01, 'item': 'IRON_SWORD', 'damage': 251),
	array('chance': -0.02, 'item': 'DIAMOND_SWORD', 'damage': 1562),
	array('chance': 0.07, 'item': 'WOODEN_AXE'),
	array('chance': 0.05, 'item': 'STONE_AXE', 'damage': 132),
	array('chance': -0.01, 'item': 'IRON_AXE', 'damage': 251),
	array('chance': -0.02, 'item': 'DIAMOND_AXE', 'damage': 1562),
	array('chance': -0.02, 'item': 'TRIDENT'),
	array('chance': 0.03, 'item': 'BOW', 'damage': 385),
	array('chance': 0.06, 'item': 'LEATHER_HELMET'),
	array('chance': 0.06, 'item': 'LEATHER_CHESTPLATE'),
	array('chance': 0.06, 'item': 'LEATHER_LEGGINGS'),
	array('chance': 0.06, 'item': 'LEATHER_BOOTS'),
	array('chance': 0.04, 'item': 'GOLDEN_HELMET'),
	array('chance': 0.04, 'item': 'GOLDEN_CHESTPLATE'),
	array('chance': 0.04, 'item': 'GOLDEN_LEGGINGS'),
	array('chance': 0.04, 'item': 'GOLDEN_BOOTS'),
	array('chance': 0.02, 'item': 'CHAINMAIL_HELMET', 'damage': 166),
	array('chance': 0.02, 'item': 'CHAINMAIL_CHESTPLATE', 'damage': 241),
	array('chance': 0.02, 'item': 'CHAINMAIL_LEGGINGS', 'damage': 226),
	array('chance': 0.02, 'item': 'CHAINMAIL_BOOTS', 'damage': 196),
	array('chance': -0.00, 'item': 'IRON_HELMET', 'damage': 166),
	array('chance': -0.00, 'item': 'IRON_CHESTPLATE', 'damage': 241),
	array('chance': -0.00, 'item': 'IRON_LEGGINGS', 'damage': 226),
	array('chance': -0.00, 'item': 'IRON_BOOTS', 'damage': 166),
	array('chance': -0.02, 'item': 'DIAMOND_HELMET', 'damage': 364),
	array('chance': -0.02, 'item': 'DIAMOND_CHESTPLATE', 'damage': 529),
	array('chance': -0.02, 'item': 'DIAMOND_LEGGINGS', 'damage': 496),
	array('chance': -0.02, 'item': 'DIAMOND_BOOTS', 'damage': 430),
	array('chance': -0.01, 'item': 'TURTLE_HELMET'),
	array('chance': -0.01, 'item': 'TOTEM_OF_UNDYING'),
	array('chance': 0.01, 'item': 'SHIELD', 'damage': 336),
	array('chance': 0.03, 'item': 'LAPIS_LAZULI'),
	array('chance': 0.04, 'item': 'IRON_INGOT'),
	array('chance': 0.03, 'item': 'DIAMOND'),
	array('chance': 0.04, 'item': 'POTION'),
	array('chance': 0.04, 'item': 'SPLASH_POTION'),
	array('chance': 0.04, 'item': 'MILK_BUCKET'),
)) {
	@inv = array();
	foreach(@weightedLoot in @loot){
		if(srand(@random) < @weightedLoot['chance'] + @floor * 0.01){
			@item = array('name': @weightedLoot['item']);
			if(array_index_exists(@weightedLoot, 'qty') && is_array(@weightedLoot['qty'])) {
				@item['qty'] = integer(srand(@random) * (@weightedLoot['qty'][1] - @weightedLoot['qty'][0]) + @weightedLoot['qty'][0]);
			}
			if(array_index_exists(@weightedLoot, 'damage')) {
				@item['meta'] = array('damage': integer(srand(@random) * @weightedLoot['damage']));
			} else if(string_ends_with(@item['name'], 'POTION')) {
				@meta = array('display': 'Mystery Potion', 'flags': array('HIDE_POTION_EFFECTS'));
				if(srand(@random) > 0.5) {
					@state = rand(3);
					@potionType = array_rand(array('SPEED', 'SLOWNESS', 'STRENGTH', 'INSTANT_HEAL', 'INSTANT_DAMAGE', 'JUMP',
					'REGEN', 'FIRE_RESISTANCE', 'WATER_BREATHING', 'INVISIBILITY', 'NIGHT_VISION', 'WEAKNESS',
					'POISON', 'LUCK'), 1, false)[0];
					@meta['base'] = array('extended': (@state == 1), 'upgraded': (@state == 2), 'type': @potionType);
				} else {
					@meta['potions'] = array();
					@effects = reflect_pull('enum', 'PotionEffectType');
					do {
						@effect = array_rand(@effects, 1, false)[0];
						@meta['potions'][@effect] = array('seconds': rand(1, 480), 'strength': rand(3)),
					} while(rand(2));
				}
				@item['meta'] = @meta;
			}
			@inv[] = @item;
		}
	}
	return(@inv);
}
