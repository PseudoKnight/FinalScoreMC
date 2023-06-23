/*
	If player moves outside an invisible and/or non-square (i.e. non-vanilla)
	world border, cancel to teleport them back.
 */
bind('player_move', array(priority: 'HIGHEST'), array(threshold: 16), @event) {
	@border = _get_worldborder(@event['world']);
	if(@border) {
		@to = @event['to'];
		if(@to['x'] > @border['x'] + @border['radiusX']
		|| @to['x'] < @border['x'] - @border['radiusX']
		|| @to['z'] > @border['z'] + @border['radiusZ']
		|| @to['z'] < @border['z'] - @border['radiusZ']) {
			@safeLoc = @event['from'];
			@safeLoc['yaw'] = @to['yaw'];
			@safeLoc['pitch'] = @to['pitch'];
			@vehicle = pvehicle();
			if(@vehicle) {
				set_entity_rider(null, puuid());
				set_entity_loc(@vehicle, @safeLoc);
				set_ploc(location_shift(@safeLoc, 'down'));
				play_sound(@safeLoc, array(sound: 'ENTITY_BLAZE_SHOOT'));
			} else {
				set_ploc(location_shift(@safeLoc, 'down'));
				play_sound(@safeLoc, array(sound: 'ENTITY_BLAZE_SHOOT'));
			}
			action_msg('Exceeded world border');
			set_pborder(array(
				center: array(@border['x'], 0, @border['z']), 
				width: @border['radiusX'] * 2, 
				warningdistance: 16,
			));
		} else {
			@border = pborder();
			if(@border != null) {
				if(@border['warningdistance'] > 0) {
					set_pborder(array(warningdistance: 0));
				} else {
					set_pborder(null);
				}
			}
		}
	}
}

/*
	If a player takes fatal damage from being outside the worldborder,
	instead teleport them to world spawn.
 */
bind('entity_damage', array(priority: 'HIGH'), array(type: 'PLAYER', cause: 'WORLD_BORDER'), @event) {
	if(@event['finalamount'] >= phealth(@event['id'])) {
		cancel();
		set_timeout(1, closure(){
			set_ploc(@event['id'], _center(get_spawn(@loc['world']), -1));
		});
	}
}