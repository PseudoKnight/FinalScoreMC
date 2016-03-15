array_push(@pvp['binds'], @id.'skullrockets')
bind(player_interact, array('id': @id.'skullrockets'), array('item': 397, 'button': 'right'), @e, @id) {
	@pvp = import('pvp'.@id)
	if(!array_index_exists(@pvp['players'], player())) {
		die();
	}
	if(@e['item'] !== '397:1', die())

	@entity = shoot_projectile(player(), 'wither_skull');
	@dir = entity_spec(@entity)['direction'];
	set_entity_spec(@entity, array(direction: array(@dir['x'], @dir['y'], @dir['z'])));

	ptake_item('397:1', 1)
	cancel()
}
