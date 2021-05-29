@pvp['binds'][] = bind('player_interact',null, array(itemname: 'TNT', button: 'right'), @e, @pvp) {
	if(array_index_exists(@pvp['players'], player()) && @e['action'] == 'right_click_block') {
		cancel();
		if(@loc = location_shift(@e['location'], @e['facing'])) {
			ptake_item(array(name: 'TNT'));
			@tnt = spawn_entity('PRIMED_TNT', 1, _center(@loc))[0];
			set_entity_spec(@tnt, array(fuseticks: 80));
		}
	}
}
