proc _pvp_msg(@pvp, @message) {
	foreach(@player in array_keys(@pvp['players'])) {
		tmsg(@player, @message);
	}
	foreach(@spectator in @pvp['spectators']) {
		tmsg(@spectator, @message);
	}
}

proc _squared_distance_to_segment(@p1, @p2a, @p2b) {
	@vx = @p2b['x'] - @p2a['x'];
	@vy = @p2b['y'] - @p2a['y'];
	@vz = @p2b['z'] - @p2a['z'];

	@wx = @p1['x'] - @p2a['x'];
	@wy = @p1['y'] - @p2a['y'];
	@wz = @p1['z'] - @p2a['z'];

	@c1 = @wx * @vx + @wy * @vy + @wz * @vz;
	if(@c1 <= 0) {
		return(((@p1['x'] - @p2a['x']) ** 2) + ((@p1['y'] - @p2a['y']) ** 2) + ((@p1['z'] - @p2a['z']) ** 2));
	}

	@c2 = @vx * @vx + @vy * @vy + @vz * @vz;
	if(@c2 <= @c1) {
		return(((@p1['x'] - @p2b['x']) ** 2) + ((@p1['y'] - @p2b['y']) ** 2) + ((@p1['z'] - @p2b['z']) ** 2));
	}

	@b = @c1 / @c2;
	@bx = @p2a['x'] + @b * @vx;
	@by = @p2a['y'] + @b * @vy;
	@bz = @p2a['z'] + @b * @vz;
	return(((@p1['x'] - @bx) ** 2) + ((@p1['y'] - @by) ** 2) + ((@p1['z'] - @bz) ** 2));
}

proc _pvp_hat_spawn(@id, @team, @loc) {
	@pvp = import('pvp'.@id)
	if(is_null(@loc)) {
		@loc = @pvp['spawn'][@team][0];
	}
	@hat = drop_item(@loc, @pvp['team'][@team]['captainhat'])
	set_entity_velocity(@hat, array(0, 0, 0))
}

/*
	Returns the max distance on the x or z axis between two locations
*/
proc _horizontal_distance(@loc1, @loc2) {
	return(max(sqrt((@loc1[0] - @loc2[0]) ** 2), sqrt((@loc1[2] - @loc2[2]) ** 2)))
}

/*
	Core game interval (overrided by game modes)
*/
proc _interval(@pvp, @id){
	return(false);
}

/*
	Core arena preparation (overrided by arena code)
*/
proc _prepare_arena(@pvp) {
	noop();
}
