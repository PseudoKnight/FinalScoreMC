/*
 * Gets the cell data from a map in the direction specified.
 * Returns null if outside of the map or invalid direction.
 */
proc _get_cell(@map, @c, @r, @dir) {
	try {
		switch(@dir) {
			case 'north':
				if(@r == 0) {
					return(null);
				}
				return(@map[@c][@r - 1]);
			case 'south':
				return(@map[@c][@r + 1]);
			case 'west':
				if(@c == 0) {
					return(null);
				}
				return(@map[@c - 1][@r]);
			case 'east':
				return(@map[@c + 1][@r]);
		}
	} catch(IndexOverflowException @ex) {
		// outside the map
	}
	return(null);
}

proc _adjacent_equals(@layoutMap, @c, @r, @type) {
	try {
		return(@layoutMap[@c + 1][@r] == @type
				|| (@c > 0 && @layoutMap[@c - 1][@r] == @type)
				|| @layoutMap[@c][@r + 1] == @type
				|| (@r > 0 && @layoutMap[@c][@r - 1] == @type));
	} catch(IndexOverflowException @ex) {
		// outside the map
		return(false);
	}
}

proc _direction_of_solid(@layoutMap, @c, @r) {
	proc _is_solid(@cell) {
		return(@cell === 'wall' || @cell === 'window' || @cell === 'column');
	}

	foreach(@dir in array('north', 'south', 'east', 'west')) {
		if(_is_solid(_get_cell(@layoutMap, @c, @r, @dir))) {
			return(@dir);
		}
	}
	return(null);
}

proc _direction_of_border(@layoutMap, @c, @r) {
	proc _is_room_border(@cell) {
		return(@cell === 'wall' || @cell === 'window' || @cell === 'door');
	}

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