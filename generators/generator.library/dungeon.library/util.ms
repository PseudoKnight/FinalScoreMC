proc _get_cell(@layoutMap, @c, @r, @dir) {
	try {
		switch(@dir) {
			case 'north':
				return(@layoutMap[@c][@r - 1]);
			case 'south':
				return(@layoutMap[@c][@r + 1]);
			case 'west':
				return(@layoutMap[@c - 1][@r]);
			case 'east':
				return(@layoutMap[@c + 1][@r]);
		}
	} catch(IndexOverflowException @ex) {
		// outside the map
	}
	return(@layoutMap[@c][@r]);
}

proc _is_solid(@cell) {
	return(@cell == 'wall' || @cell == 'window' || @cell == 'column');
}

proc _direction_of_solid(@layoutMap, @c, @r) {
	foreach(@dir in array('north', 'south', 'east', 'west')) {
		if(_is_solid(_get_cell(@layoutMap, @c, @r, @dir))) {
			return(@dir);
		}
	}
	return(null);
}

proc _get_direction(@random, @dirs = array('north', 'south', 'east', 'west')) {
	return(@dirs[integer(srand(@random) * array_size(@dirs))]);
}

proc _get_adjacent_height(@heightMap, @maxRoomHeight, @c, @r, @x, @z) {
	@height = -1;
	if(@x % 2 == 1) {
		try(@height = @heightMap[@c + 1][@r]);
	} else {
		try(@height = @heightMap[@c - 1][@r]);
	}
	if(@height != @maxRoomHeight) {
		return(@height);
	};
	if(@z % 2 == 1) {
		try(@height = @heightMap[@c][@r + 1]);
	} else {
		try(@height = @heightMap[@c][@r - 1]);
	}
	return(@height);
}
