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
