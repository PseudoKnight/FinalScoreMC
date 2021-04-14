proc _fw_start_task(@secs) {
	_fw_msg(array(
		'Don\'t look up.',
		'When it rains, it pours.',
		'ACME delivery!',
		'It\'s a bird! It\'s a plane! No! It\'s ** SPLAT **',
	));
	if(!rand(4)) {
		_fw_randompotion(array('speed', 'blind'));
	}
	if(!rand(4)) {
		_fw_mobs();
	}
	bind('entity_damage', array(id: 'fwtask'), array(type: 'PLAYER', cause: 'FALLING_BLOCK', world: 'custom'), @e) {
		if(_fw_player(@e['player'])) {
			_fw_changeteam(@e['player'], 'losers');
			play_sound(ploc(@e['player']), array(sound: 'ENTITY_ZOMBIE_VILLAGER_CONVERTED'), @e['player']);
		}
	}
	_fw_set_winners();
	@region = sk_region_info('frogware', 'custom', 0);
	for(@i = 0, @i < @secs - 2, @i++) {
		queue_push(closure(){
			_iterate_cuboid(array(@region[0][0], @region[1][1] + 24, @region[0][2], 'custom'),
				array(@region[1][0], @region[1][1] + 24, @region[1][2], 'custom'),
				'ANVIL', 3);
			foreach(@p in all_players('custom')) {
				if(get_pscoreboard(@p) == 'fw') {
					@loc = ploc(@p);
					@loc['y'] += 25;
					set_block(@loc, 'ANVIL');
				}
			}
		}, 'fw3');
		queue_delay(1000, 'fw3');
	}
}

proc _fw_end_task(@secs) {
	_remove_region_entities('frogware');
	_fw_clear_blocks(1);
	_fw_clear_effects();
}