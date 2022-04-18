proc _fw_start_task(@secs) {
	_fw_msg(array(
		'Make a trade.',
		'Haggle.',
		'Barter.',
	));
	_fw_mobs('villager');
	for(@i = 0, @i < 100, @i++) {
		drop_item(_fw_loc(), array(name: 'EMERALD', qty: 1));
	}
	bind('inventory_click', array(id: 'fwtask'), array(slottype: 'RESULT'), @e) {
		if(_fw_player(@e['player']) && @e['slotitem']) {
			if(_fw_change_team(player(), 'winners')) {
				play_sound(ploc(), array(sound: 'ENTITY_ZOMBIE_ATTACK_IRON_DOOR'), player());
			}
		}
	}
	if(!rand(5)) {
		set_timeout(3000, closure(){
			@velocity = array(rand(), rand(), rand());
			foreach(@p in all_players('custom')) {
				if(_fw_player(@p)) {
					@loc = ploc(@p);
					play_sound(@loc, array(sound: 'entity_witch_ambient', volume: 4, pitch: 1.2), @p);
					foreach(@e in entities_in_radius(@loc, 8, 'VILLAGER')) {
						set_mob_effect(@e, 'levitation', 1, 10);
					}
				}
			}
		});
	}
}

proc _fw_end_task(@secs) {
	_remove_region_entities('frogware');
}