proc _fw_start_task(@secs) {
	@type = array_get_rand(array('WOOL', 'CONCRETE_POWDER','CONCRETE'));
	_fw_msg(array(
		'Send it home.',
	));
	foreach(@p in all_players('custom')) {
		if(_fw_player(@p)) {
			pgive_item(@p, array(name: 'SULFUR_CUBE_BUCKET'));
			pgive_item(@p, array(name: 'NETHERITE_AXE', meta: array(enchants: array(sharpness: 1))));
		}
	}
	@dyeColors =  array('WHITE', 'ORANGE', 'MAGENTA', 'LIGHT_BLUE', 'YELLOW', 'LIME', 'PINK', 'GRAY',
			'LIGHT_GRAY', 'CYAN', 'PURPLE', 'BLUE', 'BROWN', 'GREEN', 'RED', 'BLACK');

	@loc = _fw_loc();
	_iterate_cuboid(array(@loc[0] + 2, @loc[1], @loc[2] + 2, 'custom'),
		array(@loc[0] - 2, @loc[1], @loc[2] - 2, 'custom'),
		'EMERALD_BLOCK', 100);
	if(rand(3)) {
		_iterate_cuboid(array(@loc[0] + 2, @loc[1] + 1, @loc[2] + 2, 'custom'),
			array(@loc[0] - 2, @loc[1] + 1, @loc[2] - 2, 'custom'),
			'GLASS', 100);
		_iterate_cuboid(array(@loc[0] + 1, @loc[1] + 1, @loc[2] + 1, 'custom'),
			array(@loc[0] - 1, @loc[1] + 1, @loc[2] - 1, 'custom'),
			'AIR', 100);
	}
	bind('player_interact', array(id: 'fwtask'), array(hand: 'main_hand', button: 'right', itemname: 'SULFUR_CUBE_BUCKET'),
			@event, @type, @dyeColors) {
		if(_fw_player(@event['player'])) {
			cancel();
			if(@event['block'] === 'WHITE_CONCRETE' && @event['facing'] === 'up') {
				@loc = @event['location'];
				@loc['x'] += 0.5;
				@loc['y'] += 1.0;
				@loc['z'] += 0.5;
				@cube = spawn_entity('SULFUR_CUBE', 1, @loc)[0];
				set_metadata(@cube, 'owner', player());
				set_mob_equipment(@cube, array(body: array(name: array_get_rand(@dyeColors).'_'.@type)));
				set_pinv(player(), null, null);
			}
		}
	}
}

proc _fw_end_task(@secs) {
	@region = sk_region_info('frogware', 'custom', 0);
	@x = @region[1][0] + ((@region[0][0] - @region[1][0]) / 2);
	@y = @region[1][1];
	@z = @region[1][2] + ((@region[0][2] - @region[1][2]) / 2);
	foreach(@e in entities_in_radius(array(@x, @y, @z, 'custom'), 128, 'SULFUR_CUBE')) {
		if(!has_metadata(@e, 'owner')) {
			continue();
		}
		@p = get_metadata(@e, 'owner', 'CommandHelper');
		if(!_fw_player(@p)) {
			continue();
		}
		@loc = location_shift(entity_loc(@e), 'down');
		if(get_block(@loc) === 'EMERALD_BLOCK'
		&& _fw_change_team(@p, 'winners')) {
			play_sound(ploc(@p), array(sound: 'ENTITY_ZOMBIE_ATTACK_IRON_DOOR'), @p);
		}
	}
	_remove_region_entities('frogware');
}