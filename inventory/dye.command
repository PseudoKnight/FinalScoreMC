register_command('dye', array(
	description: 'Dyes leather armor, maps, and potions using hex or rgb (0-255).',
	usage: '/dye <#rrggbb> | /dye <r> <g> <b>',
	permission: 'command.items',
	tabcompleter: closure(@alias, @sender, @args, @info) {
		return(array());
	},
	'executor': closure(@alias, @sender, @args, @info) {
		if(!@args) {
			return(false);
		}
		@item = pinv(player(), null);
		if(!@item) {
			die(color('gold').'You must be holding a map, potion or leather armor in your hand.');
		}
		@r = 255;
		@g = 255;
		@b = 255;
		if(array_size(@args) == 3) {
			@r = integer(clamp(@args[0], 0, 255));
			@g = integer(clamp(@args[1], 0, 255));
			@b = integer(clamp(@args[2], 0, 255));
		} else if(array_size(@args) == 1) {
			if(@args[0][0] == '#' && length(@args[0]) == 7) {
				@r = parse_int(substr(@args[0], 1, 3), 16);
				@g = parse_int(substr(@args[0], 3, 5), 16);
				@b = parse_int(substr(@args[0], 5, 7), 16);
			} else {
				return(false);
			}
		} else {
			return(false);
		}
		@color = array(@r, @g, @b);
		if(string_starts_with(@item['name'], 'LEATHER_')) {
			try {
				set_armor_color(pheld_slot(), @color);
			} catch(Exception @ex) {
				die(color('gold').'This leather item cannot be dyed.');
			}
		} else if(@item['name'] == 'FILLED_MAP' || string_ends_with(@item['name'], 'POTION')) {
			if(!@item['meta']) {
				@item['meta'] = associative_array();
			}
			@item['meta']['color'] = @color;
			set_pinv(player(), null, @item);
		} else {
			die(color('gold').'You must be holding a map, potion, or leather armor in your hand.');
		}
	}
));
