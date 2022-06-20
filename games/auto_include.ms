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