proc _fw_start_task(@secs) {
	_fw_msg(array(
		'Let\'sa go!',
		'Wahooo!',
		'Break three bricks!',
	));
	foreach(@p in all_players('custom')) {
		if(_fw_player(@p)) {
			set_pexp(@p, 0);
		}
	}
	@region = sk_region_info('frogware', 'custom', 0);
	_iterate_cuboid(array(@region[0][0] - 1, @region[1][1] + 3, @region[0][2] - 1, 'custom'),
		array(@region[1][0] + 1, @region[1][1] + 3, @region[1][2] + 1, 'custom'),
		'BRICKS', 2);

	bind('player_jump', array(id: 'fwtask'), null, @event) {
		if(_fw_player(player())) {
			@start = location_shift(ploc(), 'up', 3);
			set_timeout(100, closure() {
				@end = location_shift(ploc(), 'up', 3);
				@yaw = get_yaw(@start, @end);
				@end['yaw'] = if(@yaw == NaN, 0, @yaw);
				@end['pitch'] = get_pitch(@start, @end);
				@trace = ray_trace(@end, 0.5);
				if(@trace['hitblock'] && get_block(@trace['block']) == 'BRICKS') {
					play_sound(@end, array(sound: 'ENTITY_GENERIC_EXPLODE', pitch: 2));
					set_block(@trace['block'], 'AIR');
					spawn_particle(_center(@trace['block']), array(
						particle: 'BLOCK_CRACK',
						block: 'BRICKS',
						count: 30,
						xoffset: 1.0,
						yoffset: 1.0,
						zoffset: 1.0,
					));
					@exp = pexp();
					if(@exp < 99) {
						if(@exp == 66 && _fw_change_team(player(), 'winners')) {
							play_sound(ploc(), array(sound: 'ENTITY_ZOMBIE_ATTACK_IRON_DOOR'), player());
						}
						set_pexp(@exp + 33);
					}
				}
			});
		}
	}
}

proc _fw_end_task(@secs) {}