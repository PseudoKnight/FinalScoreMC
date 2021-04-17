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
}

proc _fw_end_task(@secs) {
	_remove_region_entities('frogware');
}