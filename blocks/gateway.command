register_command('gateway', array(
	description: 'Creates an end gateway at targeted location that goes to first selection position.',
	usage: '/gateway',
	permission: 'worldedit.setnbt',
	tabcompleter: closure(return(array())),
	executor: closure(@alias, @sender, @args, @info) {
		@location = ptarget_space();
		@block = get_block(@location);
		if(@block != 'AIR') {
			die(color('red').'Expected air but got '.@block);
		}
		@pos = sk_pos1();
		if(!@pos) {
			die(color('red').'No selection point detected.');
		}
		set_block(@location, 'END_GATEWAY');
		set_end_gateway_exit(@location, @pos, true);
		set_end_gateway_age(@location, math_const('LONG_MIN'));
	}
));