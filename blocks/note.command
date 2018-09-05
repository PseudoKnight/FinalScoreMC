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
		if(!sk_can_build(@l) || get_block(@l) != 'NOTE_BLOCK') {
			die();
		}

		@instrument = reg_match('instrument\\=([a-z]+)', get_blockdata_string(@l))[1];
		@sound = 'BLOCK_NOTE_BLOCK_'.@instrument;
		switch(get_block(location_shift(@l, 'down'))) {
			case 'ICE':
			case 'PACKED_ICE':
				@sound = 'ENTITY_EXPERIENCE_ORB_PICKUP';
			case 'ANVIL':
				@sound = 'BLOCK_ANVIL_LAND';
			case 'TERRACOTTA':
			case 'WHITE_TERRACOTTA':
			case 'ORANGE_TERRACOTTA':
			case 'YELLOW_TERRACOTTA':
			case 'RED_TERRACOTTA':
			case 'PURPLE_TERRACOTTA':
			case 'PINK_TERRACOTTA':
			case 'MAGENTA_TERRACOTTA':
			case 'LIME_TERRACOTTA':
			case 'GREEN_TERRACOTTA':
			case 'GRAY_TERRACOTTA':
			case 'CYAN_TERRACOTTA':
			case 'BROWN_TERRACOTTA':
			case 'BLUE_TERRACOTTA':
			case 'BLACK_TERRACOTTA':
			case 'LIGHT_GRAY_TERRACOTTA':
			case 'LIGHT_BLUE_TERRACOTTA':
				@sound = 'BLOCK_NOTE_BLOCK_PLING';
			case 'SLIME_BLOCK':
				@sound = 'ENTITY_CHICKEN_EGG';
			case 'COAL_BLOCK':
				@sound = 'ENTITY_FIREWORK_ROCKET_BLAST';
			case 'SEA_LANTERN':
				@instrument = 'chime';
				@sound = 'BLOCK_NOTE_BLOCK_'.@instrument;
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
		play_sound(@l, array('sound': @sound, 'category': 'RECORDS', 'pitch': @pitch));
		set_blockdata_string(@l, 'note_block[note='.@clicks.',instrument='.@instrument.']');
	}
));
