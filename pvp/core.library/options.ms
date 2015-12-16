proc _create_options_menu(@id, @arena) {
	@inv = associative_array();
	@i = 0;
	@o = 0;
	foreach(@option: @values in @arena['options']) {
		foreach(@data: @value in @values) {
			@inv[(@o * 9) + @i] = array('name': 'INK_SACK', 'data': if(@arena[@option] == @value, 10, 8), 'meta': array(
					'display': color('bold').to_upper(@option), 
					'lore': array(color('green').color('bold').@value),
			));
			@i++;
		}
		@o++;
		@i = 0;
	}
	
	create_virtualchest(array(
		'id': @id.'options',
		'size': array_size(@arena['options']) * 9,
		'title': to_upper(@id).' OPTIONS',
	));
	update_virtualchest(@id.'options', @inv);
	
	bind(inventory_click, array('id': @id.'options', 'priority': 'HIGH'), array('slottype': 'CONTAINER', 'player': player()), @e, @id) {
		if(pget_virtualchest() != @id.'options'
		|| is_null(@e['slotitem'])
		|| is_null(@e['slotitem']['meta'])
		|| is_null(@e['slotitem']['meta']['display'])) {
			die();
		}
		@arena = get_value('arena', @id);
		@option = strip_colors(to_lower(@e['slotitem']['meta']['display']));
		@value = strip_colors(to_lower(@e['slotitem']['meta']['lore'][0]));
		@min = floor(@e['slot'] / 9) * 9;
		@max = ceil(@e['slot'] + 1 / 9) * 9 - 1;
		foreach(@slot: @item in @e['inventory']) {
			if(@slot < @min, continue())
			if(@slot > @max || is_null(@item), break())
			if(@slot == @e['slot']) {
				@e['inventory'][@slot]['data'] = 10;
			} else {
				@e['inventory'][@slot]['data'] = 8;
			}
		}
		play_sound(ploc(), array('sound': 'CLICK'), player());
		update_virtualchest(@id.'options', @e['inventory']);
		@arena[@option] = @value;
		store_value('arena', @id, @arena);
	}
}