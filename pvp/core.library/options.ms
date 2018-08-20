proc _create_options_menu(@id, @arena) {
	@inv = associative_array();
	@i = 0;
	@o = 0;
	foreach(@option: @values in @arena['options']) {
		foreach(@data: @value in @values) {
			@inv[(@o * 9) + @i] = array('name': if(@arena[@option] == @value, 'LIME_DYE', 'GRAY_DYE'), 'meta': array(
					'display': color('bold').to_upper(@option),
					'lore': array(color('green').color('bold').@value),
			));
			@i++;
		}
		@o++;
		@i = 0;
	}

	create_virtual_inventory(@id.'options', array_size(@arena['options']) * 9, to_upper(@id).' OPTIONS', @inv);

	bind('inventory_click', array('id': @id.'options', 'priority': 'HIGH'), array('slottype': 'CONTAINER', 'player': player()), @e, @id) {
		if(pinventory_holder() != @id.'options'
		|| is_null(@e['slotitem'])
		|| is_null(@e['slotitem']['meta'])
		|| is_null(@e['slotitem']['meta']['display'])) {
			die();
		}
		@arena = get_value('arena', @id);
		@option = strip_colors(to_lower(@e['slotitem']['meta']['display']));
		@value = strip_colors(to_lower(@e['slotitem']['meta']['lore'][0]));
		@min = floor(@e['slot'] / 9) * 9;
		@max = ceil((@e['slot'] + 1) / 9) * 9 - 1;
		foreach(@slot in range(@min, @max)) {
			if(is_null(@e['inventory'][@slot])) {
				break();
			}
			if(@slot == @e['slot']) {
				@e['inventory'][@slot]['name'] = 'LIME_DYE';
			} else {
				@e['inventory'][@slot]['name'] = 'GRAY_DYE';
			}
		}
		play_sound(ploc(), array('sound': 'UI_BUTTON_CLICK'), player());
		set_inventory(@id.'options', @e['inventory']);
		@arena[@option] = @value;
		store_value('arena', @id, @arena);
	}
}
