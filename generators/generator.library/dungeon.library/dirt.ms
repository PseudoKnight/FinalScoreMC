proc _get_options() {
	return(array(
		'level': 1,
		'maxRoomHeight': 2,
		'roof': false,
		'chestCount': -1,
		'spawnChance': 0.15,
		'extraDoors': 0.1,
		'duplicateOffset': 12,
		'duplicateDir': 'up',
	));
}

proc _set_locations(@start, @end, @spawns){
	noop();
}

proc _get_loot(@level, @random, @loot = array()) {
	return(@loot);
}

proc _materials(@level) {
	return(array(
		'empty': 'AIR',
		'wall': array('POLISHED_ANDESITE'),
		'room': 'AIR',
		'door': 'AIR',
		'column': 'YELLOW_CONCRETE',
		'ladder': 'AIR',
		'ceiling': array('AIR'),
		'floor': array('BROWN_TERRACOTTA'),
		'utility': array('YELLOW_CONCRETE', 'LIMTE_CONCRETE'),
		'decor': array('YELLOW_CONCRETE', 'LIMTE_CONCRETE'),
		'edge': array('AIR', 'AIR', 'AIR', 'AIR'),
	));
}

proc _duplicate_materials(@level) {
	return(array(
		'empty': 'AIR',
		'wall': array('BARRIER'),
		'room': 'AIR',
		'door': 'AIR',
		'column': 'AIR',
		'ladder': 'AIR',
		'ceiling': array('AIR'),
		'floor': array('BARRIER'),
		'utility': array('AIR'),
		'decor': array('AIR'),
		'edge': array('AIR', 'AIR', 'AIR', 'AIR'),
	));
}

proc _level_mobs(@level) {
	return(array());
}

proc _spawn_entity(@loc, @level) {
	noop();
}
