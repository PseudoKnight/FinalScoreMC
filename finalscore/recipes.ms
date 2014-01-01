# RECIPES
if(!get_recipe_for(array('type': 43, 'data': 8))) {
	add_recipe(array(
		'type': 'SHAPELESS',
		'result': array('type': 43, 'data': 8),
		'ingredients': array('44', '44')
	))
	console('Recipe for smooth stone double step loaded.')
}
if(!get_recipe_for(array('type': 43, 'data': 9))) {
	add_recipe(array(
		'type': 'SHAPELESS',
		'result': array('type': 43, 'data': 9, 'qty': 2),
		'ingredients': array('44:1', '44:1', '44:1', '44:1')
	))
	console('Recipe for smooth sandstone double step loaded.')
}
if(!get_recipe_for(array('type': 17, 'data': 12))) {
	add_recipe(array(
		'type': 'SHAPELESS',
		'result': array('type': 17, 'data': 12, 'qty': 4),
		'ingredients': array('17:0', '17:0', '17:0', '17:0')
	))
	console('Recipe for oak log cube loaded.')
}
if(!get_recipe_for(array('type': 17, 'data': 13))) {
	add_recipe(array(
		'type': 'SHAPELESS',
		'result': array('type': 17, 'data': 13, 'qty': 4),
		'ingredients': array('17:1', '17:1', '17:1', '17:1')
	))
	console('Recipe for spruce log cube loaded.')
}
if(!get_recipe_for(array('type': 17, 'data': 14))) {
	add_recipe(array(
		'type': 'SHAPELESS',
		'result': array('type': 17, 'data': 14, 'qty': 4),
		'ingredients': array('17:2', '17:2', '17:2', '17:2')
	))
	console('Recipe for birch log cube loaded.')
}
if(!get_recipe_for(array('type': 17, 'data': 15))) {
	add_recipe(array(
		'type': 'SHAPELESS',
		'result': array('type': 17, 'data': 15, 'qty': 4),
		'ingredients': array('17:3', '17:3', '17:3', '17:3')
	))
	console('Recipe for jungle log cube loaded.')
}
if(!get_recipe_for(array('type': 162, 'data': 12))) {
	add_recipe(array(
		'type': 'SHAPELESS',
		'result': array('type': 162, 'data': 12, 'qty': 4),
		'ingredients': array('162:0', '162:0', '162:0', '162:0')
	))
	console('Recipe for acacia log cube loaded.')
}
if(!get_recipe_for(array('type': 162, 'data': 13))) {
	add_recipe(array(
		'type': 'SHAPELESS',
		'result': array('type': 162, 'data': 13, 'qty': 4),
		'ingredients': array('162:1', '162:1', '162:1', '162:1')
	))
	console('Recipe for dark oak log cube loaded.')
}

# MAKE LOG CUBES PLACEABLE
bind('block_place', null, array('type': 17), @e,
	@item = pinv(player(), null)
	if(@item['data'] >= 12 && sk_can_build(@e['location'])) {
		set_block_at(@e['location'], '17:'.@item['data'])
	}
)

bind('block_place', null, array('type': 162), @e,
	@item = pinv(player(), null)
	if(@item['data'] >= 12 && sk_can_build(@e['location'])) {
		set_block_at(@e['location'], '162:'.@item['data'])
	}
)