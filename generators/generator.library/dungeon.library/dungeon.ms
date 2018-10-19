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
