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
		'empty': '0:0',
		'wall': array('1:6'),
		'room': '0:0',
		'door': '0:0',
		'column': '251:14',
		'ladder': '0:0',
		'ceiling': array('0:0'),
		'floor': array('159:12'),
		'utility': array('251:4', '251:5'),
		'decor': array('251:4', '251:5'),
		'edge': array('0:0', '0:0', '0:0', '0:0'),
	));
}

proc _duplicate_materials(@level) {
	return(array(
		'empty': '0:0',
		'wall': array('166'),
		'room': '0:0',
		'door': '0:0',
		'column': '0:0',
		'ladder': '0:0',
		'ceiling': array('0:0'),
		'floor': array('166'),
		'utility': array('0:0'),
		'decor': array('0:0'),
		'edge': array('0:0', '0:0', '0:0', '0:0'),
	));
}

proc _level_mobs(@level) {
	return(array());
}

proc _spawn_entity(@loc, @level) {
	noop();
}
