/*
	Returns a new shifted location from the origin based on relative Minecraft coordinate inputs
*/
proc _relative_coords(@originloc, @x, @y, @z) {
	@loc = @originloc[]
	if(@x[0] == '~') {
		if(@x != '~') {
			@loc['x'] = @originloc['x'] + double(substr(@x, 1));
		}
	} else {
		@loc['x'] = @x;
	}
	if(@y[0] == '~') {
		if(@y != '~') {
			@loc['y'] = @originloc['y'] + double(substr(@y, 1));
		}
	} else {
		@loc['y'] = @y;
	}
	if(@z[0] == '~') {
		if(@z != '~') {
			@loc['z'] = @originloc['z'] + double(substr(@z, 1));
		}
	} else {
		@loc['z'] = @z;
	}
	return(@loc);
}

/*
	Returns the nearest player or null if not within range.
*/
proc _get_nearby_player(@loc, @maxRange) {
	@players = all_players(@loc['world']);
	@player = null;
	foreach(@p in @players) {
		if(pmode(@p) != 'SPECTATOR') {
			@dist = distance(ploc(@p), @loc);
			if(@dist < @maxRange) {
				@player = @p;
				@maxRange = @dist;
			}
		}
	}
	return(@player);
}

/*
	This executes a closure on one or more targets (if any) based on a limited set of vanilla player selector patterns
*/
proc _execute_on(@target, @closure) {
	if(length(@target) < 7 && @target !== '@s' && @target !== '@p') {
		// do not accept most selectors without parameters
		@loc = get_command_block();
		if(@loc) {
			@loc = array_normalize(@loc)[0..3];
			@player = _get_nearby_player(@loc, 16);
			if(@player) {
				tmsg(@player, 'Nearby CommandBlock used unallowed selector: '.@target);
			}
			console(@loc.' has '.@target.' selector.');
		} else {
			msg('Selector is not allowed: '.@target);
		}
		return(0);
	}
	@players = null;
	try {
		@players = select_entities(@target);
	} catch(FormatException @ex) {
		// legacy selectors
		if(@target[0] === '@') {
			@loc = get_command_block();
			if(!@loc) {
				@loc = ploc();
			}

			@maxRange = 128;
			if(length(@target) > 4) {
				@filters = split(',', substr(@target, 3, length(@target) - 1));
				foreach(@filter in @filters) {
					@value = split('=', @filter);
					if(@value[0] === 'r') {
						@maxRange = double(@value[1]);
					} else if(@value[0] === 'distance') {
						@maxRange = double(split('..', @value[1])[1]);
					}
				}
			}

			if(@target[1] === 'p') {
				// single player selector
				@player = _get_nearby_player(@loc, @maxRange);
				if(!@player) {
					return(0);
				}
				@players = array(@player);
			} else if(@target[1] === 'a') {
				// multi player selector
				@players = players_in_radius(@loc, @maxRange);
			}
		} else if(ponline(@target) && !get_command_block()) {
			@players = array(@target);
		}
	}

	if(!@players) {
		return(0);
	}
	foreach(@p in @players) {
		execute(@p, @closure);
	}
	return(array_size(@players));
}
