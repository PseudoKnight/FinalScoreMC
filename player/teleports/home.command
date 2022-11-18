register_command('home', array(
	description: 'Teleports you to the specified home location.',
	usage: '/home [world] [player]',
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
	},
	executor: closure(@alias, @sender, @args, @info) {
		include('includes.library/teleports.ms');
		if(!_world_allows_teleports(pworld())) {
			die('You cannot teleport in this world.');
		}
		@world = pworld();
		@player = player();
		if(@args) {
			try {
				@world = _world_id(@args[0]);
				if(array_size(@args) == 2) {
					@player = @args[1];
				}
			} catch(InvalidWorldException @ex) {
				@player = @args[0];
				if(array_size(@args) == 2) {
					@world = _world_id(@args[1]);
				}
			}
		}
		@pdata = null;
		try {
			@pdata = _pdata(@player);
		} catch(NotFoundException @ex) {
			die(color('gold') . '"' . @player . '" is not a known world or player name.');
		}
		if(!array_index_exists(@pdata, 'homes') || !array_index_exists(@pdata['homes'], @world)) {
			if(@player == player()) {
				die(color('yellow') . 'You can set a home for a world with /sethome');
			} else {
				die(color('gold') . "@player has not set a home for @world");
			}
		}
		@loc = @pdata['homes'][@world];
		if(_is_survival_world(@world) && !_is_safe_location(@loc)) {
			if(@world == 'world_the_end') {
				die(color('red') . 'That teleport location does not appear to be safe!');
			} else {
				@overrides = import('tp.overrides');
				if(!@overrides) {
					@overrides = associative_array();
				}
				@overrides[player()] = @loc;
				export('tp.overrides', @overrides);
				die(color('yellow') . 'That teleport location does not appear to be safe! /override');
			}
		}
		_warmuptp(player(), @loc);
	}
));
