proc _fw_start_task(@secs) {
	@mob = if(!rand(4), 'BAT', 'CHICKEN');
	@count = if(@mob === 'BAT', '1', '3');
	_fw_msg(array(
		'Shoot '.@count.'!',
		'KILL ALL '.@mob.'S! Well, '.@count.' of them.',
	));
	foreach(@p in all_players('custom')) {
		if(_fw_player(@p)) {
			pgive_item(@p, array(name: 'BOW', meta: array(damage: 379, enchants: array(flame: 1))));
			pgive_item(@p, array(name: 'ARROW', qty: 6));
			play_sound(ploc(@p), array(sound: if(@mob === 'BAT', 'ENTITY_BAT_LOOP', 'ENTITY_CHICKEN_AMBIENT')), @p);
			set_pexp(@p, 0);
		}
	}

	for(@i = 0, @i < (_fw_totalplayers() * 4), @i++) {
		spawn_entity(@mob, 1, if(@mob === 'BAT', _fw_loc(8), _fw_loc(18)));
	}
	bind('entity_death', array(id: 'fwtask'), array(type: @mob), @e, @mob) {
		if(array_index_exists(@e['cause'], 'shooter')
		&& ponline(@e['cause']['shooter'])
		&& _fw_player(@e['cause']['shooter'])) {
			modify_event('xp', 0);
			if(@e['type'] === 'BAT') {
				set_pexp(@e['cause']['shooter'], 99);
			} else {
				set_pexp(@e['cause']['shooter'], min(99, pexp(@e['cause']['shooter']) + 33));
			}
			if(pexp(@e['cause']['shooter']) > 90
			&& _fw_changeteam(@e['cause']['shooter'], 'winners')) {
				play_sound(ploc(@e['cause']['shooter']), array(sound: 'ENTITY_ZOMBIE_ATTACK_IRON_DOOR'), @e['cause']['shooter']);
			}
		}
	}
	if(@mob == 'CHICKEN' && !rand(5)) {
		set_timeout(3000, closure(){
			@loc = _fw_loc(8);
			if(!@loc) {
				die();
			}
			foreach(@p in all_players('custom')) {
				if(_fw_player(@p)) {
					play_sound(ploc(@p), array(sound: 'entity_witch_ambient', volume: 4, pitch: 1.2), @p);
				}
			}
			@chickens = entities_in_radius(@loc, 32, 'CHICKEN');
			foreach(@chicken in @chickens) {
				set_entity_velocity(@chicken, array(rand(), rand(), rand()));
			}
		});
	}
}

proc _fw_end_task(@secs) {
	foreach(@p in all_players('custom')) {
		if(_fw_player(@p)) {
			set_pexp(@p, 0);
		}
	}
}