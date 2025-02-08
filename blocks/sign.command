register_command('sign', array(
	description: 'Sets the text on existing signs.',
	usage: '/sign [side] [line#] <text>\n/sign [side] glow>\n/sign <woodtype>\n/sign wax',
	permission: 'command.sign',
	tabcompleter: _create_tabcompleter(
		array('front', 'back', 'glow', 'wax', 'acacia', 'bamboo', 'birch', 'cherry', 'crimson', 'dark_oak', 'jungle', 'mangrove', 'oak', 'spruce', 'warped', 'pale_oak', '1', '2', '3', '4'),
		array('<front|back': array('glow', '1', '2', '3', '4')),
	),
	executor: closure(@alias, @sender, @args, @info) {
		if(!@args) {
			return(false);
		}
		@sign = pcursor();
		if(!sk_can_build(@sign)) {
			die(color('gold').'You cannot build here.');
		}
		if(!is_sign_at(@sign)) {
			die(color('gold').'That is not a sign');
		}
		@signData = get_blockdata(@sign);
		if(array_size(@args) == 1) {
			// toggle waxed state
			if(equals_ic(@args[0], 'wax')) {
				set_sign_waxed(@sign, !is_sign_waxed(@sign));
				return(true);
			}

			// change sign material
			 if(array_contains_ic(array('acacia', 'bamboo', 'birch', 'cherry', 'crimson', 'dark_oak', 'jungle', 'mangrove', 'oak', 'spruce', 'warped', 'pale_oak'), @args[0])) {
				@linesFront = get_sign_text(@sign, 'FRONT');
				@linesBack = get_sign_text(@sign, 'BACK');
				@glowingFront = is_sign_text_glowing(@sign, 'FRONT');
				@glowingBack = is_sign_text_glowing(@sign, 'BACK');
				if(string_starts_with(@signData['block'], 'dark_oak') || string_starts_with(@signData['block'], 'pale_oak')) {
					@signData['block'] = to_lower(@args[0]).'_'.split('_', @signData['block'], 2)[2];
				} else {
					@signData['block'] = to_lower(@args[0]).'_'.split('_', @signData['block'], 1)[1];
				}
				set_blockdata(@sign, @signData);
				set_sign_text(@sign, 'FRONT', @linesFront);
				set_sign_text(@sign, 'BACK', @linesBack);
				set_sign_text_glowing(@sign, 'FRONT', @glowingFront);
				set_sign_text_glowing(@sign, 'BACK', @glowingBack);
				return(true);
			}
		}

		@side = 'FRONT';
		@numIndex = 0;
		if(equals_ic(@args[0], 'FRONT') || equals_ic(@args[0], 'BACK')) {
			@numIndex = 1;
			@side = to_upper(@args[0]);
		} else {
			@loc = ploc();
			if(array_index_exists(@signData, 'rotation')) {
				@dYaw = @loc['yaw'] - @signData['rotation'] * 22.5;
				if(@dYaw > 180) {
					@dYaw -= 360;
				} else if(@dYaw < -180) {
					@dYaw += 360;
				}
				if(abs(@dYaw) < 90) {
					@side = 'BACK';
				}
			} else if(@signData['facing'] == 'east') {
				if(@loc['x'] < @sign['x'] + 0.25) {
					@side = 'BACK';
				}
			} else if(@signData['facing'] == 'west') {
				if(@loc['x'] > @sign['x'] + 0.75) {
					@side = 'BACK';
				}
			} else if(@signData['facing'] == 'south') {
				if(@loc['z'] < @sign['z'] + 0.25) {
					@side = 'BACK';
				}
			} else {
				if(@loc['z'] > @sign['z'] + 0.75) {
					@side = 'BACK';
				}
			}
		}

		// toggle glow state
		if(equals_ic(@args[@numIndex], 'glow')) {
			set_sign_text_glowing(@sign, @side, !is_sign_text_glowing(@sign, @side));
			return(true);
		}

		@lines = get_sign_text(@sign, @side);
		if(is_integral(@args[@numIndex]) && integer(@args[@numIndex]) > 0 && integer(@args[@numIndex]) < 5) {
			@lines[@args[@numIndex] - 1] = colorize(array_implode(@args[cslice(@numIndex + 1, -1)]));
		} else {
			@lines = split('\\', colorize(array_implode(@args[cslice(@numIndex, -1)])));
		}
		set_sign_text(@sign, @side, @lines);
	}
));
