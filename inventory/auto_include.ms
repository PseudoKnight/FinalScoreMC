/*
	Removes all items from a player's inventory and armor slots
*/
proc _clear_pinv(@player) {
	if(!@player) {
		@player = player();
	}
	@world = pworld(@player);
	if(_is_survival_world(@world)) {
		return();
	}
	set_pinv(@player, associative_array(
		0: null, 1: null, 2: null, 3: null, 4: null, 5: null, 6: null, 7: null, 8: null,
		9: null, 10: null, 11: null, 12: null, 13: null, 14: null, 15: null, 16: null, 17: null,
		18: null, 19: null, 20: null, 21: null, 22: null, 23: null, 24: null, 25: null, 26: null,
		27: null, 28: null, 29: null, 30: null, 31: null, 32: null, 33: null, 34: null, 35: null,
		100: null, 101: null, 102: null, 103: null, -106: null
	));
}

/*
	Sets a player's inventory with a preset kit
*/
proc _equip_kit(@player, @inv) {
	if(!@player) {
		@player = player();
	}

	@worldInfo = _worlds_config()[pworld(@player)];
	switch(@worldInfo['group']) {
		case 'minigames':
			@mode = pmode(@player);
			if(@mode != @worldInfo['mode']) {
				set_pmode(@player, @worldInfo['mode']);
			}
			_clear_pinv(@player);
			@pdata = _pdata(@player);
			@kit = array(
				2: array('name': 'BOOK', 'meta': array(
					'display': 'Park Directory',
				)),
				3: array('name': 'COOKED_MUTTON', 'qty': 32, 'meta': array(
					'display': 'Frog Legs',
					'lore': array('Good eatin\''),
				)),
			);
			if(array_index_exists(@pdata, 'support') && @pdata['support'] >= 10) {
				@kit[4] = array(
					'name': 'FIREWORK',
					'meta': array(
						'display': colorize('&r&kX&a&l Random Firework &r&kX'),
						'lore': array(
							color('f').'Available to ',
							color('f').'server supporters',
						)
					)
				);
			}
			if(is_array(@inv)) {
				set_pinv(@player, array_merge(@kit, @inv));
			} else {
				set_pinv(@player, @kit);
			}
			if(@mode != 'CREATIVE') {
				set_pflight(@player, false);
			}

		case 'dev':
			_clear_pinv(@player);
			set_pinv(@player, associative_array(
				0: associative_array('name': 'COMPASS', 'meta': associative_array(
					'display': 'Teleporter',
				)),
				1: associative_array('name': 'GOLD_AXE', 'meta': associative_array(
					'display': 'WorldEdit Selector',
				)),
			));
	}
}

/*
	Returns specific item meta or null if it doesn't exist
*/
proc _item_meta(@item, @index) {
	if(is_null(@item)
	|| is_null(@item['meta'])) {
		return(null);
	}
	return(@item['meta'][@index]);
}

/*
	Compacts all an inventory array by removing unnecessary keys in item arrays
*/
proc _minify_inv(@inv, @keepnulls = false) {
	proc _minify_item(@item) {
		array_remove(@item, 'type');
		array_remove(@item, 'enchants');
		if(@item['data'] == 0) {
			array_remove(@item, 'data');
		}
		if(@item['qty'] == 1) {
			array_remove(@item, 'qty');
		}
		if(is_null(@item['meta'])) {
			array_remove(@item, 'meta');
		} else {
			if(array_size(@item['meta']['enchants']) == 0) {
				array_remove(@item['meta'], 'enchants');
			}
			if(is_null(@item['meta']['display'])) {
				array_remove(@item['meta'], 'display');
			}
			if(is_null(@item['meta']['lore'])) {
				array_remove(@item['meta'], 'lore');
			}
			if(array_index_exists(@item['meta'], 'firework')
			&& is_null(@item['meta']['firework'])) {
				array_remove(@item['meta'], 'firework');
			}
			if(@item['meta']['repair'] == 0) {
				array_remove(@item['meta'], 'repair');
			}
			if(array_size(@item['meta']['flags']) == 0) {
				array_remove(@item['meta'], 'flags');
			}
			if(array_index_exists(@item['meta'], 'inventory')) {
				_minify_inv(@item['meta']['inventory']);
			}
		}
	}

	if(array_index_exists(@inv, 'type')) {
		_minify_item(@inv);
	} else {
		foreach(@slot: @item in @inv) {
			if(@item == null) {
				if(!@keepnulls) {
					array_remove(@inv, @slot);
				}
			} else {
				_minify_item(@item);
			}
		}
	}
}

/*
	Returns how many of an item an inventory contains at a location.
	@item: 0:0 format
*/
proc _get_inventory_count(@loc, @item) {
	try {
		@inv = get_inventory(@loc);
	} catch(FormatException @ex) {
		return(null);
	}
	if(is_numeric(@item)) {
		@item .= ':0';
	}
	@count = 0;
	foreach(@i in @inv) {
		if(!is_null(@i) && (@i['type'].':'.@i['data'] === @item || @item === 'all')) {
			@count += @i['qty'];
		}
	}
	return(@count);
}