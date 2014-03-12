# RECIPES
if(!get_recipe_for(array('type': 48, 'data': 0))) {
	add_recipe(array(
		'type': 'SHAPELESS',
		'result': array('type': 48, 'data': 0),
		'ingredients': array('4', '106')
	))
}
if(!get_recipe_for(array('type': 98, 'data': 1))) {
	add_recipe(array(
		'type': 'SHAPELESS',
		'result': array('type': 98, 'data': 1),
		'ingredients': array('98:0', '106')
	))
}
if(!get_recipe_for(array('type': 98, 'data': 3))) {
	add_recipe(array(
		'type': 'SHAPELESS',
		'result': array('type': 98, 'data': 3),
		'ingredients': array('44:5', '44:5')
	))
}
if(!get_recipe_for(array('type': 43, 'data': 8))) {
	add_recipe(array(
		'type': 'SHAPELESS',
		'result': array('type': 43, 'data': 8),
		'ingredients': array('44', '44')
	))
}
if(!get_recipe_for(array('type': 43, 'data': 9))) {
	add_recipe(array(
		'type': 'SHAPELESS',
		'result': array('type': 43, 'data': 9, 'qty': 2),
		'ingredients': array('44:1', '44:1', '44:1', '44:1')
	))
}
if(!get_recipe_for(array('type': 17, 'data': 12))) {
	add_recipe(array(
		'type': 'SHAPELESS',
		'result': array('type': 17, 'data': 12, 'qty': 4),
		'ingredients': array('17:0', '17:0', '17:0', '17:0')
	))
}
if(!get_recipe_for(array('type': 17, 'data': 13))) {
	add_recipe(array(
		'type': 'SHAPELESS',
		'result': array('type': 17, 'data': 13, 'qty': 4),
		'ingredients': array('17:1', '17:1', '17:1', '17:1')
	))
}
if(!get_recipe_for(array('type': 17, 'data': 14))) {
	add_recipe(array(
		'type': 'SHAPELESS',
		'result': array('type': 17, 'data': 14, 'qty': 4),
		'ingredients': array('17:2', '17:2', '17:2', '17:2')
	))
}
if(!get_recipe_for(array('type': 17, 'data': 15))) {
	add_recipe(array(
		'type': 'SHAPELESS',
		'result': array('type': 17, 'data': 15, 'qty': 4),
		'ingredients': array('17:3', '17:3', '17:3', '17:3')
	))
}
if(!get_recipe_for(array('type': 162, 'data': 12))) {
	add_recipe(array(
		'type': 'SHAPELESS',
		'result': array('type': 162, 'data': 12, 'qty': 4),
		'ingredients': array('162:0', '162:0', '162:0', '162:0')
	))
}
if(!get_recipe_for(array('type': 162, 'data': 13))) {
	add_recipe(array(
		'type': 'SHAPELESS',
		'result': array('type': 162, 'data': 13, 'qty': 4),
		'ingredients': array('162:1', '162:1', '162:1', '162:1')
	))
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