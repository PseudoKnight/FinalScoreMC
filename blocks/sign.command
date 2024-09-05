register_command('sign', array(
	description: 'Sets the text on existing signs.',
	usage: '/sign [side] [line#] <text>',
	permission: 'command.sign',
	tabcompleter: closure(return(array())),
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
		@lines = get_sign_text(@sign, @side);
		if(is_integral(@args[@numIndex]) && integer(@args[@numIndex]) > 0 && integer(@args[@numIndex]) < 5) {
			@lines[@args[@numIndex] - 1] = colorize(array_implode(@args[cslice(@numIndex + 1, -1)]));
		} else {
			@lines = split('\\', colorize(array_implode(@args[cslice(@numIndex, -1)])));
		}
		set_sign_text(@sign, @side, @lines);
	}
));
