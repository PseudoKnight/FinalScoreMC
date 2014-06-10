array_push(@pvp['binds'], @id.'firefire')
bind('player_interact', array('id': @id.'firefire'), array('item': 259), @e, assign(@id, @id)) {
	@pvp = import('pvp'.@id)
	if(!array_index_exists(@pvp['players'], player())
	|| !array_index_exists(@e, 'location'), die())
	@loc = ptarget_space()
	if(sk_region_check_flag(@loc, 'lighter')) {
		set_block_at(@loc, '51:0')
	}
}