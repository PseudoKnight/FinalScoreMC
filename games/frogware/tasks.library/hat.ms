proc _fw_start_task(@secs) {
	@mats = all_materials();
	@hat = null;
	@entity = null;
	@attempts = 10;
	do {
		@hat = array_get_rand(@mats);
		if(!material_info(@hat, 'isItem')) {
			continue();
		}
		// drop the desired items first
		@count = _fw_total_players() * 2;
		for(@i = 0, @i < @count, @i++) {
			@entity = drop_item(_fw_loc(), array(name: @hat));
		}
	} while(--@attempts && !entity_exists(@entity))

	if(!@attempts) {
		console('Failed to create item drops');
	}

	update_bar('fw', array(title: 'Put on a fancy hat! '._to_upper_camel_case(@hat)));

	// now drop some random items
	@count = @secs * 10;
	for(@i = 0, @i < @count, @i++) {
		@mat = array_get_rand(@mats);
		if(!material_info(@mat, 'isItem')) {
			continue();
		}
		drop_item(_fw_loc(), array(name: @mat))
	}

	bind('player_armor_change', array(id: 'fwtask'), null, @event, @hat) {
		if(_fw_player(player())
		&& @event['slottype'] == 'HEAD'
		&& @event['newitem']
		&& @event['newitem']['name'] == @hat
		&& _fw_change_team(player(), 'winners')) {
			play_sound(ploc(), array(sound: 'ENTITY_ZOMBIE_ATTACK_IRON_DOOR'), player());
		}
	}
}

proc _fw_end_task(@secs) {
	_remove_region_entities('frogware');
}