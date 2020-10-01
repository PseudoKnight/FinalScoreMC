/*
 * Gets the cell data from a map in the direction specified.
 * Returns null if outside of the map or invalid direction.
 */
proc _get_cell(@map, @c, @r, @dir) {
	try {
		switch(@dir) {
			case 'north':
				return(@map[@c][@r - 1]);
			case 'south':
				return(@map[@c][@r + 1]);
			case 'west':
				return(@map[@c - 1][@r]);
			case 'east':
				return(@map[@c + 1][@r]);
		}
	} catch(IndexOverflowException @ex) {
		// outside the map
	}
	return(null);
}

proc _is_solid(@cell) {
	return(@cell == 'wall' || @cell == 'window' || @cell == 'column');
}

proc _is_room_border(@cell) {
	return(@cell == 'wall' || @cell == 'window' || @cell == 'door');
}

proc _direction_of_solid(@layoutMap, @c, @r) {
	foreach(@dir in array('north', 'south', 'east', 'west')) {
		if(_is_solid(_get_cell(@layoutMap, @c, @r, @dir))) {
			return(@dir);
		}
	}
	return(null);
}

proc _direction_of_border(@layoutMap, @c, @r) {
	foreach(@dir in array('north', 'south', 'east', 'west')) {
		if(_is_room_border(_get_cell(@layoutMap, @c, @r, @dir))) {
			return(@dir);
		}
	}
	return(null);
}

proc _get_direction(@random, @dirs = array('north', 'south', 'east', 'west')) {
	return(@dirs[integer(srand(@random) * array_size(@dirs))]);
}

/*
 * Gets the cell height of the nearest adjacent cell to this coordinate.
 */
proc _get_adjacent_height(@heightMap, @maxRoomHeight, @c, @r, @x, @z) {
	@height = -1;
	try {
		if(@x % 2 == 1) {
			@height = @heightMap[@c + 1][@r];
		} else {
			@height = @heightMap[@c - 1][@r];
		}
		// Will be max room height if not inside a room.
		// This is not desirable.
		if(@height != @maxRoomHeight) {
			return(@height);
		};
	} catch (IndexOverflowException @ex) {
		// outside map
	}
	try {
		if(@z % 2 == 1) {
			@height = @heightMap[@c][@r + 1];
		} else {
			@height = @heightMap[@c][@r - 1];
		}
	} catch (IndexOverflowException @ex) {
		// outside map
	}
	return(@height);
}

/*
 * Add block to chunk batch.
 * To minimize memory use, the chunk array alternates between location and material.
 * Therefore these chunk batches should always be processed sequentially.
 */
proc _add_to_chunk(@chunk, @loc, @material) {
	@chunk[] = @loc[];
	if(is_array(@material)) {
		@chunk[] = array_get_rand(@material);
	} else {
		@chunk[] = @material;
	}
}