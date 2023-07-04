/*
	Modifies a location to be at the center of the block.
 */
proc _center(@loc, @height = 0.5) {
	if(is_associative(@loc)) {
		@loc['x'] = floor(@loc['x']) + 0.5;
		@loc['y'] = floor(@loc['y']) + @height;
		@loc['z'] = floor(@loc['z']) + 0.5;
	} else {
		@loc[0] = floor(@loc[0]) + 0.5;
		@loc[1] = floor(@loc[1]) + @height;
		@loc[2] = floor(@loc[2]) + 0.5;
	}
	return(@loc);
}
