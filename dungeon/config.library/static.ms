@level = 1;
@scale = 2;

proc _set_locations(@start, @end){
	@pvp = import('pvpstatic');
    @pvp['arena']['spawn'] = array(array(@start), array(@end));
}

proc _materials(@level) {
	return(associative_array(
		'empty': '7:0',
		'wall': array('73:0'),
		'room': '0:0',
		'door': '0:0',
		'column': '73:0',
        'stairs': '114:2',
		'ceiling': '73:0',
		'floor': '73:0',
		'utility': array('73:0'),
		'decor': array('73:0'),
	));
}

proc _spawner_mobs(@level) {
	return(null);
}
