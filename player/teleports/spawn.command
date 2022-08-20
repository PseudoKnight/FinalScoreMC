register_command('spawn', array(
	description: 'Teleports you to a world\'s spawn.',
	usage: '/spawn [world]',
	executor: closure(@alias, @sender, @args, @info) {
		include('includes.library/teleports.ms');
		try {
			@world = if(@args, _worldid(@args[0]), pworld());
			if(!pisop() && (!_allows_teleports(@world) || !_allows_teleports(pworld()))) {
				die(color('gold').'You cannot teleport directly to or from that world.');
			}
			@loc = get_spawn(@world);
			@loc = array(@loc[0] + 0.5, @loc[1] - 1, @loc[2] + 0.5, @loc[3]);
		} catch (InvalidWorldException @ex) {
			@loc = get_value('warp.'.to_lower(@args[0]));
			if(!@loc) {
				die(color('gold').'That world does not exist.');
			}
			if(!_allows_teleports(pworld())) {
				die(color('gold').'You cannot teleport in this world.');
			}
		}
		_warmuptp(player(), @loc, @loc[3] == 'custom');
	},
	tabcompleter: closure(@alias, @sender, @args, @info) {
		@worlds = array();
		@attempt = @args[-1];
		foreach(@world in _worlds_config()) {
			if(is_array(@world)) {
				@name = replace(@world['name'], ' ', '');
				if(length(@attempt) <= length(@name) && equals_ic(@attempt, substr(@name, 0, length(@attempt)))) {
					@worlds[] = @name;
				}
			}
		}
		return(@worlds);
	}
));
