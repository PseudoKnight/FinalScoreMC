/*
	Format all exception messages according to the sender and receiver.
	Only displays technical details to console/log, not to player.
*/
set_uncaught_exception_handler(closure(@ex){
	if(@loc = get_command_block()) {
		console('Exception occurred in CommandBlock at '.array_normalize(@loc)[0..3], false);
	} else if(ponline(player())) {
		msg(color('red').@ex['message']);
	}
	console(@ex['classType'].': '.@ex['message'], false);
	foreach(@trace in @ex['stackTrace']) {
		console(split('LocalPackages', @trace['file'])[-1].':'.@trace['line'].' '.@trace['id'], false);
	}
	return(true);
});

/*
	Gets a value from any number of nested arrays using multiple keys.
	Returns null if expected arrays or keys don't exist.
	Example: @value = _multi_array_get(@nestedArrays, 'key_for_parent_array', 'key_for_nested_array');
*/
proc _multi_array_get(@value) {
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
	Removes certain entities from inside (and near) region.
	Since it select entities by chunk, it may remove some entities that are just outside the region.
	@region: The WorldGuard region name. It will use the player or commandblock world.
	@entities: An array of entity types to remove. (some entity types are automatically protected)
*/
proc _remove_region_entities(@region, @entityTypes = array(), @world = 'custom', @removeProtected = false) {
	if(!sk_region_exists(@world, @region)) {
		console('Can\'t remove entities because region doesn\'t exist: '.@region, false);
		return(false);
	}
	@loc = sk_region_info(@region, @world, 0);
	if(array_size(@loc) > 2) {
		return(false);
	}
	@xMax = floor(@loc[0][0] / 16);
	@zMax = floor(@loc[0][2] / 16);
	@excludeEntities = array('PLAYER', 'COMPLEX_PART', 'ITEM_FRAME', 'PAINTING', 'UNKNOWN');
	for(@x = floor(@loc[1][0] / 16), @x <= @xMax, @x++) {
		for(@z = floor(@loc[1][2] / 16), @z <= @zMax, @z++) {
			foreach(@entity in all_entities(@world, @x, @z)) {
				@type = entity_type(@entity);
				if(!@entityTypes && !array_contains(@excludeEntities, @type)
				|| array_contains(@entityTypes, @type)) {
					if(@type === 'ARMOR_STAND' && !@removeProtected) {
						if(entity_spec(@entity)['visible']
						|| !array_contains(sk_regions_at(entity_loc(@entity)), @region)) {
							continue();
						}
					}
					try {
						entity_remove(@entity);
					} catch(BadEntityException @ex) {
						console('Entity not found when trying to remove from region.', false);
						console('Region: '.@region.', EntityID: '.@entity, false);
					}
				}
			}
		}
	}
	return(true)
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
	_update_activities();
	if(@region && @world) {
		if(function_exists('discord_broadcast')) {
			discord_broadcast('minecraft_chat', '**'.@title.' started...**');
		}
		if(extension_exists('CHDynmap')) {
			try {
				@regionInfo = sk_region_info(@region, @world);
				@minX = @regionInfo[0][1][0];
				@minZ = @regionInfo[0][1][2];
				@maxX = @regionInfo[0][0][0];
				@maxZ = @regionInfo[0][0][2];
				dm_create_marker('markers', array(
					'type': 'AREA',
					'world': @world,
					'label': @title,
					'id': @id,
					'corners': array(
						array(@minX, 0, @minZ, @world),
						array(@maxX, 0, @minZ, @world),
						array(@maxX, 0, @maxZ, @world),
						array(@minX, 0, @maxZ, @world),
					),
				));
				dm_set_marker_line_style('markers', @id, array(
					'color': array('r': 255, 'g': 0, 'b': 0),
					'opacity': 1,
					'weight': 1,
				));
				dm_set_marker_fill_style('markers', @id, array(
					'color': array('r': 255, 'g': 0, 'b': 0),
					'opacity': 0.1,
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
		_update_activities();
		if(@activity['region']) {
			if(extension_exists('CHDynmap')) {
				try(dm_delete_marker('markers', @id));
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

proc _update_activities() {
	@activities = _get_activities_string();
	@footer = '';
	if(@activities) {
		@footer = color('gray').'Current Activities:\n'.color('reset').@activities;
	}
	foreach(@p in all_players()) {
		set_plist_footer(@p, @footer);
	}
}
