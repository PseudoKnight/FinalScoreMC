@level = 1;
@scale = 2;

proc _set_locations(@start, @end){
	@pvp = import('pvpstatic');
	if(@pvp) {
    	@pvp['arena']['spawn'] = array(array(@end), array(@start));
	}
}

proc _loot(@level) {
	return(array(
		array(0.25, associative_array('name': 'IRON_PLATE', 'meta': associative_array('display': 'MINE'))),
		array(0.25, associative_array('name': 'BREAD')),
		array(0.20, associative_array('name': 'COMPASS')),
		array(0.20, associative_array('name': 'GOLDEN_APPLE')),
		array(0.16, associative_array('name': 'MILK_BUCKET')),
		array(0.08, associative_array('name': 'WOOD_AXE')),
		array(0.04, associative_array('name': 'STONE_AXE')),
		array(0.02, associative_array('name': 'IRON_AXE')),
		array(0.01, associative_array('name': 'DIAMOND_AXE')),
		array(0.08, associative_array('name': 'WOOD_SWORD')),
		array(0.08, associative_array('name': 'GOLD_SWORD')),
		array(0.04, associative_array('name': 'STONE_SWORD')),
		array(0.02, associative_array('name': 'IRON_SWORD')),
		array(0.01, associative_array('name': 'DIAMOND_SWORD')),
		array(0.16, associative_array('name': 'LEATHER_CHESTPLATE')),
		array(0.16, associative_array('name': 'LEATHER_LEGGINGS')),
		array(0.16, associative_array('name': 'LEATHER_BOOTS')),
		array(0.08, associative_array('name': 'GOLD_CHESTPLATE')),
		array(0.08, associative_array('name': 'GOLD_LEGGINGS')),
		array(0.08, associative_array('name': 'GOLD_BOOTS')),
		array(0.04, associative_array('name': 'CHAINMAIL_LEGGINGS')),
		array(0.02, associative_array('name': 'IRON_CHESTPLATE')),
		array(0.02, associative_array('name': 'IRON_LEGGINGS')),
		array(0.02, associative_array('name': 'IRON_BOOTS')),
		array(0.01, associative_array('name': 'DIAMOND_CHESTPLATE')),
		array(0.01, associative_array('name': 'DIAMOND_LEGGINGS')),
		array(0.01, associative_array('name': 'DIAMOND_BOOTS')),
		array(0.10, associative_array('name': 'BOW')),
		array(0.10, associative_array('name': 'SPECTRAL_ARROW', 'qty': array(1, 4))),
		array(0.04, associative_array('name': 'SNOW_BALL', 'qty': 2, 'meta': associative_array('display': 'SHOTGUN'))),
		array(0.02, associative_array('name': 'GHAST_TEAR', 'qty': array(1, 7), 'meta': associative_array('display': 'PISTOL')));
	));
}

proc _materials(@level) {
	return(associative_array(
		'empty': '8:0',
		'wall': array('7:0'),
		'room': '0:0',
		'door': '0:0',
		'column': '7:0',
		'ladder': '65:3',
		'ceiling': '7:0',
		'floor': array('73:0', '110:0'),
		'utility': array('7:0'),
		'decor': array('7:0'),
		'edge': array('0', '0', '0', '0'),
	));
}

proc _spawner_mobs(@level) {
	return(null);
}
