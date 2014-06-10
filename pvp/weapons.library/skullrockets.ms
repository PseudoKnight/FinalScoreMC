array_push(@pvp['binds'], @id.'skullrockets')
bind('player_interact', array('id': @id.'skullrockets'), array('item': 397, 'button': 'right'), @e, assign(@id, @id)) {
	@pvp = import('pvp'.@id)
	if(!array_index_exists(@pvp['players'], player()), die())
	if(@e['item'] != '397:1', die())

	@skull = shoot_projectile(player(), 'wither_skull')
	ptake_item('397:1', 1)
	cancel()
}