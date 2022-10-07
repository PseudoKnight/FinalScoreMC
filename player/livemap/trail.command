register_command('trail', array(
	description: 'Sets the color of your trail on the live map using hex (0-f) or rgb (0-255).',
	usage: '/trail <#rrggbb> | /dye <r> <g> <b>',
	executor: closure(@alias, @sender, @args, @info) {
		@pdata = _pdata(player());
		if(!array_index_exists(@pdata, 'support')) {
			msg('You do not have a livemap trail.');
		}
		@hex = @args[0];
		@R = 255;
		@G = 255;
		@B = 255;
		if(array_size(@args) == 3) {
			@R = integer(clamp(@args[0], 0, 255));
			@G = integer(clamp(@args[1], 0, 255));
			@B = integer(clamp(@args[2], 0, 255));
			@hexR = to_radix(@R, 16);
			if(@R < 16) {
				@hexR = '0'.@hexR;
			}
			@hexG = to_radix(@G, 16);
			if(@G < 16) {
				@hexG = '0'.@hexG;
			}
			@hexB = to_radix(@B, 16);
			if(@B < 16) {
				@hexB = '0'.@hexB;
			}
			@hex = '#'.@hexR.@hexG.@hexB;
		} else if(array_size(@args) == 1) {
			if(@args[0][0] == '#' && length(@args[0]) == 7) {
				@R = parse_int(substr(@args[0], 1, 3), 16);
				@G = parse_int(substr(@args[0], 3, 5), 16);
				@B = parse_int(substr(@args[0], 5, 7), 16);
			} else {
				return(false);
			}
		} else {
			return(false);
		}
		@color = array(@R, @G, @B);
		@pdata['trail'] = @color;
		if(array_contains(dm_all_markers('tracers'), player())) {
			dm_delete_marker('tracers', player());
		}
		runas('~console', '/tellraw '.player()
				.' [{"text":"Trail color set to "},'
				.'{"text":"['.array_implode(@args).']","color":"'.@hex.'"},'
				.'{"text":"⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯","color":"'.@hex.'","strikethrough":true}]');
	}
));
