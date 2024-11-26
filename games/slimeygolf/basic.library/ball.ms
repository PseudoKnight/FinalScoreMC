proc _place_ball(@loc, @ball) {
	@ball['id'] = spawn_entity('ARMOR_STAND', 1, @loc, closure(@armorStand){
		set_entity_velocity(@armorStand, array(0, 0, 0));
		set_entity_spec(@armorStand, array(visible: false, small: @ball['size'] < 0.5));
		add_scoreboard_tag(@armorStand, 'remove');
	})[0];
	@loc['y'] += 0.01;
	@ball['slime'] = spawn_entity('ITEM_DISPLAY', 1, @loc, closure(@head) {
		set_display_entity(@head, array(
			interpolationduration: 0,
			teleportduration: 1,
			brightness: 15,
			glowcolor: _dye_to_rgb(@ball['dyecolor']),
			transformation: array(
				translation: array(x: 0, y: @ball['size'] * 0.95, z: 0),
				scale: array(x: @ball['size'] * 1.8, y: @ball['size'] * 1.8, z: @ball['size'] * 1.8))));
		set_entity_spec(@head, array(item: array(name: 'PLAYER_HEAD', meta: array(
			owneruuid: 'd5dcf43b-ffcf-412e-bbd1-33fabc8ad503',
			texture: 'eyJ0ZXh0dXJlcyI6eyJTS0lOIjp7InVybCI6Imh0dHA6Ly90ZXh0dXJlcy5taW5lY3JhZnQubmV0L3RleHR1cmUvNjc3NjE5ZTYwMDA1YzM4ZTRkNTA5Y2M5YTlmZTcyOTNhMzMyYzdiYzM4Yjg5MzM0MTc5MjkwMTA2YjAzMWJjMSJ9fX0='))));
	})[0];

	// face player
	@yaw = get_yaw(ploc(), @loc);
	@yaw = round(@yaw / 90) * 90;
	if(@yaw != 0) {
		// get quaternion rotation
		@y = -to_radians(@yaw) * 0.5;
		@leftRotation = array(
			w: cos(@y),
			x: 0,
			y: sin(@y),
			z: 0,
		);
		set_display_entity(@ball['slime'], array(transformation: array(leftRotation: @leftRotation)));
	}

	@ball['color'] = spawn_entity('BLOCK_DISPLAY', 1, @loc, closure(@display) {
		set_entity_spec(@display, array(blockdata: @ball['dyecolor'].'_STAINED_GLASS'));
		set_display_entity(@display, array(
			teleportduration: 1,
			brightness: 15,
			glowcolor: _dye_to_rgb(@ball['dyecolor']),
			transformation: array(
				translation: array(x: -@ball['size'] / 2, y: 0.0, z: -@ball['size'] / 2),
				scale: array(x: @ball['size'], y: @ball['size'], z: @ball['size']))));
		add_scoreboard_tag(@display, 'remove');
	})[0];
	set_entity_rider(@ball['slime'], @ball['color']);
	
	@ball['velocity'] = array(x: 0, y: 0, z: 0);

	if(function_exists('set_entity_size')) {
		set_entity_size(@ball['id'], @ball['size'], @ball['size']);
	}
	spawn_particle(@loc, array(particle: 'BLOCK_CRACK', block: @ball['dyecolor'].'_STAINED_GLASS', count: 20, xoffset: @ball['size'], zoffset: @ball['size']));
	play_sound(@loc, array(sound: 'ENTITY_SLIME_JUMP', volume: 0.5));
}

proc _ball_exists(@id) {
	return(@id && entity_exists(@id));
}

proc _remove_ball(@ball, @slime) {
	try(entity_remove(get_entity_rider(@slime)))
	try(entity_remove(@slime))
	try(entity_remove(@ball))
}

proc _dye_to_rgb(@dyeColor, @converter = array(
			WHITE: array(240, 240, 240),
			LIGHT_GRAY: array(171, 171, 171),
			GRAY: array(67, 67, 67),
			BLACK: array(30, 27, 27),
			RED: array(179, 49, 44),
			ORANGE: array(235, 136, 68),
			MAGENTA: array(195, 84, 205),
			LIGHT_BLUE: array(102, 137, 211),
			YELLOW: array(222, 207, 42),
			LIME: array(65, 205, 52),
			GREEN: array(59, 81, 26),
			CYAN: array(40, 118, 151),
			BLUE: array(37, 49, 146),
			PURPLE: array(123, 47, 190),
			PINK: array(216, 129, 152),
			BROWN: array(81, 48, 26),
		)) {
	return(@converter[@dyeColor]);
}

proc _get_block_below(@loc, @v, @size) {
	@block = get_block(@loc);
	if(@block !== 'AIR') {
		if(@block === 'BLACK_WOOL') {
			play_sound(@loc, array('sound': 'BLOCK_WOODEN_BUTTON_CLICK_ON', 'pitch': 0.5));
		}
		return(@block);
	}

	@rx = @loc['x'] - floor(@loc['x']);
	@dirx = '';
	if(@rx < @size / 2) {
		@dirx = 'west';
	} else if(@rx > 1 - @size / 2) {
		@dirx = 'east';
	}
	@blockX = if(@dirx, get_block(location_shift(@loc, @dirx)), @block);
	if(@blockX !== 'AIR') {
		// adjust ball velocity towards edge if hanging off
		if(@rx < @size / 2) {
			@v['x'] += 0.02;
		} else if(@rx > 1 - @size / 2) {
			@v['x'] -= 0.02;
		}
	}

	@rz = @loc['z'] - floor(@loc['z']);
	@dirz = '';
	if(@rz < @size / 2) {
		@dirz = 'north';
	} else if(@rz > 1 - @size / 2) {
		@dirz = 'south';
	}
	@blockZ = if(@dirz, get_block(location_shift(@loc, @dirz)), @block);
	if(@blockZ !== 'AIR') {
		if(@rz < @size / 2) {
			@v['z'] += 0.02;
		} else if(@rz > 1 - @size / 2) {
			@v['z'] -= 0.02;
		}
	}
	if(@blockX !== 'AIR') {
		return(@blockX);
	}
	if(@blockZ !== 'AIR') {
		return(@blockZ);
	}
	return(null);
}
