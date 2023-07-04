register_command('note', array(
	description: 'Sets the exact note of a noteblock.',
	usage: '/note <note> [octave]',
	tabcompleter: closure(return(array())),
	executor: closure(@alias, @sender, @args, @info) {
		if(!@args) {
			return(false);
		}

		@l = ray_trace(10)['block'];
		if(@l == null) {
			die(color('gold').'No noteblock in range.');
		} else if(!sk_can_build(@l)){
			die(color('gold').'You cannot build there.');
		} else if(get_block(@l) != 'NOTE_BLOCK') {
			die(color('gold').'That is not a noteblock. Found: '.get_block(@l));
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
			case 'SOUL_SAND':
				@instrument = 'cow_bell';
				@sound = 'BLOCK_NOTE_BLOCK_COW_BELL';
			case 'IRON_BLOCK':
				@instrument = 'iron_xylophone';
				@sound = 'BLOCK_NOTE_BLOCK_IRON_XYLOPHONE';
		}


		@note = @args[0];
		@octave = 0;
		if(array_size(@args) == 2) {
			@octave = integer(@args[1]) - 1;
		}
		if(!is_numeric(@note)) {
			@notes = array('F#', 'G', 'G#', 'A', 'A#', 'B', 'C', 'C#', 'D', 'D#', 'E', 'F');
			@notesB = array('GB', 'G', 'AB', 'A', 'BB', 'B', 'C', 'DD', 'D', 'EB', 'E', 'F');
			@note = to_upper(@note);
			@index = array_index(@notes, @note);
			if(is_null(@index)) {
				// try flats
				@index = array_index(@notesB, @note);
				if(!@index) {
					die('Invalid note: '.@note);
				}
			}
			@note = @index + (@octave * 12);
		}
		if(@note < 0 || @note > 24) {
			die('Invalid note');
		}
		@pitch = 2 ** ((@note - 12) / 12);
		play_sound(@l, array(sound: @sound, category: 'RECORDS', pitch: @pitch));
		set_blockdata_string(@l, 'note_block[note='.@note.',instrument='.@instrument.']');
		@l['x'] += 0.5;
		@l['y'] += 1.3;
		@l['z'] += 0.5;
		spawn_particle(@l, array(particle: 'NOTE', speed: 4.0, xoffset: @note / 24));
	}
));
