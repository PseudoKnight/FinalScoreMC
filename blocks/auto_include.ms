/*
	Gets the pitch for the given tone and octave
*/
proc _get_pitch(@tone, @octave, @tones = array(
	'F#': array(0.5, 1.0, 2.0),
	'GB': 'F#',
	'G': array(0.53, 1.06),
	'G#': array(0.56, 1.12),
	'AB': 'G#',
	'A': array(0.6, 1.19),
	'A#': array(0.63, 1.26),
	'BB': 'A#',
	'B': array(0.67, 1.33),
	'C': array(0.7, 1.41),
	'C#': array(0.75, 1.5),
	'DB': 'C#',
	'D': array(0.79, 1.59),
	'D#': array(0.84, 1.68),
	'EB': 'D#',
	'E': array(0.89, 1.78),
	'F': array(0.94, 1.89),
)) {
	try {
		@pitches = @tones[@tone];
		if(is_string(@pitches)) {
			// convert flat to sharp
			@pitches = @tones[@pitches];
		}
		return(@pitches[@octave]);
	} catch (IndexOverflowException @ex) {
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
