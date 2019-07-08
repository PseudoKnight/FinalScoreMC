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
	@players = all_players(@loc[3]);
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
	Returns an array of players matching selectors
*/
proc _get_target(@target)  {
	if(@target[0] == '@') {
		if(length(@target) < 2) {
			return(false);
		}
		@loc = get_command_block();
		if(!@loc) {
			return(false);
		}

		@maxRange = 128;
		if(length(@target) > 4) {
			@filters = split(',', substr(@target, 3, length(@target) - 1));
			foreach(@filter in @filters) {
				@value = split('=', @filter);
				if(@value[0] == 'r') {
					@maxRange = double(@value[1]);
				}
			}
		}

		if(@target[1] == 'p') {
			// single player selector
			@player = _get_nearby_player(@loc, @maxRange);
			if(@player) {
				return(array(@player));
			}
			return(false);
		} else if(@target[1] == 'a') {
			// multi player selector
			return(players_in_radius(@loc, @maxRange));
		}
	} else if(ponline(@target) && !get_command_block()) {
		return(array(@target));
	}
	return(false);
}

/*
	This executes a closure on one or more targets (if any) based on a limited set of vanilla player selector patterns
*/
proc _execute_on(@target, @closure) {
	@players = _get_target(@target);
	if(!@players) {
		return(false);
	}
	foreach(@p in @players) {
		execute(@p, @closure);
	}
	return(true);
}
