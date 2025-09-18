register_command('spawn', array(
	description: 'Teleports you to the spawn of a world.',
	usage: '/spawn [world]',
	executor: closure(@alias, @sender, @args, @info) {
		include('includes.library/teleports.ms');
		array @teleportLoc;
		boolean @clearEffects = false;
		try {
			@world = if(@args, _world_id(@args[0]), pworld());
			if(!pisop() && (!_world_allows_teleports(@world) || !_world_allows_teleports(pworld()))) {
				die(color('gold').'You cannot teleport directly to or from that world.');
			}
			@spawnLoc = get_spawn(@world);
			@teleportLoc = array(
				x: @spawnLoc['x'] + 0.5,
				y: @spawnLoc['y'] - 1,
				z: @spawnLoc['z'] + 0.5,
				world: @spawnLoc['world'],
				yaw: @spawnLoc['yaw'],
				pitch: 0);
			if(@world === 'custom') {
				@clearEffects = true;
			}
		} catch (InvalidWorldException @ex) {
			// fall back to warp names, if available
			@teleportLoc = get_value('warp.'.to_lower(@args[0]));
			if(!@teleportLoc) {
				die(color('gold').'That world does not exist.');
			}
			if(!_world_allows_teleports(pworld())) {
				die(color('gold').'You cannot teleport in this world.');
			}
			if(@teleportLoc[3] === 'custom') {
				@clearEffects = true;
			}
		}
		_warmuptp(player(), @teleportLoc, @clearEffects);
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
