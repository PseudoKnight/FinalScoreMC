@warps = array();
foreach(@w in array_keys(get_values('warp'))) {
	@warps[] = split('.', @w)[1];
}
foreach(@w in _worlds_config()) {
	if(is_array(@w) && @w['teleports']) {
		@warps[] = replace(to_lower(@w['name']), ' ', '');
	}
}
register_command('warp', array(
	description: 'Teleports you to a predefined location.',
	usage: '/warp [player] <warp_name>',
	'tabcompleter': _create_tabcompleter(@warps),
	executor: closure(@alias, @sender, @args, @info) {
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
		
		include('includes.library/teleports.ms');
		@closure = closure(@uuid) {
			@warp = get_value('warp.'.to_lower(@warpid));
			if(!@warp) {
				try {
					// try a world name
					@world = _world_id(@warpid);
					if(!pisop(@uuid) && !_world_allows_teleports(@world)) {
						die(color('gold').'You cannot teleport directly to that world.');
					}
					@warp = get_spawn(@world);
					@warp = array(@warp[0] + 0.5, @warp[1] - 1, @warp[2] + 0.5, @warp[3]);
				} catch (InvalidWorldException @ex) {
					die(color('gold').'That warp does not exist.');
				}
			}

			if(!_world_allows_teleports(pworld(@uuid))) {
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
