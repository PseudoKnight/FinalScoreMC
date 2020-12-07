@pvp['binds'][] = @id.'primedtnt';
bind('player_interact', array('id': @id.'primedtnt'), array('itemname': 'TNT', 'button': 'right'), @e, @id) {
	@pvp = import('pvp'.@id);
	if(!array_index_exists(@pvp['players'], player()) || @e['action'] !== 'right_click_block') {
		die();
	}
	cancel();
	if(@loc = location_shift(@e['location'], @e['facing'])) {
		ptake_item(array('name': 'TNT'));
		@tnt = spawn_entity('PRIMED_TNT', 1, _center(@loc))[0];
		set_entity_spec(@tnt, array('fuseticks': 80));
	}
}
