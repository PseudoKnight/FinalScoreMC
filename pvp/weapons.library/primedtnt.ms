array_push(@pvp['binds'], @id.'primedtnt')
bind(player_interact, array('id': @id.'primedtnt'), array('item': 46, 'button': 'right'), @e, @id) {
	@pvp = import('pvp'.@id)
	if(!array_index_exists(@pvp['players'], player())
	|| @e['action'] !== 'right_click_block', die())
	cancel()
	if(@loc = _relative(@e['location'], @e['facing'])) {
		@loc = array(@loc[0] + 0.5, @loc[1] + 0.5, @loc[2] + 0.5, @loc[3])
		ptake_item(46, 1)
		@tnt = spawn_entity('PRIMED_TNT', 1, @loc)[0]
		set_entity_spec(@tnt, array('fuseticks': 80))
	}
}