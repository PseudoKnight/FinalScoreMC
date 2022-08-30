proc _get_loot(@floor, @random, @bonus, @loot = array(
	array(0.25, associative_array('name': 'HEAVY_WEIGHTED_PRESSURE_PLATE', 'meta': associative_array('display': 'MINE'))),
	array(0.25, associative_array('name': 'BREAD')),
	array(0.20, associative_array('name': 'COMPASS')),
	array(0.20, associative_array('name': 'GOLDEN_APPLE')),
	array(0.08, associative_array('name': 'WOODEN_AXE')),
	array(0.04, associative_array('name': 'STONE_AXE')),
	array(0.02, associative_array('name': 'IRON_AXE')),
	array(0.01, associative_array('name': 'DIAMOND_AXE')),
	array(0.08, associative_array('name': 'WOODEN_SWORD')),
	array(0.08, associative_array('name': 'GOLDEN_SWORD')),
	array(0.04, associative_array('name': 'STONE_SWORD')),
	array(0.02, associative_array('name': 'IRON_SWORD')),
	array(0.01, associative_array('name': 'DIAMOND_SWORD')),
	array(0.16, associative_array('name': 'LEATHER_CHESTPLATE')),
	array(0.16, associative_array('name': 'LEATHER_LEGGINGS')),
	array(0.32, associative_array('name': 'LEATHER_BOOTS')),
	array(0.08, associative_array('name': 'GOLDEN_CHESTPLATE')),
	array(0.08, associative_array('name': 'GOLDEN_LEGGINGS')),
	array(0.16, associative_array('name': 'GOLDEN_BOOTS')),
	array(0.04, associative_array('name': 'CHAINMAIL_LEGGINGS')),
	array(0.02, associative_array('name': 'IRON_CHESTPLATE')),
	array(0.02, associative_array('name': 'IRON_LEGGINGS')),
	array(0.04, associative_array('name': 'IRON_BOOTS')),
	array(0.01, associative_array('name': 'DIAMOND_CHESTPLATE')),
	array(0.01, associative_array('name': 'DIAMOND_LEGGINGS')),
	array(0.02, associative_array('name': 'DIAMOND_BOOTS')),
	array(0.10, associative_array('name': 'BOW')),
	array(0.10, associative_array('name': 'SPECTRAL_ARROW', 'qty': array(1, 4))),
	array(0.04, associative_array('name': 'SNOWBALL', 'qty': 2, 'meta': associative_array('display': 'SHOTGUN'))),
	array(0.02, associative_array('name': 'GHAST_TEAR', 'qty': array(1, 7), 'meta': associative_array('display': 'PISTOL'))),
)) {
	@inv = associative_array();
	foreach(@weightedLoot in @loot){
		if(srand(@random) < @weightedLoot[0]){
			@item = @weightedLoot[1];
			if(array_index_exists(@weightedLoot[1], 'qty')
			&& is_array(@weightedLoot[1]['qty'])) {
				@item = @weightedLoot[1][];
				@item['qty'] = integer(srand(@random) * (@item['qty'][1] - @item['qty'][0]) + @item['qty'][0]);
			}
			@inv[rand(27)] = @item;
		}
	}
	return(@inv);
}
