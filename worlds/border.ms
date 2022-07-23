/*
	If player moves outside an invisible and/or non-square (i.e. non-vanilla)
	world border, cancel to teleport them back.
 */
bind('player_move', array(priority: 'HIGHEST'), array(threshold: 16), @event) {
	@border = _get_worldborder(@event['world']);
	if(@border) {
		@loc = @event['to'];
		if(@loc['x'] > @border['x'] + @border['radiusX']
		|| @loc['x'] < @border['x'] - @border['radiusX']
		|| @loc['z'] > @border['z'] + @border['radiusZ']
		|| @loc['z'] < @border['z'] - @border['radiusZ']) {
			cancel();
			action_msg('Exceeded world border');
		}
	}
}

/*
	If a player takes fatal suffocation damage from being outside the worldborder,
	instead teleport them to world spawn.
 */
bind('entity_damage', array(priority: 'HIGH'), array(type: 'PLAYER', cause: 'SUFFOCATION'), @event) {
	if(@event['finalamount'] >= phealth(@event['id'])) {
		@loc = @event['location'];
		// special handling for shard
		if(@loc['world'] == 'shard') {

		}
		@border = get_world_border(@loc['world']);
		@center = @border['center'];
		@radius = @border['width'] / 2;
		if(@loc['x'] > @center['x'] + @radius
		|| @loc['x'] < @center['x'] - @radius
		|| @loc['z'] > @center['z'] + @radius
		|| @loc['z'] < @center['z'] - @radius) {
			cancel();
			set_timeout(1, closure(){
				set_ploc(@event['id'], _center(get_spawn(@loc['world']), -1));
			});
		}
	}
}