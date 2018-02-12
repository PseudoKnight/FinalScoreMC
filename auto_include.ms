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
	Returns an array of potion effect name:id pairs
*/
proc _get_effects() {
	return(array(
		'speed': 1,
		'slowness': 2,
		'haste': 3,
		'fatigue': 4,
		'strength': 5,
		'health': 6,
		'damage': 7,
		'jump': 8,
		'leaping': 8,
		'nausea': 9,
		'regen': 10,
		'resistance': 11,
		'fireresistance': 12,
		'waterbreathing': 13,
		'invis': 14,
		'invisibility': 14,
		'blindness': 15,
		'nightvision': 16,
		'hunger': 17,
		'weakness': 18,
		'poison': 19,
		'wither': 20,
		'boost': 21,
		'healthboost': 21,
		'absorption': 22,
		'saturation': 23,
		'glowing': 24,
		'levitation': 25,
		'luck': 26,
		'badluck': 27,
	));
}

/*
	Removes certain entities from inside (and near) region.
	Since it select entities by chunk, it may remove some entities that are just outside the region.
	@region: The WorldGuard region name. It will use the player or commandblock world.
	@entities: An array of entity types to remove. (some entity types are automatically protected)
*/
proc _remove_region_entities(@region, @entities = array(), @world = 'custom') {
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
				if(!@entities && !array_contains(@excludeEntities, @type)
				|| array_contains(@entities, @type)) {
					if(@type === 'ARMOR_STAND') {
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
proc _add_activity(@id, @title) {
	@activities = import('activities');
	if(is_null(@activities)) {
		@activities = associative_array();
	}
	@activities[@id] = @title;
	export('activities', @activities);
	
	@serverTitle = colorize('&6&lFINALSCORE&e&lMC');
	@footer = color('gray').'Activities:\n'.color('reset').array_implode(array_normalize(@activities), '\n');
	foreach(@p in all_players()) {
		psend_list_header_footer(@p, @serverTitle, @footer);
	}
}

/*
	Removes an activity from the activities list.
*/
proc _remove_activity(@id) {
	@activities = import('activities');
	if(!is_null(@activities) && array_index_exists(@activities, @id)) {
		array_remove(@activities, @id);
		export('activities', @activities);
		
		@serverTitle = colorize('&6&lFINALSCORE&e&lMC');
		if(@activities) {
			@footer = color('gray').'Activities:\n'.color('reset').array_implode(array_normalize(@activities), '\n');
		} else {
			@footer = null;
		}
		foreach(@p in all_players()) {
			psend_list_header_footer(@p, @serverTitle, @footer);
		}
		return(true);
	}
	return(false);
}
