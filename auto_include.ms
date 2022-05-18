/*
	Gets a value from any number of nested arrays using multiple keys.
	Returns null if expected arrays or keys don't exist.
	Example: @value = _nested_array_get(@nestedArrays, 'key_for_parent_array', 'key_for_nested_array');
*/
proc _nested_array_get(@value) {
	@size = array_size(@arguments);
	for(@i = 1, @i < @size, @i++) {
		if(is_array(@value)) {
			@key = @arguments[@i];
			if(array_index_exists(@value, @key)) {
				@value = @value[@key];
			} else {
				return(null);
			}
		} else {
			return(null);
		}
	}
	return(@value);
}

/*
	Adds an activity to the activities list.
	This is used for checking which games are running.
*/
proc _add_activity(@id, @title, @region, @world) {
	@activities = import('activities');
	if(is_null(@activities)) {
		@activities = associative_array();
		export('activities', @activities);
	}
	@activities[@id] = array('title': @title, 'region': @region, 'world': @world);
	if(@region && @world) {
		if(function_exists('discord_broadcast')) {
			discord_broadcast('minecraft_chat', array(embed: array(title: @title.' started...')));
		}
		if(extension_exists('CHDynmap')) {
			try {
				@regionCoords = sk_region_info(@region, @world, 0);
				@minX = @regionCoords[1][0];
				@minZ = @regionCoords[1][2];
				@maxX = @regionCoords[0][0];
				@maxZ = @regionCoords[0][2];
				dm_create_marker('markers', array(
					type: 'AREA',
					world: @world,
					label: @title,
					id: @id,
					corners: array(
						array(@minX, 0, @minZ, @world),
						array(@maxX, 0, @minZ, @world),
						array(@maxX, 0, @maxZ, @world),
						array(@minX, 0, @maxZ, @world),
					),
				));
				dm_set_marker_line_style('markers', @id, array(
					color: array(r: 255, g: 0, b: 0),
					opacity: 1,
					weight: 1,
				));
				dm_set_marker_fill_style('markers', @id, array(
					color: array(r: 255, g: 0, b: 0),
					opacity: 0.1,
				));
			} catch (Exception @ex) {
				console('Failed to create region marker for activity: '.@title);
			}
		}
	}
}

/*
	Removes an activity from the activities list.
*/
proc _remove_activity(@id) {
	@activities = import('activities');
	if(!is_null(@activities) && array_index_exists(@activities, @id)) {
		@activity = array_remove(@activities, @id);
		if(@activity['region']) {
			if(extension_exists('CHDynmap')) {
				try(dm_delete_marker('markers', @id))
			}
		}
		return(true);
	}
	return(false);
}

proc _get_activities_string() {
	@activities = import('activities');
	if(!@activities) {
		return('');
	}
	@string = '';
	foreach(@id: @activity in @activities) {
		@string .= if(@string, ', ').@activity['title'];
	}
	return(@string);
}

/*
	Returns a tabcompleter closure that supports an ordered list of static or dynamic returns.
	Example:
		set_tabcompleter('player', _create_tabcompleter(
			array('player.management': array('set', 'get'), ), // requires permission to see
			null, // no completion
			array('health', 'hunger'), // simple list of options
			array('<health|hunger': array('min', 'max', 'none'), // requires previous to be health or hunger
			closure(@alias, @sender, @args){ ... }, // custom tabcompleter for this argument
		));
 */
proc _create_tabcompleter() {
	@argumentCompletions = @arguments;
	return(closure(@alias, @sender, @args) {
		if(array_size(@args) > array_size(@argumentCompletions)) {
			return(array());
		}
		@completions = @argumentCompletions[array_size(@args) - 1];
		if(is_array(@completions)) {
			@arg = to_lower(@args[-1]);
			if(is_associative(@completions)) {
				@result = array();
				foreach(@perm: @array in @completions) {
					if(!@perm) {
						@result = @array;
					} else if(@perm[0] == '<') {
						@count = 1;
						while(@perm[@count] == '<') {
							@count++;
						}
						@previous = @args[array_size(@args) - 1 - @count];
						@split = split('|', substr(@perm, @count));
						foreach(@s in @split) {
							if(@previous == @s) {
								@result = @array;
								break();
							}
						}
					} else if(has_permission(@perm)) {
						@result = @array;
						break();
					}
				}
				return(array_filter(@result, closure(@key, @value) {
					return(string_starts_with(@value, @arg));
				}));
			} else {
				return(array_filter(@completions, closure(@key, @value) {
					return(string_starts_with(@value, @arg));
				}));
			}
		} else if(is_closure(@completions)) {
			return(execute(@completions));
		}
		return(array());
	});
}
