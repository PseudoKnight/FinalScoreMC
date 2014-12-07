# RECIPES

# Smooth Stone Slab (Double)
if(!get_recipe_for(array('type': 43, 'data': 8))) {
	add_recipe(array(
		'type': 'SHAPED',
		'result': array('type': 43, 'data': 8),
		'shape': array('A', 'A'),
		'ingredients': array('A': '44:0')
	))
}

# Smooth Sandstone Slab (Double)
if(!get_recipe_for(array('type': 43, 'data': 9))) {
	add_recipe(array(
		'type': 'SHAPED',
		'result': array('type': 43, 'data': 9, 'qty': 2),
		'shape': array('AA', 'AA'),
		'ingredients': array('A': '44:1')
	))
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