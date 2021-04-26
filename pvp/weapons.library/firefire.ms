@pvp['binds'][] = bind('player_interact', null, array(itemname: 'FLINT_AND_STEEL'), @e, @pvp) {
	if(array_index_exists(@pvp['players'], player()) && array_index_exists(@e, 'location')) {
 		@loc = location_shift(@e['location'], @e['facing']);
		if(sk_region_check_flag(@loc, 'lighter')) {
			set_block(@loc, 'FIRE');
		}
	}
}
