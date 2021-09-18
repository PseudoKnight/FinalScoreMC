register_command('sign', array(
	description: 'Sets the text on existing signs.',
	usage: '/sign [line#] <text>',
	permission: 'command.sign',
	tabcompleter: closure(return(array())),
	executor: closure(@alias, @sender, @args, @info) {
		@sign = ray_trace(8)['block'];
		if(@sign == null) {
			die(color('gold').'No sign in range.');
		}
		if(!sk_can_build(@sign)) {
			die(color('gold').'You cannot build here.');
		}
		if(!is_sign_at(@sign)) {
			die(color('gold').'That is not a sign');
		}
		@lines = get_sign_text(@sign);
		if(is_integral(@args[0]) && integer(@args[0]) > 0 && integer(@args[0]) < 5) {
			@lines[@args[0] - 1] = colorize(array_implode(@args[1..-1]));
		} else {
			@lines = split('\\', colorize(array_implode(@args)));
		}
		set_sign_text(@sign, @lines);
	}
));
