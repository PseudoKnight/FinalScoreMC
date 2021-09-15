@pvp['binds'][] = bind('player_interact',null, array(itemname: 'TNT', button: 'right'), @e, @pvp) {
	if(array_index_exists(@pvp['players'], player()) && @e['action'] == 'right_click_block') {
		cancel();
		if(@loc = location_shift(@e['location'], @e['facing'])) {
			ptake_item(array(name: 'TNT'));
			spawn_entity('PRIMED_TNT', 1, _center(@loc), closure(@tnt) {
				set_entity_spec(@tnt, array(fuseticks: 80, source: puuid()));
				add_scoreboard_tag(@tnt, 'nodamage');
			});
		}
	}
}
