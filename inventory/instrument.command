// Hand instruments
register_command('instrument', array(
	description: 'Play an instrument with the held item',
	usage: '/instrument <instrument> <mode>',
	tabcompleter: _create_tabcompleter(
		array('banjo', 'bass', 'bell', 'bit', 'chime', 'cow_bell', 'didgeridoo', 'flute',
				'guitar', 'harp', 'iron_xylophone', 'pling', 'trumpet', 'trumpet_exposed',
				'trumpet_weathered', 'trumpet_oxidized', 'xylophone', 'none', '<sound.key|seed>'),
		array('chromatic', 'pentatonic_major', 'pentatonic_minor', 'harmonic_minor', 'blues',
				'ionian', 'aoelian', 'dorian', 'phrygian_dominant', 'lydian', '<comma separated integer notation>'),
	),
	executor: closure(@alias, @player, @args, @info) {
		@item = pinv(player(), null);
		if(!@item) {
			die('Must be holding an item.');
		}
		@itemName = @item['name'];

		unbind(@player.'.instrument.'.@itemName);
		unbind(@player.'.basedrum.'.@itemName);

		@instrument = array_get(@args, 0, 'none');
		@seed = 0;
		if(@instrument === 'none') {
			die('Unbound this instrument');
		}
		if(string_position(@instrument, '.') < 0) {
			@instrument = 'block.note_block.'.@instrument;
		} else if(string_position(@instrument, '|') >= 0) {
			@split = split('|', @instrument);
			@instrument = @split[0];
			@seed = integer(@split[1]);
		}

		@mode = array_get(@args, 1, 'chromatic');
		@notes = array(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11);
		if(string_position(@mode, ',') > -1) {
			@notes = split(',', @mode);
			foreach(@note in @notes) {
				if(!is_integral(@note)) {
					die(@note.' is not an integer.');
				}
			}
		} else if(@mode === 'pentatonic_major') {
			@notes = array(0, 2, 4, 7, 9);
		} else if(@mode === 'pentatonic_minor') {
			@notes = array(0, 3, 5, 7, 10);
		} else if(@mode === 'harmonic_minor') {
			@notes = array(0, 2, 3, 5, 7, 8, 11);
		} else if(@mode === 'blues') {
			@notes = array(0, 3, 5, 6, 7, 10);
		} else if(@mode === 'ionian') {
			@notes = array(0, 2, 4, 5, 7, 9, 11);
		} else if(@mode === 'aoelian') {
			@notes = array(0, 2, 3, 5, 7, 8, 10);
		} else if(@mode === 'dorian') {
			@notes = array(0, 2, 3, 5, 7, 9, 10);
		} else if(@mode === 'phrygian_dominant') {
			@notes = array(0, 1, 4, 5, 7, 8, 10);
		} else if(@mode === 'lydian') {
			@notes = array(0, 2, 4, 6, 7, 9, 11);
		} else {
			die('Unknown scale. Consider using an integer notation. e.g. 0,2,4,7,9');
		}

		msg('Bound an instrument to this item type for you. Use "/instrument none" to unbind.');

		bind('player_interact', array(id: @player.'.instrument.'.@itemName), array(player: @player, itemname: @itemName), @event, @instrument, @seed, @notes) {
			@loc = location_shift(ploc(), 'up', 3);
			if(@event['button'] === 'left') {
				if(@event['block']) {
					play_named_sound(@loc, array(sound: 'block.note_block.snare', category: 'VOICE'));
				} else {
					play_named_sound(@loc, array(sound: 'block.note_block.hat', category: 'VOICE'));
				}
			} else {
				@note = round((-@loc['pitch'] + 90) / (180 / 24));
				if(@event['hand'] === 'off_hand') {
					@note += if(@note < 21, 4, -5);
				}
				@modNote = integer(@note) % 12;
				while(!array_contains(@notes, @modNote) && @modNote > 0) {
					@modNote--;
					@note--;
				}
				@pitch = 2 ** ((@note - 12) / 12);
				play_named_sound(@loc, array(sound: @instrument, pitch: @pitch, category: 'VOICE', volume: 1, seed: @seed));
				@loc['x'] += rand() * 1.4 - 0.7;
				@loc['z'] += rand() * 1.4 - 0.7;
				spawn_particle(@loc, array(particle: 'NOTE', speed: 4.0, xoffset: abs(@loc['pitch'] - 90) / 180));
			}
		}

		bind('player_toggle_sneak', array(id: @player.'.basedrum.'.@itemName), array(player: @player, sneaking: true), @event, @itemName) {
			@mainhand = pinv(player(), null);
			@offhand = pinv(player(), -106);
			if(@mainhand && @mainhand['name'] === @itemName) {
				play_named_sound(ploc(), array(sound: 'block.note_block.basedrum', category: 'VOICE'));
			} else if(@offhand && @offhand['name'] === @itemName) {
				play_named_sound(ploc(), array(sound: 'block.note_block.basedrum', category: 'VOICE'));
			}
		}
	}
));