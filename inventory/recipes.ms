# RECIPES

# Enchanted lore books
add_recipe(array(
	'type': 'SHAPELESS',
	'result': associative_array('name': 'ENCHANTED_BOOK', 'qty': 1, 'meta': associative_array(
		'display': color('k').'Enchanted Lore Book',
		'lore': array(color('k').'This is random text.', color('k').'More random text.'),
	)),
	'ingredients': array('387:0', '403:0')
));

# Bottle o' Enchanting experience storage
add_recipe(array(
	'type': 'SHAPELESS',
	'result': associative_array('name': 'EXP_BOTTLE', 'qty': 1),
	'ingredients': array('374:0')
));

# Special recipe handling (enchanted lore books and player heads)
bind('inventory_click', null, array('slottype': 'RESULT'), @event) {
	if(is_null(@event['slotitem'])) {
		die();
	}

	if(@event['inventorytype'] == 'WORKBENCH' || @event['inventorytype'] == 'CRAFTING') {
		if(@event['slotitem']['name'] == 'ENCHANTED_BOOK'
		&& strip_colors(@event['slotitem']['meta']['display']) === 'Enchanted Lore Book') {

			@slotitem = @event['slotitem'];

			foreach(@item in @event['inventory']) {
				if(is_null(@item), continue())
				if(@item['name'] == 'WRITTEN_BOOK') {

					@slotitem['meta']['display'] = colorize(@item['meta']['title']);

					@lines = split('\n', @item['meta']['pages'][0]);
					@wrappedLines = array();
					foreach(@line in @lines) {
						@wrappedLines = array_merge(@wrappedLines, _wrap_string(@line, 112));
					}
					foreach(@index: @line in @wrappedLines) {
						@wrappedLines[@index] = colorize(@line);
					}
					@slotitem['meta']['lore'] = @wrappedLines;

				} else if(@item['name'] == 'ENCHANTED_BOOK') {
					@slotitem['meta']['stored'] = @item['meta']['stored'];
				}
			}

			modify_event('slotitem', @slotitem);

		} else if(@event['slotitem']['name'] == 'EXP_BOTTLE') {
			@xp = ptexp();
			@qty = 7;
			if(@event['shiftclick']) {
				foreach(@item in @event['inventory']) {
					if(@item && @item['name'] == 'GLASS_BOTTLE') {
						@qty *= @item['qty'];
						break();
					}
				}
			}
			if(@xp >= @qty) {
				set_ptexp(@xp - @qty);
			} else {
				cancel();
			}
		}

	} else if(@event['inventorytype'] === 'ANVIL') {
		if(!is_null(@event['inventory'][1])
		&& @event['inventory'][1]['name'] == 'ENCHANTED_BOOK'
		&& @event['inventory'][1]['meta']['lore']) {
			# enchanted lore book

			@slotitem = @event['slotitem'];
			if(!is_null(@slotitem['meta']['display'])) {
				@slotitem['meta']['display'] = colorize(@slotitem['meta']['display']);
			} else {
				@slotitem['meta']['display'] = @event['inventory'][1]['meta']['display'];
			}
			@slotitem['meta']['lore'] = @event['inventory'][1]['meta']['lore'];

			if(array_size(@slotitem['meta']['enchants']) == 0) {
				@slotitem['meta']['enchants'][] = array('elevel': 1, 'etype': 'DURABILITY');
				@slotitem['meta']['flags'][] = 'HIDE_ENCHANTS';
			}

			modify_event('slotitem', @slotitem);

		} else if(@event['slotitem']['name'] == 'SKULL_ITEM'
		&& @event['slotitem']['data'] == 3
		&& !is_null(@event['slotitem']['meta'])
		&& !is_null(@event['slotitem']['meta']['display'])) {
			# named player head

			@event['slotitem']['meta']['owner'] = @event['slotitem']['meta']['display'];
			modify_event('slotitem', @event['slotitem']);
		}
	}
}

# Player head recipe
if(!get_recipe_for(array('name': 'SKULL_ITEM', 'data': 3))) {
	add_recipe(array(
		'type': 'SHAPED',
		'result': array('name': 'SKULL_ITEM', 'data': 3),
		'ingredients': array('S': '397:0', 'C': '337:0'),
		'shape': array('CCC', 'CSC', 'CCC'),
	));
}

# Skeleton skull recipe
if(!get_recipe_for(array('name': 'SKULL_ITEM', 'data': 0))) {
	add_recipe(array(
		'type': 'SHAPELESS',
		'result': array('name': 'SKULL_ITEM', 'data': 0),
		'ingredients': array('397:2'),
	));
}
