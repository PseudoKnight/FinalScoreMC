proc _fw_start_task(@secs) {
	_fw_msg(array(
		'Bring in the harvest!',
		'The farm life\'s for you.',
		'Bring life from the bones of the fallen!',
		'Get what? Get wheat!',
		'Plant seeds. Bonemeal them. Get wheat.',
	));
	_fw_items(array(name: 'BONE_MEAL', qty: 1), 100);
	@region = sk_region_info('frogware', 'custom', 0);
	_iterate_cuboid(array(@region[0][0], @region[1][1], @region[0][2], 'custom'),
		array(@region[1][0], @region[1][1], @region[1][2], 'custom'),
		'DIRT', 2);
	foreach(@p in all_players('custom')) {
		if(_fw_player(@p)) {
			pgive_item(@p, array(name: 'STONE_HOE', meta: array(damage: 130)));
			pgive_item(@p, array(name: 'SEEDS')); # seeds
		}
	}
	bind('item_pickup', array(id: 'fwtask'), array(itemname: 'WHEAT'), @e) {
		if(_fw_player(player())
		&& _fw_change_team(player(), 'winners')) {
			modify_event('item', null);
			play_sound(ploc(), array(sound: 'ENTITY_ZOMBIE_ATTACK_IRON_DOOR'), player());
		}
	}
}

proc _fw_end_task(@secs) {
	_remove_region_entities('frogware', array('DROPPED_ITEM'));
}