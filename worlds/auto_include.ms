/**
 * Returns the worlds config
 */
proc _worlds_config() {
	@worlds = import('worlds');
	if(is_null(@worlds)) {
		@worlds = yml_decode(read('config.yml'));
		export('worlds', @worlds);
	}
	return(@worlds);
}

// /**
//  * Returns the absolute directory of the worlds container.
//  */
// proc _worlds_dir() {
// 	@userDir = sys_properties()['user.dir'];
// 	@worldContainer = get_server_info(6);
// 	if(@worldContainer == '.') {
// 		return(@userDir);
// 	}
// 	return(@userDir.'/'.@worldContainer);
// }

/**
 * Returns world group
 */
proc _world_group(@world) {
	@worlds = _worlds_config();
	if(array_index_exists(@worlds, @world)) {
		return(@worlds[@world]['group']);
	}
	return(null);
}

/**
 * Returns world alias when given world folder name
 */
proc _world_name(@world) {
	@worlds = _worlds_config();
	@world = to_lower(@world);
	try {
		return(@worlds[@world]['name']);
	} catch(IndexOverflowException @ex) {
		# default to lower case name
		return(@world);
	}
}

/**
 * Returns a world folder name when given a world alias
 */
proc _world_id(@world) {
	@worlds = _worlds_config();
	@world_name = to_lower(@world);
	@world_id = '';
	if(array_index_exists(@worlds, @world)) {
		@world_id = @worlds[@world_name];
	} else {
		@world_name  = reg_replace('[_-]', '', @world_name);
		if(array_index_exists(@worlds, @world_name)) {
			@world_id = @worlds[@world_name];
		} else {
			throw(InvalidWorldException, 'A world by the name "'.@world.'" does not exist.');
		}
	}
	@world_id = @worlds[@world_name];
	if(is_array(@world_id)) {
		return(@world_name);
	} else {
		return(@world_id);
	}
}

/**
 * Returns if the world is a survival world
 */
proc _is_survival_world(@world) {
	return(has_metadata(@world, 'survival'));
}

/**
 * Returns if the world allows teleports
 */
proc _world_allows_teleports(@world) {
	@worlds = _worlds_config();
	try {
		return(@worlds[@world]['teleports']);
	} catch(IndexOverflowException @ex) {
		# default to true
		return(true);
	}
}

/**
 * Creates and adds a world to config transiently.
 * Throws InvalidWorldException if the world already exists by that name or display name.
 * 
 * @world keys:
 * name: The display title for the world.
 * mode: The default gamemode for players entering the world.
 * group: The world group name. Used for separating inventories, among other things.
 * teleports: Whether or not a player can use teleport commands to enter/exit this world. (default: true)
 * seed: The world seed used to generate terrain. Random if not provided.
 * environment: The world dimension. (NORMAL, NETHER, THE_END)
 * generator: The name of a custom world generator.
 * difficulty: The difficulty mode. (default: HARD)
 * spawning: An associative array of spawning behavior defined in bukkit.yml. (eg. ticks-per-monster-spawns)
 */
proc _create_world(@name, @world) {
	@title = @world['name'];
	@worlds = _worlds_config();
	if(array_contains(@worlds, @name) || array_contains(@worlds, @title)) {
		throw(InvalidWorldException, "World already exists.");
	}
	@worlds[@name] = @world;
	@worlds[@title] = @name; // alias display name
	if(array_index_exists(@world, 'seed')) {
		if(array_index_exists(@world, 'generator')) {
			create_world(@name, 'NORMAL', @world['environment'], @world['seed'], @world['generator']);
		} else {
			create_world(@name, 'NORMAL', @world['environment'], @world['seed']);
		}
	} else {
		create_world(@name, 'NORMAL', @world['environment']);
	}
	// Flags a world in the survival world group
	if(@world['group'] == 'survival') {
		set_metadata(@name, 'survival', true);
	}
	// Since difficulty is not currently loaded from level.dat
	@difficulty = 'HARD';
	if(array_index_exists(@world, 'difficulty')) {
		@difficulty = @world['difficulty'];
	}
	set_difficulty(@name, @difficulty);
	if(array_index_exists(@world, 'spawning')) {
		if(extension_exists('CHPaper')) {
			set_spawning(@name, @world['spawning']);
		}
	}
}

/**
 * Unloads world from server and worlds config.
 * Teleports existing players to another world in the same world group.
 * Throws InvalidWorldException if something goes wrong.
 */
proc _unload_world(@name, @save = true) {
	@worlds = _worlds_config();
	if(!array_index_exists(@worlds, @name)) {
		throw(InvalidWorldException, "World does not exist in config and may not be loaded.");
	}

	// get the world array for this name
	@world = @worlds[@name];
	if(is_string(@world)) {
		@name = @world;
		@world = @worlds[@name];
	}

	if(!array_contains(get_worlds(), @name)) {
		throw(InvalidWorldException, "World is not loaded.");
	}

	// find the another world in the same group to put players
	@alternateWorld = '';
	foreach(@n: @w in @worlds) {
		if(is_array(@w) && @w['group'] == @world['group'] && @w['name'] != @world['name']) {
			@alternateWorld = @n;
			break();
		}
	}

	// Teleport all existing players in world to another world
	@players = all_players(@name);
	if(@players) {
		if(!@alternateWorld) {
			throw(InvalidWorldException, "No other world in world group.");
		}
		@loc = get_spawn(@alternateWorld);
		@loc['y']--;
		foreach(@player in @players) {
			set_ploc(@player, @loc);
		}
	}

	if(!unload_world(@name, @save)) {
		throw(InvalidWorldException, "World could not be unloaded.");
	}

	// remove entries from world config
	array_remove(@worlds, @name);
	foreach(@n: @w in @worlds) {
		if(is_string(@w) && equals_ic(@w, @name)) {
			array_remove(@worlds, @n);
		}
	}
}

/**
 * Gets the custom border for the given world.
 * These are used where visual borders are distracting
 * or when borders are not perfectly square.
 */
proc _get_worldborder(@world) {
	@worlds = _worlds_config();
	if(array_index_exists(@worlds, @world, 'border')) {
		return(@worlds[@world]['border']);
	}
	return(null);
}

/**
 * Gets the extent of the world on the x and z axes.
 * Optionally specify a buffer in meters.
 * Returns an array with the indexes xMin, xMax, zMin, and zMax.
 */
proc _get_world_extent(@world, @buffer = 0) {
	@worldBorder = get_world_border(@world);

	@center = @worldBorder['center'];
	@width = integer(@worldBorder['width']);
	if(@buffer >= @width / 2) {
		throw('RangeException', 'Buffer is larger than world radius');
	}

	@xMin = integer(@center['x'] - @width / 2);
	@zMin = integer(@center['z'] - @width / 2);
	@xMax = integer(@center['x'] + @width / 2);
	@zMax = integer(@center['z'] + @width / 2);

	// Make sure it is within our custom world border too
	@border = _get_worldborder(@world);
	if(@border) {
		@xCenter = @border['x'];
		@zCenter = @border['z'];
		@xRadius = @border['radiusX'];
		@zRadius = @border['radiusZ'];

		// limit to within both world borders
		@xMin = max(@xMin, @xCenter - @xRadius);
		@xMax = min(@xMax, @xCenter + @xRadius);
		@zMin = max(@zMin, @zCenter - @zRadius);
		@zMax = min(@zMax, @zCenter + @zRadius);
	}

	@xMin += @buffer;
	@zMin += @buffer;
	@xMax -= @buffer;
	@zMax -= @buffer;
	return(array(xMin: @xMin, xMax: @xMax, zMin: @zMin, zMax: @zMax));
}

/**
 * Interpolates between current world time and target time over a number of ticks.
 * Returns whether or not this will be successful in modifying time.
 */
proc _world_time_travel(@world, @targetTime, @ticks) {
	if(import('timetravel.'.@world)) {
		return(false);
	}
	export('timetravel.'.@world, true);

	@startTime = get_world_time(@world);
	if(@targetTime <= @startTime) {
		@targetTime += 24000;
	}
	@timeDelta = @targetTime - @startTime;

	@daylightCycle = get_gamerule(@world, 'DODAYLIGHTCYCLE');
	set_gamerule(@world, 'DODAYLIGHTCYCLE', false);

	@step = array(0);
	set_interval(50, closure(){
		@step[0]++;
		@interp = -(cos(math_const('PI') * @step[0] / @ticks) - 1) / 2;
		set_world_time(@world, @startTime + integer(round(@timeDelta * @interp)));
		if(@step[0] == @ticks) {
			set_gamerule(@world, 'DODAYLIGHTCYCLE', @daylightCycle);
			export('timetravel.'.@world, null);
			clear_task();
		}
	});
	return(true);
}
