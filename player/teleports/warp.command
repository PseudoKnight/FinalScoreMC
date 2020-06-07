register_command('warp', array(
	'description': 'Teleports you to a predefined location.',
	'usage': '/warp [player] <warp_name>',
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		return(array());
	},
	'executor': closure(@alias, @sender, @args, @info) {
		if(!@args) {
			run('/warps list');
			die();
		}

		@target = null;
		@warpid = null;
		if(array_size(@args) == 2) {
			if(!get_command_block()) {
				die(color('gold').'You cannot teleport others.');
			}
			@target = @args[0];
			@warpid = @args[1];
		} else {
			@target = player();
			@warpid = @args[0];
		}
		
		@closure = closure(@uuid) {
			@warp = get_value('warp.'.to_lower(@warpid));
			if(!@warp) {
				die(color('gold').'That warp does not exist.');
			}
			
			include('includes.library/teleports.ms');
			if(!_allows_teleports(pworld(@uuid))) {
				die(color('gold').'You cannot warp in this world.');
			}
			
			_warmuptp(player(@uuid), @warp, @warp[3] == 'custom');
		}

		if(array_size(@args) == 2) {
			_execute_on(@target, @closure);
		} else {
			execute(@target, @closure);
		}
	}
));
