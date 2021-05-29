register_command('track', array(
	'description': 'Commands for creating and editing tracks for races.',
	'usage': '/track <set|delete> <track> [setting] [value(s)]',
	'permission': 'command.track',
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		return(array());
	},
	'executor': closure(@alias, @sender, @args, @info) {
		if(array_size(@args) < 2) {
			return(false);
		}
		@action = @args[0];
		@id = @args[1];
		@setting = array_get(@args, 2, null);
		@value = array_get(@args, 3, null);
		@values = null;
		if(array_size(@args) > 4) {
			@values = @args[4..];
		}

		@track = get_value('track', @id);
		if(!@track) {
			@track = associative_array();
			msg(color('green').'Creating '.@id.'...');
		}
		switch(@action) {
			case 'set':
				switch(@setting) {
					// string
					case 'region':
						@track[@setting] = @value;
						msg(colorize("&7[Track]&r Set &e@setting&r to &a@value"));

					// integer
					case 'laps':
						if(!is_integral(@value)) {
							die(color('gold').'Expecting an integer for '.@setting);
						}
						@track[@setting] = integer(@value);
						msg(colorize("&7[Track]&r Set &e@setting&r to &a@value"));

					// single number
					case 'health':
						if(!is_numeric(@value)) {
							die(color('gold').'Expecting a number for '.@setting);
						}
						@num = @values[0];
						@track[@setting] = double(@value);
						msg(colorize("&7[Track]&r Set &e@setting&r to &a@value"));

					// two numbers
					case 'sky':
						if(!is_numeric(@value) || !@values || !is_numeric(@values[0])) {
							die(color('gold').'Expecting two numbers for '.@setting);
						}
						@num = @values[0];
						@track[@setting] = array(double(@value), double(@num));
						msg(colorize("&7[Track]&r Set &e@setting&r to &a@value&r and &a@num"));

					// single location
					case 'lobby':
						@loc = entity_loc(puuid());
						@track[@setting] = @loc;
						msg(colorize("&7[Track]&r Set &e@setting&r to this location"));

					// multiple locations
					case 'spawn':
						if(!array_index_exists(@track, @setting)) {
							@track[@setting] = array();
						}
						@loc = array_normalize(entity_loc(puuid()))[0..5];
						@track[@setting][] = @loc;
						msg(colorize("&7[Track]&r Set &e@setting&r to this location"));

					// selection with optional integer
					case 'checkpoint':
						@pos1 = sk_pos1();
						@pos2 = sk_pos2();
						if(!@pos1 || !@pos2) {
							die(color('gold').'Expected a WorldEdit selection.');
						}
						@cuboid = array(
							array(
								integer(max(@pos1['x'], @pos2['x'])) + 1,
								integer(max(@pos1['y'], @pos2['y'])) + 1,
								integer(max(@pos1['z'], @pos2['z'])) + 1,
							),
							array(
								integer(min(@pos1['x'], @pos2['x'])),
								integer(min(@pos1['y'], @pos2['y'])),
								integer(min(@pos1['z'], @pos2['z'])),
							),
						);
						if(!array_index_exists(@track, @setting)) {
							@track[@setting] = array();
						}
						@num = array_size(@track[@setting]);
						if(!is_null(@value) && is_integral(@value)) {
							@num = integer(@value);
						}
						@track[@setting][@num] = @cuboid;
						msg(colorize("&7[Track]&r Set &e@setting &a@num&r to the current selection."));

					// string from set
					case 'type':
						@tracktypes = array('boat', 'elytra', 'horse', 'parkour', 'pig');
						if(!array_contains(@tracktypes, @value)) {
							die(color('gold').'Expecting one of '.array_implode(@tracktypes));
						}
						@track[@setting] = @value;
						msg(colorize("&7[Track]&r Set &e@setting&r to &a@value"));

					// effect name, strength integer, seconds integer
					case 'effect':
						if(!array_index_exists(reflect_pull('enum', 'PotionEffectType'), @value)) {
							die(color('gold').'Expecting one of '.array_implode(reflect_pull('enum', 'PotionEffectType')));
						}
						if(array_size(@values) < 2) {
							die(color('gold').'Expecting a strength and time in seconds after the effect name.');
						}
						@potionid = to_upper(@value);
						@strength = @values[0];
						@seconds = @values[1];
						if(!array_index_exists(@track, @setting)) {
							@track[@setting] = associative_array();
						}
						@track[@setting][@potionid] = array(@strength, @seconds);
						msg(colorize("&7[Track]&r Set &a@value&r &e@setting&r with a strength of &a@strength&r and a length of &a@seconds&r seconds."));
				}
				store_value('track', @id, @track);

			case 'info':
				foreach(@setting: @value in @track) {
					msg(color('yellow').@setting.color('r').': '.@value);
				}

			case 'delete':
			case 'remove':
				if(@setting) {
					if(@value) {
						if(is_array(@track[@setting])) {
							array_remove(@track[@setting], @value);
							msg(colorize("&7[Track]&r Deleted &e@value&r in &e@setting&r array from &a@id&r track"));
						} else {
							die(color('gold').@setting.' is not an array.');
						}
					} else {
						array_remove(@track, @setting);
						msg(colorize("&7[Track]&r Deleted &e@setting&r from &a@id&r track"));
					}
					store_value('track', @id, @track);
				} else {
					clear_value('track', @id);
					msg(colorize("&7[Track]&r Deleted track &a@id"));
				}

			default:
				return(false);
		}
	}
));
