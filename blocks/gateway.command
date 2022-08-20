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
		@x = integer(@location['x']);
		@y = integer(@location['y']);
		@z = integer(@location['z']);
		@pos = sk_pos1();
		if(!@pos) {
			die(color('red').'No selection point detected.');
		}
		@px = @pos['x'];
		@py = @pos['y'];
		@pz = @pos['z'];
		sudo("/setblock @x @y @z end_gateway{\"ExitPortal\":{\"X\":@px,\"Y\":@py,\"Z\":@pz},\"ExactTeleport\":1,\"Age\":-9223372036854775808L}");
	}
));