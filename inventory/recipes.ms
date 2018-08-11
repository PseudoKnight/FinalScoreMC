# RECIPES

# Player head recipes
add_recipe(array(
	'key': 'skeleton_to_player_skull',
	'type': 'SHAPED',
	'result': array('name': 'SKULL_ITEM', 'data': 3),
	'ingredients': array(
		'S': array('name': 'SKULL_ITEM', 'data': 0),
		'C': array('name': 'CLAY_BALL')
	),
	'shape': array(
		'CCC',
		'CSC',
		'CCC'
	),
));

add_recipe(array(
	'key': 'wither_to_player_skull',
	'type': 'SHAPED',
	'result': array('name': 'SKULL_ITEM', 'data': 3),
	'ingredients': array(
		'S': array('name': 'SKULL_ITEM', 'data': 1),
		'C': array('name': 'CLAY_BALL')
	),
	'shape': array(
		'CCC',
		'CSC',
		'CCC'
	),
));

# Skeleton skull recipe
add_recipe(array(
	'key': 'skeleton_skull',
	'type': 'SHAPELESS',
	'result': array('name': 'SKULL_ITEM', 'data': 0),
	'ingredients': array(array('name': 'SKULL_ITEM', 'data': 2)),
));

# Enchanted lore books
add_recipe(array(
	'key': 'enchanted_lore_book',
	'type': 'SHAPELESS',
	'result': array('name': 'ENCHANTED_BOOK', 'qty': 1, 'meta': array(
		'display': color('k').'Enchanted Lore Book',
		'lore': array(color('k').'This is random text.', color('k').'More random text.'),
	)),
	'ingredients': array(array('name': 'WRITTEN_BOOK'), array('name': 'ENCHANTED_BOOK')),
));

# Bottle o' Enchanting experience storage
add_recipe(array(
	'key': 'exp_bottle',
	'type': 'SHAPELESS',
	'result': associative_array('name': 'EXP_BOTTLE', 'qty': 1),
	'ingredients': array(array('name': 'GLASS_BOTTLE')),
));

# Spawner egg ingredient
add_recipe(array(
	'key': 'spawner_egg_in_firework',
	'type': 'SHAPELESS',
	'result': associative_array('name': 'FIREWORK', 'qty': 1),
	'ingredients': array(array('name': 'FIREWORK'), array('name': 'MONSTER_EGG')),
));

# Fix broken enchantment books
add_recipe(array(
	'key': 'fix_enchanted_book',
	'type': 'SHAPELESS',
	'result': array('name': 'ENCHANTED_BOOK', 'qty': 1, 'meta': array('display': 'Fix Enchanted Book')),
	'ingredients': array(array('name': 'BOOK')),
));

# Faster bone -> bone-block recipe
add_recipe(array(
	'key': 'bone_to_bone_block',
	'type': 'SHAPELESS',
	'result': array('name': 'BONE_BLOCK', 'qty': 3),
	'ingredients': array(array('name': 'BONE', 'qty': 9)),
));

# Ice -> Packed Ice (1.13)
add_recipe(array(
	'key': 'ice_to_packed_ice',
	'type': 'SHAPELESS',
	'result': array('name': 'PACKED_ICE'),
	'ingredients': array(array('name': 'ICE', 'qty': 9)),
));

# Special recipe handling (eg. enchanted lore books, exp bottles, player heads)
bind('inventory_click', null, array('slottype': 'RESULT'), @event) {
	@slotitem = @event['slotitem'];
	if(is_null(@slotitem)) {
		die();
	}

	if(@event['inventorytype'] == 'WORKBENCH' || @event['inventorytype'] == 'CRAFTING') {
		
		if(@slotitem['name'] == 'ENCHANTED_BOOK') {
			if(strip_colors(@slotitem['meta']['display']) === 'Enchanted Lore Book') {
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
				
			} else {
				# Fix broken enchantment books
				@stored = null;
				foreach(@item in @event['inventory']) {
					if(@item) {
						if(@item['name'] == 'BOOK') {
							if(@item['meta'] && @item['meta']['enchants']) {
								@stored = @item['meta']['enchants'];
								break();
							} else {
								die();
							}
						}
					}
				}
				if(@stored) {
					@slotitem['meta'] = array('stored': @stored, 'display': null);
					modify_event('slotitem', @slotitem);
				}
			}

		} else if(@slotitem['name'] == 'EXP_BOTTLE') {
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
			
		} else if(@slotitem['name'] == 'FIREWORK') {
			@meta = null;
			@type = null;
			@count = array(0, 0);
			foreach(@item in @event['inventory']) {
				if(@item) {
					if(@item['name'] == 'FIREWORK') {
						@meta = @item['meta'];
						if(@meta && @meta['lore'] && array_size(@meta['lore']) == 3) {
							cancel();
							die();
						}
						@count[0] = @item['qty'];
					} else if(@item['name'] == 'MONSTER_EGG') {
						@type = @item['meta']['spawntype'];
						@count[1] = @item['qty'];
					}
				}
			}
			if(!@type) {
				die();
			}
			if(@event['shiftclick']) {
				@slotitem['qty'] = min(@count[0], @count[1]);
			}
			if(!@meta) {
				@slotitem['meta'] = array('lore': array());
			} else {
				if(!@meta['lore']) {
					@meta['lore'] = array();
				}
				@slotitem['meta'] = @meta;
			}
			@slotitem['meta']['lore'][] = color('gray').'Spawn Type: '.@type;
			modify_event('slotitem', @slotitem);
			
		}

	} else if(@event['inventorytype'] === 'ANVIL') {
		if(!is_null(@event['inventory'][1])
		&& @event['inventory'][1]['name'] == 'ENCHANTED_BOOK'
		&& @event['inventory'][1]['meta']['lore']) {
			# enchanted lore book

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

		} else if(@slotitem['name'] == 'SKULL_ITEM'
		&& @slotitem['data'] == 3
		&& !is_null(@slotitem['meta'])
		&& !is_null(@slotitem['meta']['display'])) {
			# named player head
			@slotitem['meta']['owner'] = @slotitem['meta']['display'];
			modify_event('slotitem', @slotitem);
		}
	}
}
