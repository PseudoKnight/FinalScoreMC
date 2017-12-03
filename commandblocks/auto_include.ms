/*
	Returns a new shifted location from the origin based on relative Minecraft coordinate inputs
*/
proc _relative_coords(@originloc, @x, @y, @z) {
	@loc = @originloc[]
	if(@x[0] === '~') {
		if(@x === '~') {
			@loc['x'] = @originloc['x'];
		} else {
			@loc['x'] = @originloc['x'] + substr(@x, 1);
		}
	} else {
		@loc['x'] = @x;
	}
	if(@y[0] === '~') {
		if(@y === '~') {
			@loc['y'] = @originloc['y'];
		} else {
			@loc['y'] = @originloc['y'] + substr(@y, 1);
		}
	} else {
		@loc['y'] = @y;
	}
	if(@z[0] === '~') {
		if(@z === '~') {
			@loc['z'] = @originloc['z'];
		} else {
			@loc['z'] = @originloc['z'] + substr(@z, 1);
		}
	} else {
		@loc['z'] = @z;
	}
	return(@loc);
}
