/*
 * Gets the cell data from a map in the direction specified.
 * Returns null if outside of the map or invalid direction.
 */
proc _get_cell(@map, @c, @r, @dir) {
	if(@dir === 'north') {
		if(@r < 1) {
			return(null);
		}
		return(@map[@c][@r - 1]);
	} else if(@dir === 'south') {
		if(@r + 1 >= array_size(@map[@c])) {
			return(null);
		}
		return(@map[@c][@r + 1]);
	} else if(@dir === 'west') {
		if(@c < 1) {
			return(null);
		}
		return(@map[@c - 1][@r]);
	} else if(@dir === 'east') {
		if(@c + 1 >= array_size(@map)) {
			return(null);
		}
		return(@map[@c + 1][@r]);
	}
	return(null);
}

proc _adjacent_equals(@layoutMap, @c, @r, @type) {
	return(@c > 0 && @layoutMap[@c - 1][@r] === @type
		|| @r > 0 && @layoutMap[@c][@r - 1] === @type
		|| @c + 1 < array_size(@layoutMap) && @layoutMap[@c + 1][@r] === @type
		|| @r + 1 < array_size(@layoutMap[@c]) && @layoutMap[@c][@r + 1] === @type);
}

proc _direction_of_solid(@layoutMap, @c, @r) {
	foreach(@dir in array('north', 'south', 'east', 'west')) {
		@cell = _get_cell(@layoutMap, @c, @r, @dir);
		if(@cell === 'wall' || @cell === 'window' || @cell === 'column') {
			return(@dir);
		}
	}
	return(null);
}

proc _direction_of_border(@layoutMap, @c, @r) {
	foreach(@dir in array('north', 'south', 'east', 'west')) {
		@cell = _get_cell(@layoutMap, @c, @r, @dir);
		if(@cell === 'wall' || @cell === 'window' || @cell === 'door') {
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