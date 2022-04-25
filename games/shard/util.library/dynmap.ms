dm_create_marker('markers', array(
	type: 'AREA',
	world: @world,
	label: 'Shard',
	id: 'shard',
	corners: array(
		array(@minX, 0, @minZ, @world),
		array(@maxX, 0, @minZ, @world),
		array(@maxX, 0, @maxZ, @world),
		array(@minX, 0, @maxZ, @world),
	),
));
dm_set_marker_line_style('markers', 'shard', array(
	color: array(r: 255, g: 0, b: 0),
	opacity: 1,
	weight: 1,
));
dm_set_marker_fill_style('markers', 'shard', array(
	color: array(r: 255, g: 0, b: 0),
	opacity: 0.1,
));
