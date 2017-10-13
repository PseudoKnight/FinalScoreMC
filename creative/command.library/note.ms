register_command('note', array(
	'description': 'Sets the exact note of a noteblock.',
	'usage': '/note <note> [octave]',
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		return(array());
	},
	'executor': closure(@alias, @sender, @args, @info) {
		if(!@args) {
			return(false);
		}
		
		@l = pcursor();
		if(!sk_can_build(@l) || get_block_at(@l) != '25:0') {
			die();
		}
	
		@instrument = 'NOTE_PIANO';
		switch(split(':', get_block_at(_relative(@l, 'down')))[0]) {
			case '1':
				@instrument = 'NOTE_BASS_DRUM';
			case '5':
			case '17':
				@instrument = 'NOTE_BASS_GUITAR';
			case '12':
			case '13':
				@instrument = 'NOTE_SNARE_DRUM';
			case '20':
				@instrument = 'NOTE_STICKS';
			case '79':
			case '174':
				@instrument = 'ORB_PICKUP';
			case '159':
			case '172':
				@instrument = 'NOTE_PLING';
			case '165':
				@instrument = 'CHICKEN_EGG_POP';
			case '173':
				@instrument = 'FIREWORK_BLAST';
		}
	
		@clicks = @args[0];
		@octave = 0;
		if(array_size(@args) == 2) {
			@octave = integer(@args[1]);
		}
		@pitch = 0.5;
		@notes = array('F#', 'G', 'G#', 'A', 'A#', 'B', 'C', 'C#', 'D', 'D#', 'E', 'F');
		if(!is_numeric(@clicks)) {
			@pitch = _get_pitch(to_upper(@args[0]), @octave);
			@clicks = array_index(@notes, to_upper(@args[0])) + (@octave * 12);
		} else {
			@pitch = _get_pitch(@notes[@clicks % 12], floor(@clicks / 12));
		}
		play_sound(@l, array('sound': @instrument, 'category': 'RECORDS', 'pitch': @pitch));
		sudo('/blockdata '.@l[0].' '.@l[1].' '.@l[2].' {"note":'.@clicks.'b}');
	}
));
