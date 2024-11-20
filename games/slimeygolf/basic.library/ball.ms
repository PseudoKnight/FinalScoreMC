proc _place_ball(@loc, @ball) {
	@ball['id'] = spawn_entity('ARMOR_STAND', 1, @loc, closure(@armorStand){
		set_entity_velocity(@armorStand, array(0, 0, 0));
		set_entity_spec(@armorStand, array(visible: false, small: true));
		add_scoreboard_tag(@armorStand, 'remove');
	})[0];
	@loc['y'] += 0.01;
	@ball['slime'] = spawn_entity('ITEM_DISPLAY', 1, @loc, closure(@head) {
		set_display_entity(@head, array(
			teleportduration: 1,
			transformation: array(
				translation: array(x: 0, y: 0.455, z: 0),
				scale: array(x: 0.9, y: 0.9, z: 0.9))));
		set_entity_spec(@head, array(item: array(name: 'PLAYER_HEAD', meta: array(
			owneruuid: 'd5dcf43b-ffcf-412e-bbd1-33fabc8ad503',
			texture: 'eyJ0ZXh0dXJlcyI6eyJTS0lOIjp7InVybCI6Imh0dHA6Ly90ZXh0dXJlcy5taW5lY3JhZnQubmV0L3RleHR1cmUvNjc3NjE5ZTYwMDA1YzM4ZTRkNTA5Y2M5YTlmZTcyOTNhMzMyYzdiYzM4Yjg5MzM0MTc5MjkwMTA2YjAzMWJjMSJ9fX0='))));
	})[0];
	@ball['color'] = spawn_entity('BLOCK_DISPLAY', 1, @loc, closure(@display) {
		set_entity_spec(@display, array(blockdata: @ball['dyecolor'].'_STAINED_GLASS'));
		set_display_entity(@display, array(
			teleportduration: 1,
			glowcolor: _dye_to_rgb(@ball['dyecolor']),
			transformation: array(
				translation: array(x: -0.23, y: 0.0, z: -0.23),
				scale: array(x: 0.46, y: 0.46, z: 0.46))));
		add_scoreboard_tag(@display, 'remove');
	})[0];
	set_entity_rider(@ball['slime'], @ball['color']);
	
	@ball['velocity'] = array(x: 0, y: 0, z: 0);

	if(function_exists('set_entity_size')) {
		set_entity_size(@ball['id'], 0.4575, 0.4575);
	}
	spawn_particle(@loc, array(particle: 'BLOCK_CRACK', block: @ball['dyecolor'].'_STAINED_GLASS', count: 20, xoffset: 0.6, zoffset: 0.6));
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

proc _get_block_below(@loc, @v) {
	@block = get_block(@loc);
	if(@block !== 'AIR') {
		if(@block === 'BLACK_WOOL') {
			play_sound(@loc, array('sound': 'BLOCK_WOODEN_BUTTON_CLICK_ON', 'pitch': 0.5));
		}
		return(@block);
	}

	@rx = @loc['x'] - floor(@loc['x']);
	@dirx = '';
	if(@rx < 0.2287) {
		@dirx = 'west';
	} else if(@rx > 0.7713) {
		@dirx = 'east';
	}
	@blockX = if(@dirx, get_block(location_shift(@loc, @dirx)), @block);
	if(@blockX !== 'AIR') {
		// adjust ball velocity towards edge if hanging off
		if(@rx < 0.2287) {
			@v['x'] += @rx * 0.2;
		} else if(@rx > 0.7713) {
			@v['x'] -= (1.0 - @rx) * 0.2;
		}
	}

	@rz = @loc['z'] - floor(@loc['z']);
	@dirz = '';
	if(@rz < 0.2287) {
		@dirz = 'north';
	} else if(@rz > 0.7713) {
		@dirz = 'south';
	}
	@blockZ = if(@dirz, get_block(location_shift(@loc, @dirz)), @block);
	if(@blockZ !== 'AIR') {
		if(@rz < 0.2287) {
			@v['z'] += @rz * 0.2;
		} else if(@rz > 0.7713) {
			@v['z'] -= (1.0 - @rz) * 0.2;
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
