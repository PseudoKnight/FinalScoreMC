proc _fw_start_task(@secs) {
	@mob = if(!rand(4), 'BAT', 'CHICKEN');
	@gun = !rand(4);
	@count = if(@mob == 'BAT', if(@gun, 3, 1), if(@gun, 7, 3));
	_fw_msg(array(
		'Shoot '.@count.'!',
		'KILL ALL '.@mob.'S! Well, '.@count.' of them.',
	));
	foreach(@p in all_players('custom')) {
		if(_fw_player(@p)) {
			if(@gun) {
				pgive_item(@p, array(name: 'STONE_HOE', meta: array(display: 'Machine Gun')));
			} else {
				pgive_item(@p, array(name: 'BOW', meta: array(damage: 379, enchants: array(flame: 1))));
				pgive_item(@p, array(name: 'ARROW', qty: 6));
			}
			play_sound(ploc(@p), array(sound: if(@mob === 'BAT', 'ENTITY_BAT_LOOP', 'ENTITY_CHICKEN_AMBIENT')), @p);
			set_pexp(@p, 0);
		}
	}

	for(@i = 0, @i < (_fw_total_players() * (@count + 1)), @i++) {
		spawn_entity(@mob, 1, if(@mob === 'BAT', _fw_loc(8), _fw_loc(18)));
	}
	bind('entity_death', array(id: 'fwtask'), array(type: @mob), @e, @count) {
		if(!array_index_exists(@e['cause'], 'shooter')) {
			die();
		}
		@shooter = @e['cause']['shooter'];
		if(_fw_player(@shooter)) {
			modify_event('xp', 0);
			set_pexp(@shooter, min(99, round(pexp(@shooter) + 99 / @count)));
			if(pexp(@shooter) == 99 && _fw_change_team(@shooter, 'winners')) {
				play_sound(ploc(@shooter), array(sound: 'ENTITY_ZOMBIE_ATTACK_IRON_DOOR'), @shooter);
			}
		}
	}
	if(@gun) {
		bind('player_interact', array(id: 'fwgun'), array(hand: 'main_hand', button: 'right', itemname: 'STONE_HOE'), @e) {
			if(_fw_player(player())) {
				@arrow = shoot_projectile(player(), 'ARROW');
				set_entity_spec(@arrow, array(critical: true));
				set_entity_onfire(@arrow, 5);
				play_sound(ploc(), array('sound': 'ENTITY_FIREWORK_ROCKET_BLAST', 'pitch': 0.7, 'volume': 2));
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
				set_entity_velocity(@chicken, array(rand() * 2 - 1, 0, rand() * 2 - 1));
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
	unbind('fwgun');
}