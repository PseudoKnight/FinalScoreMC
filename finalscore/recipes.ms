# RECIPES

# Enchanted lore books
if(!get_recipe_for(array('type': 403))) {
	add_recipe(array(
		'type': 'SHAPELESS',
		'result': array('type': 403, 'qty': 1, 'meta': array(
			'display': color('k').'Enchanted Lore Book',
			'lore': array(color('k').'This is random text.', color('k').'More random text.'),
		)),
		'ingredients': array('387:0', '403:0')
	));
}

bind('inventory_click', null, array('slottype': 'RESULT'), @event) {
	if(is_null(@event['slotitem']), die())
	
	if(@event['inventorytype'] == 'WORKBENCH') {
		if(@event['slotitem']['type'] == 403 
		&& strip_colors(@event['slotitem']['meta']['display']) == 'Enchanted Lore Book') {
		
			@slotitem = @event['slotitem'];
			
			foreach(@item in @event['inventory']) {
				if(is_null(@item), continue())
				if(@item['type'] == 387) {
				
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
					
				} else if(@item['type'] == 403) {
					@slotitem['meta']['stored'] = @item['meta']['stored'];
				}
			}
			
			modify_event('slotitem', @slotitem);
			
		}
		
	} else if(@event['inventorytype'] == 'ANVIL' 
	&& !is_null(@event['inventory'][1])
	&& @event['inventory'][1]['type'] == 403
	&& @event['inventory'][1]['meta']['lore']) {
	
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
		
	}
}

# Oak Log Cube (6-sided bark)
if(!get_recipe_for(array('type': 17, 'data': 12))) {
	add_recipe(array(
		'type': 'SHAPED',
		'result': array('type': 17, 'data': 12, 'qty': 4),
		'shape': array('AA', 'AA'),
		'ingredients': array('A': '17:0')
	))
}

# Spruce Log Cube (6-sided bark)
if(!get_recipe_for(array('type': 17, 'data': 13))) {
	add_recipe(array(
		'type': 'SHAPED',
		'result': array('type': 17, 'data': 13, 'qty': 4),
		'shape': array('AA', 'AA'),
		'ingredients': array('A': '17:1')
	))
}

# Birch Log Cube (6-sided bark)
if(!get_recipe_for(array('type': 17, 'data': 14))) {
	add_recipe(array(
		'type': 'SHAPED',
		'result': array('type': 17, 'data': 14, 'qty': 4),
		'shape': array('AA', 'AA'),
		'ingredients': array('A': '17:2')
	))
}

# Jungle Log Cube (6-sided bark)
if(!get_recipe_for(array('type': 17, 'data': 15))) {
	add_recipe(array(
		'type': 'SHAPED',
		'result': array('type': 17, 'data': 15, 'qty': 4),
		'shape': array('AA', 'AA'),
		'ingredients': array('A': '17:3')
	))
}

# Acacia Log Cube (6-sided bark)
if(!get_recipe_for(array('type': 162, 'data': 12))) {
	add_recipe(array(
		'type': 'SHAPED',
		'result': array('type': 162, 'data': 12, 'qty': 4),
		'shape': array('AA', 'AA'),
		'ingredients': array('A': '162:0')
	))
}

# Dark Oak Log Cube (6-sided bark)
if(!get_recipe_for(array('type': 162, 'data': 13))) {
	add_recipe(array(
		'type': 'SHAPED',
		'result': array('type': 162, 'data': 13, 'qty': 4),
		'shape': array('AA', 'AA'),
		'ingredients': array('A': '162:1')
	))
}

# MAKE LOG CUBES PLACEABLE
bind(block_place, null, array('type': 17), @e) {
	@item = pinv(player(), null)
	if(@item['data'] >= 12 && sk_can_build(@e['location'])) {
		set_block_at(@e['location'], '17:'.@item['data'])
	}
}

bind(block_place, null, array('type': 162), @e) {
	@item = pinv(player(), null)
	if(@item['data'] >= 12 && sk_can_build(@e['location'])) {
		set_block_at(@e['location'], '162:'.@item['data'])
	}
}