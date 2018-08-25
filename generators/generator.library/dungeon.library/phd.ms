proc _get_options() {
	return(array(
		'level': 1,
		'maxRoomHeight': 8,
	));
}

proc _set_locations(@start, @end, @spawns){
	_start_game(@start, @end, @spawns);
}

proc _get_loot(@level, @random) {
	return(array());
}

proc _materials(@level) {
	switch(@level) {
		case 0:
			return(associative_array(
				'empty': 'BEDROCK',
				'wall': array('STONE', 'STONE', 'STONE', 'STONE', 'STONE', 'STONE', 'STONE', 'STONE', 'ANDESITE', 'ANDESITE', 'ANDESITE', 'IRON_ORE'),
				'room': 'AIR',
				'door': 'AIR',
				'column': 'STONE',
				'ladder': 'LADDER',
				'ceiling': array('STONE', 'STONE', 'STONE', 'STONE', 'STONE', 'STONE', 'STONE', 'STONE', 'ANDESITE', 'ANDESITE', 'ANDESITE', 'IRON_ORE'),
				'floor': array('STONE', 'STONE', 'STONE', 'STONE', 'STONE', 'STONE', 'STONE', 'STONE', 'ANDESITE', 'ANDESITE', 'ANDESITE', 'IRON_ORE'),
				'utility': array('GOLD_ORE'),
				'decor': array('STONE'),
				'edge': array('STONE', 'STONE', 'STONE', 'STONE'),
			));
	}
}

proc _level_mobs(@level) {
	return(array());
}

proc _spawn_entity(@loc, @level) {
	noop();
}
