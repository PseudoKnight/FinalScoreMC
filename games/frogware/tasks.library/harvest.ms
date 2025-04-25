proc _fw_start_task(@secs) {
	_fw_msg(array(
		'Bring in the harvest!',
		'The farm life\'s for you.',
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
			pgive_item(@p, array(name: 'WHEAT_SEEDS')); # seeds
		}
	}
	if(!rand(5)) {
		set_timeout(3000, closure(){
			@velocity = array(rand(), rand(), rand());
			foreach(@p in all_players('custom')) {
				if(_fw_player(@p)) {
					play_sound(ploc(@p), array(sound: 'entity_witch_ambient', volume: 4, pitch: 1.2), @p);
					set_pvelocity(@p, @velocity);
				}
			}
		});
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
	_remove_region_entities('frogware', 'custom', array('DROPPED_ITEM'));
}