/*
	Gets the pitch for the given tone and octave
*/
proc _get_pitch(@tone, @octave) {
	switch(@tone) {
		case 'F#':
			if(@octave == 2) {
				return(2.0);
			} else if(@octave == 1) {
				return(1.0);
			}
			return(0.5);
		case 'G':
			if(@octave == 1) {
				return(1.06);
			}
			return(0.53);
		case 'G#':
			if(@octave == 1) {
				return(1.12);
			}
			return(0.56);
		case 'A':
			if(@octave == 1) {
				return(1.19);
			}
			return(0.6);
		case 'A#':
			if(@octave == 1) {
				return(1.26);
			}
			return(0.63);
		case 'B':
			if(@octave == 1) {
				return(1.33);
			}
			return(0.67);
		case 'C':
			if(@octave == 1) {
				return(1.41);
			}
			return(0.7);
		case 'C#':
			if(@octave == 1) {
				return(1.50);
			}
			return(0.75);
		case 'D':
			if(@octave == 1) {
				return(1.59);
			}
			return(0.79);
		case 'D#':
			if(@octave == 1) {
				return(1.68);
			}
			return(0.84);
		case 'E':
			if(@octave == 1) {
				return(1.78);
			}
			return(0.89);
		case 'F':
			if(@octave == 1) {
				return(1.89);
			}
			return(0.94);
		default:
			return(1.0);
	}
}

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
