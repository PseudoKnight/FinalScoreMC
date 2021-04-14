proc _fw_start_task(@secs) {
	_fw_msg(array(
		'Climb.',
		'Get on up!',
		'Parkour to the top!',
		'JUMP JUMP JUMP',
	));
	if(!rand(4)) {
		_fw_randompotion(array('speed', 'jump_boost', 'blindness'));
	}
	if(!rand(4)) {
		_fw_mobs();
	}
	@region = sk_region_info('frogware', 'custom', 0);
	queue_push(closure(){
		_iterate_cuboid(array(@region[0][0], @region[1][1], @region[0][2], 'custom'),
			array(@region[1][0], @region[1][1], @region[1][2], 'custom'),
			'GOLD_BLOCK', 5);
	}, 'fw3');
	queue_delay(500, 'fw3');
	queue_push(closure(){
		_iterate_cuboid(array(@region[0][0], @region[1][1] + 1, @region[0][2], 'custom'),
			array(@region[1][0], @region[1][1] + 1, @region[1][2], 'custom'),
			'DIAMOND_BLOCK', 4);
	}, 'fw3');
	queue_delay(500, 'fw3');
	if(rand(4)) {
		queue_push(closure(){
			_iterate_cuboid(array(@region[0][0], @region[1][1] + 2, @region[0][2], 'custom'),
				array(@region[1][0], @region[1][1] + 2, @region[1][2], 'custom'),
				'EMERALD_BLOCK', 3);
		}, 'fw3');
	} else {
		queue_push(closure(){
			_iterate_cuboid(array(@region[0][0], @region[1][1] + 2, @region[0][2], 'custom'),
				array(@region[1][0], @region[1][1] + 2, @region[1][2], 'custom'),
				'DIAMOND_BLOCK', 3);
		}, 'fw3');

		queue_push(closure(){
			_iterate_cuboid(array(@region[0][0], @region[1][1] + 3, @region[0][2], 'custom'),
				array(@region[1][0], @region[1][1] + 3, @region[1][2], 'custom'),
				'EMERALD_BLOCK', 3);
		}, 'fw3');
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
}

proc _fw_end_task(@secs) {
	foreach(@p in all_players('custom')) {
		if(_fw_player(@p)) {
			clear_peffects(@p);
			if(get_block(ploc(@p)) === 'EMERALD_BLOCK'
			&& _fw_changeteam(@p, 'winners')) {
				play_sound(ploc(@p), array(sound: 'ENTITY_ZOMBIE_ATTACK_IRON_DOOR'), @p);
			}
		}
	}
	_remove_region_entities('frogware');
}