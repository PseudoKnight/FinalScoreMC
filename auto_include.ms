set_uncaught_exception_handler(closure(@ex){
	if(@loc = get_command_block()) {
		console('Exception occurred in CommandBlock at '.array_normalize(@loc)[0..3], false);
	} else {
		msg(color('red').@ex['message']);
	}
	console(@ex['classType'].': '.@ex['message'], false);
	foreach(@trace in @ex['stackTrace']) {
		console(split('LocalPackages', @trace['file'])[-1].':'.@trace['line'].' '.@trace['id'], false);
	}
	return(true);
});

/*
	Gets online player from truncated name in user input
*/
proc _find_player(@player) {
	try {
		return(player(@player));
	} catch(PlayerOfflineException @ex) {
		die(color('yellow').'Could not find player starting with "'.@player.'"');
	}
}

/*
	Gets the pitch for the given tone and octave
*/
proc _get_pitch(@tone, @octave) {
	switch(@tone) {
		case 'F#':
			if(@octave == 2) {
				return(2.0);
			} else if(@octave == 1) {
				return(1.0);
			}
			return(0.5);
		case 'G':
			if(@octave == 1) {
				return(1.06);
			}
			return(0.53);
		case 'G#':
			if(@octave == 1) {
				return(1.12);
			}
			return(0.56);
		case 'A':
			if(@octave == 1) {
				return(1.19);
			}
			return(0.6);
		case 'A#':
			if(@octave == 1) {
				return(1.26);
			}
			return(0.63);
		case 'B':
			if(@octave == 1) {
				return(1.33);
			}
			return(0.67);
		case 'C':
			if(@octave == 1) {
				return(1.41);
			}
			return(0.7);
		case 'C#':
			if(@octave == 1) {
				return(1.50);
			}
			return(0.75);
		case 'D':
			if(@octave == 1) {
				return(1.59);
			}
			return(0.79);
		case 'D#':
			if(@octave == 1) {
				return(1.68);
			}
			return(0.84);
		case 'E':
			if(@octave == 1) {
				return(1.78);
			}
			return(0.89);
		case 'F':
			if(@octave == 1) {
				return(1.89);
			}
			return(0.94);
		default:
			return(1.0);
	}
}

/*
	Returns a new shifted location from origin based on a single direction and distance
*/
proc _relative(@loc, @dir, @amount = 1, @inPlace = false) {
	if(!@inPlace) {
		@loc = @loc[];
	}
	switch(@dir) {
		case 'down':
			if(is_associative(@loc)) {
				@loc['y'] -= @amount;
			}
			@loc[1] -= @amount;

		case 'up':
			if(is_associative(@loc)) {
				@loc['y'] += @amount;
			}
			@loc[1] += @amount;

		case 'north':
			if(is_associative(@loc)) {
				@loc['z'] -= @amount;
			}
			@loc[2] -= @amount;

		case 'south':
			if(is_associative(@loc)) {
				@loc['z'] += @amount;
			}
			@loc[2] += @amount;

		case 'west':
			if(is_associative(@loc)) {
				@loc['x'] -= @amount;
			}
			@loc[0] -= @amount;

		case 'east':
			if(is_associative(@loc)) {
				@loc['x'] += @amount;
			}
			@loc[0] += @amount;
	}
	return(@loc);
}

/*
	Returns a new shifted location from the origin based on relative Minecraft coordinate inputs
*/
proc _relative_coords(@originloc, @x, @y, @z) {
	@loc = @originloc[]
	if(@x[0] === '~') {
		if(@x === '~') {
			@loc['x'] = @originloc['x'];
		} else {
			@loc['x'] = @originloc['x'] + substr(@x, 1);
		}
	} else {
		@loc['x'] = @x;
	}
	if(@y[0] === '~') {
		if(@y === '~') {
			@loc['y'] = @originloc['y'];
		} else {
			@loc['y'] = @originloc['y'] + substr(@y, 1);
		}
	} else {
		@loc['y'] = @y;
	}
	if(@z[0] === '~') {
		if(@z === '~') {
			@loc['z'] = @originloc['z'];
		} else {
			@loc['z'] = @originloc['z'] + substr(@z, 1);
		}
	} else {
		@loc['z'] = @z;
	}
	return(@loc);
}

/*
	Gets a normalized vector when given a yaw and pitch
*/
proc _get_vector(@yaw, @pitch = 0, @magnitude = 1, @angle = 0) {
	if(is_array(@yaw)) {
		@angle = @magnitude;
		@magnitude = @pitch;
		@pitch = @yaw[1];
		@yaw = @yaw[0];
	}
	@yaw = @yaw + 90;
	@pitch = 0 - @pitch;
	@vector = associative_array('x': 0, 'y': 0, 'z': 0);
	@vector['x'] = @magnitude * (cos(to_radians(@yaw)) * cos(to_radians(@pitch)));
	@vector['y'] = @magnitude * sin(to_radians(@pitch)) + @angle;
	@vector['z'] = @magnitude * (sin(to_radians(@yaw)) * cos(to_radians(@pitch)));
	return(@vector);
}

/*
	Add an amount to a player's coin balance
*/
proc _acc_add(@player, @amount) {
	try {
		@pdata = _pdata(@player);
	} catch(NotFoundException @ex) {
		return(false);
	}
	if(!array_index_exists(@pdata, 'coins')) {
		@pdata['coins'] = 100; // default
	}
	@pdata['coins'] += @amount;
	_store_pdata(@player, @pdata);
	return(true);
}

/*
	Subtracts an amount from a player's coin balance
*/
proc _acc_subtract(@player, @amount) {
	try {
		@pdata = _pdata(@player);
	} catch(NotFoundException @ex) {
		return(false);
	}
	if(!array_index_exists(@pdata, 'coins')) {
		@pdata['coins'] = 100;
	}
	@pdata['coins'] -= @amount;
	_store_pdata(@player, @pdata);
	return(true);
}

/*
	Returns the amount of coins a player has
*/
proc _acc_balance(@player) {
	try {
		@pdata = _pdata(@player);
	} catch(NotFoundException @ex) {
		return(0);
	}
	if(!array_index_exists(@pdata, 'coins')) {
		return(100);
	} else {
		return(@pdata['coins']);
	}
}

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
proc _remove_region_entities(@region, @entities, @world = 'custom') {
	if(!sk_region_exists(@world, @region)) {
		console('Can\'t remove entities because region doesn\'t exist: '.@region, false);
		return(false);
	}
	@loc = sk_region_info(@region, @world)[0];
	if(array_size(@loc) > 2) {
		return(false);
	}
	@xMax = floor(@loc[0][0] / 16);
	@zMax = floor(@loc[0][2] / 16);
	@excludeEntities = array('PLAYER', 'COMPLEX_PART', 'ITEM_FRAME', 'PAINTING', 'UNKNOWN');
	if(!@entities) {
		@entities = array();
	}
	for(@x = floor(@loc[1][0] / 16), @x <= @xMax, @x++) {
		for(@z = floor(@loc[1][2] / 16), @z <= @zMax, @z++) {
			foreach(@entity in all_entities(@world, @x, @z)) {
				@type = entity_type(@entity);
				if((!@entities && !array_contains(@excludeEntities, @type))
				|| array_contains(@entities, @type)) {
					if(@type === 'ARMOR_STAND' && entity_spec(@entity)['visible']) {
						continue();
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
	Remove all potion effects from a player
*/
proc _clear_peffects(@player) {
	if(!@player) {
		@player = player();
	}
	@effects = get_peffect(@player);
	foreach(@e in @effects) {
		set_peffect(@player, @e['id'], 0, 0);
	}
}

/*
	Returns the distance between two points
	If @3d is false, returns the 2d distance with x,z
*/
proc _distance(@loc1, @loc2, @3d = true) {
	if(@3d) {
		if(is_associative(@loc1)) {
			return(sqrt(((@loc1['x'] - @loc2['x']) ** 2) + ((@loc1['y'] - @loc2['y']) ** 2) + ((@loc1['z'] - @loc2['z']) ** 2)));
		} else {
			return(sqrt(((@loc1[0] - @loc2[0]) ** 2) + ((@loc1[1] - @loc2[1]) ** 2) + ((@loc1[2] - @loc2[2]) ** 2)));
		}
	} else {
		if(is_associative(@loc1)) {
			return(sqrt(((@loc1['x'] - @loc2['x']) ** 2) + ((@loc1['z'] - @loc2['z']) ** 2)));
		} else {
			return(sqrt(((@loc1[0] - @loc2[0]) ** 2) + ((@loc1[2] - @loc2[2]) ** 2)));
		}
	}
}

/*
	Gets an offline player's UUID for db access
*/
proc _get_uuid(@player, @autocomplete = true, @dashless = true) {
	if(ponline(@player)) {
		return(puuid(@player, true));
	} else {
		@uuidDashed = get_value('players', @player);
		if(is_null(@uuidDashed)) {
			if(@autocomplete) {
				@uuids = get_values('players.'.@player);
				if(array_size(@uuids) > 0) {
					@uuidDashed = array_normalize(@uuids)[0];
				} else {
					throw('NotFoundException', 'Could not find player in database matching: '.@player);
				}
			} else {
				throw('NotFoundException', 'Player name not stored in database: '.@player);
			}
		}
		return(if(@dashless, replace(@uuidDashed, '-', ''), @uuidDashed));
	}
}

/*
	Gets stored data for account under given player name.
	Will return cached data if available.
*/
proc _pdata(@player, @autocomplete = true) {
	@player = to_lower(@player);
	@pdata = import('pdata.'.@player);
	if(is_null(@pdata)) {
		@uuid = _get_uuid(@player, @autocomplete);
		@pdata = _pdata_by_uuid(@uuid);
		if(ponline(@player)) {
			export('pdata.'.@player, @pdata);
		}
	}
	return(@pdata);
}

/*
	Gets stored data for account under given dashless UUID.
	Always returns stored data, not cached.
*/
proc _pdata_by_uuid(@uuid) {
	@pdata = get_value('uuids', @uuid);
	if(is_null(@pdata)) {
		throw('NotFoundException', 'User data not stored in database: '.@uuid);
	}
	return(@pdata);
}

/*
	Sets player data
*/
proc _store_pdata(@player, @data) {
	if(!is_array(@data), return());
	@player = to_lower(@player);
	@uuid = _get_uuid(@player);
	x_new_thread('storePlayerData', closure(){
		store_value('uuids', @uuid, @data);
	});
}

/*
	Gets current session data for player
*/
proc _pstate(@player) {
	@pstate = import('pstate.'.@player);
	if(is_null(@pstate)) {
		@pstate = array('activity': null);
		export('pstate.'.@player, @pstate);
	}
	return(@pstate);
}

/*
	Sets the activity for the player
*/
proc _set_pstate_activity(@player, @activity) {
	@pstate = _pstate(@player);
	if(@pstate['activity'] && @activity) {
		return(false);
	}
	@pstate['activity'] = @activity;
	if(@activity) {
		set_list_name(@player, color('gray').@activity.' '._colorname(@player).@player);
	} else {
		set_list_name(@player, _colorname(@player).@player);
	}
	return(true);
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
