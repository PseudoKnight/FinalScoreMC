array_push(@pvp['binds'], @id.'firefire')
bind('player_interact', array('id': @id.'firefire'), array('item': 259), @e, @id) {
	@pvp = import('pvp'.@id)
	if(!array_index_exists(@pvp['players'], player())
	|| !array_index_exists(@e, 'location'), die())
	@loc = location_shift(@e['location'], @e['facing'])
	if(sk_region_check_flag(@loc, 'lighter')) {
		set_block(@loc, 'FIRE');
	}
}
