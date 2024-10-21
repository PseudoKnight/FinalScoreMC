// Logs spawning of a wither
bind('block_place', null, array(block: 'WITHER_SKELETON_SKULL'), @event) {
	@loc = @event['location'];
	foreach(@dir in array('north', 'south', 'east', 'west', 'up', 'down')) {
		@block = get_block(location_shift(@loc, @dir));
		if(@block === 'SOUL_SAND' || @block === 'SOUL_SOIL') {
			@player = player();
			@stringLoc = floor(@loc['x']).','.floor(@loc['y']).','.floor(@loc['z']).' '._world_name(@loc['world']);
			console("@player spawning a wither at @stringLoc!", false);
			break();
		}
	}
}