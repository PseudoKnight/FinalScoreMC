/*
	Gets the player count for the whole server or world if specified.
*/
proc _player_count(@world) {
	@players = all_players();
	if(@world) {
		foreach(@index: @player in @players) {
			if(pworld(@player) != @world) {
				array_remove(@players, @index);
			}
		}
	}
	return(array_size(@players));
}

/*
	Returns if the world is a survival world
*/
proc _is_survival_world(@world) {
	return(!(@world == 'dev' || @world == 'custom'))
}

/*
	Sets a player's inventory for Frog Park
*/
proc _equip_park(@player) {
	if(!@player) {
		@player = player();
	}
	
	if(pworld(@player) != 'custom') {
		return();
	}

	_clear_pinv(@player)
	
	set_pinv(@player, array(
		2: array('name': 'BOOK', 'meta': array(
			'display': 'Park Directory',
		)),
		3: array('name': 'COOKED_MUTTON', 'qty': 64, 'meta': array(
			'display': 'Frog Legs', 
			'lore': array('Good eatin\''),
		)),
	))
	
	try(
	@pdata = _pdata(@player)
	if(array_index_exists(@pdata, 'support')
	&& @pdata['support'] >= 10) {
		set_pinv(@player, array(
			4: array(
				'type': 401, 
				'meta': array(
					'display': color('green').color('bold').'Random Firework',
					'lore': array(
						color('f').'Available to ',
						color('f').'server supporters',
					)
				)
			),
		))
	}
	)

}

/*
	Returns specific item meta or null if it doesn't exist
*/
proc _item_meta(@item, @index) {
	if(is_null(@item)
	|| is_null(@item['meta'])) {
		return(null)
	}
	return(@item['meta'][@index])
}

/*
	Removes unnecessary indexes in item arrays for compact storage
*/
proc _minify_item(@item) {
	array_remove(@item, 'type');
	array_remove(@item, 'enchants');
	if(@item['data'] == 0) {
		array_remove(@item, 'data');
	}
	if(@item['qty'] == 1) {
		array_remove(@item, 'qty');
	}
	if(is_null(@item['meta'])) {
		array_remove(@item, 'meta');
	} else {
		if(array_size(@item['meta']['enchants']) == 0) {
			array_remove(@item['meta'], 'enchants');
		}
		if(is_null(@item['meta']['display'])) {
			array_remove(@item['meta'], 'display');
		}
		if(is_null(@item['meta']['lore'])) {
			array_remove(@item['meta'], 'lore');
		}
		if(array_index_exists(@item['meta'], 'firework')
		&& is_null(@item['meta']['firework'])) {
			array_remove(@item['meta'], 'firework');
		}
		if(@item['meta']['repair'] == 0) {
			array_remove(@item['meta'], 'repair');
		}
	}
}

/*
	Compacts all item arrays in an inventory array
*/
proc _minify_inv(@inv, @keepnulls = false) {
	foreach(@slot: @item in @inv) {
		if(@item == null) {
			if(!@keepnulls) {
				array_remove(@inv, @slot);
			}
		} else {
			_minify_item(@item);
		}
	}
}

/*
	Returns a new shifted location from origin based on a single direction and distance
*/
proc _relative(@originloc, @dir, @amount = 1) {
	@loc = @originloc[]
	switch(@dir) {
	case 'up':
		if(array_index_exists(@loc, 'y')) {
			@loc['y'] += @amount
		}
		@loc[1] += @amount
		
	case 'down':
		if(array_index_exists(@loc, 'y')) {
			@loc['y'] -= @amount
		}
		@loc[1] -= @amount
		
	case 'north':
		if(array_index_exists(@loc, 'z')) {
			@loc['z'] -= @amount
		}
		@loc[2] -= @amount
		
	case 'south':
		if(array_index_exists(@loc, 'z')) {
			@loc['z'] += @amount
		}
		@loc[2] += @amount
		
	case 'east':
		if(array_index_exists(@loc, 'x')) {
			@loc['x'] += @amount
		}
		@loc[0] += @amount
		
	case 'west':
		if(array_index_exists(@loc, 'x')) {
			@loc['x'] -= @amount
		}
		@loc[0] -= @amount
	
	default:
		console('Error: unhandled relative direction: '.@dir);
		
	}
	return(@loc)
}

/*
	Returns a new shifted location from the origin based on relative Minecraft coordinate inputs
*/
proc _relative_coords(@originloc, @x, @y, @z) {
	@loc = @originloc[]
	if(@x[0] == '~') {
		if(@x == '~') {
			@loc['x'] = @originloc['x']
		} else {
			@loc['x'] = @originloc['x'] + substr(@x, 1)
		}
	} else {
		@loc['x'] = @x
	}
	if(@y[0] == '~') {
		if(@y == '~') {
			@loc['y'] = @originloc['y']
		} else {
			@loc['y'] = @originloc['y'] + substr(@y, 1)
		}
	} else {
		@loc['y'] = @y
	}
	if(@z[0] == '~') {
		if(@z == '~') {
			@loc['z'] = @originloc['z']
		} else {
			@loc['z'] = @originloc['z'] + substr(@z, 1)
		}
	} else {
		@loc['z'] = @z
	}
	return(@loc)
}

/*
	Gets a normalized vector when given a yaw and pitch
*/
proc _get_vector(@yaw, @pitch) {
	@yaw = @yaw + 90;
	@pitch = 0 - @pitch;
	@vector = array('x': 0, 'y': 0, 'z': 0);
	@vector['x'] = cos(to_radians(@yaw)) * cos(to_radians(@pitch));
	@vector['y'] = sin(to_radians(@pitch));
	@vector['z'] = sin(to_radians(@yaw)) * cos(to_radians(@pitch));
	return(@vector);
}

/*
	Removes all items from a player's inventory and armor slots
*/
proc _clear_pinv(@player) {
	if(!@player) {
		@player = player()
	}
	@world = pworld(@player)
	if(_is_survival_world(@world)) {
		return()
	}
	set_pinv(@player, array(
		null, null, null, null, null, null, null, null, null,
		null, null, null, null, null, null, null, null, null,
		null, null, null, null, null, null, null, null, null,
		null, null, null, null, null, null, null, null, null,
		100: null, 101: null, 102: null, 103: null
	))
}

/*
	Add an amount to a player's coin balance
*/
proc _acc_add(@player, @amount) {
	try(
		@pdata = _pdata(@player)
	, #catch 
		return(false)
	)
	if(!array_index_exists(@pdata, 'coins'), @pdata['coins'] = 100)
	@pdata['coins'] = @pdata['coins'] + @amount
	_store_pdata(@player, @pdata)
	return(true)
}

/*
	Subtracts an amount from a player's coin balance
*/
proc _acc_subtract(@player, @amount) {
	try(
		@pdata = _pdata(@player)
	, #catch 
		return(false)
	)
	if(!array_index_exists(@pdata, 'coins'), @pdata['coins'] = 100)
	@pdata['coins'] = @pdata['coins'] - @amount
	_store_pdata(@player, @pdata)
	return(true)
}

/*
	Returns the amount of coins a player has
*/
proc _acc_balance(@player) {
	try(
		@pdata = _pdata(@player)
	, #catch 
		return(0)
	)
	if(!array_index_exists(@pdata, 'coins')) {
		return(100)
	} else {
		return(@pdata['coins'])
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
		'blindness': 15,
		'nightvision': 16,
		'hunger': 17,
		'weakness': 18,
		'poison': 19,
		'wither': 20,
		'boost': 21,
		'absorption': 22,
		'saturation': 23
	))
}

/*
	Removes certain entities from inside (and near) region.
	Since it select entities by chunk, it may remove some entities that are just outside the region.
	@region: The WorldGuard region name. It will use the player or commandblock world.
	@entities: An array of entity types to remove. (some entity types are automatically protected)
*/
proc _remove_region_entities(@region, @entities = array()) {
	@world = 'custom'; # we don't need this for other worlds
	if(!sk_region_exists(@world, @region)) {
		console('Can\'t remove entities because region doesn\'t exist: '.@region)
		return(false)
	}
	@loc = sk_region_info(@region, @world)[0]
	if(array_size(@loc) > 2) {
		return(false)
	}
	for(@x = @loc[1][0], @x < (@loc[0][0] + 15), inc(@x, 16)) {
		if(@x > @loc[0][0], @x = @loc[0][0])
		for(@z = @loc[1][2], @z < (@loc[0][2] + 15), inc(@z, 16)) {
			if(@z > @loc[0][2], @z = @loc[0][2])
			foreach(@entity in all_entities(array(@x, 64, @z, @world))) {
				@type = entity_type(@entity)
				if((!@entities && !array_contains(array('PLAYER', 'COMPLEX_PART', 'ITEM_FRAME', 'PAINTING', 'UNKNOWN'), @type))
				|| array_contains(@entities, @type)) {
					if(@type == 'ARMOR_STAND' && entity_spec(@entity)['visible']) {
						continue();
					}
					try(
					entity_remove(@entity)
					, # if fail
						console('Entity not found when trying to remove from region.')
						console('Region: '.@region.', EntityID: '.@entity)
					)
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
	if(!@player, @player = player())
	@effects = get_peffect(@player)
	foreach(@e in @effects) {
		set_peffect(@player, @e['id'], 0, 0)
	}
}

/*
	Returns a Minecraft color code for the specified player's group
*/
proc _colorname(@player) {
	if(!@player, @player = player());
	@color = 'white';
	if(has_permission(@player, 'group.moderator')) {
		@color = 'aqua';
	} else if(has_permission(@player, 'group.donor')) {
		@color = 'green';
	} else if(has_permission(@player, 'group.member')) {
		@color = 'yellow';
	}
	return(color(@color));
}

/*
	Refreshes the player colors on the tab list.
	This needs to be done for all players when new players join
	and for players that change scoreboards. (for 1.8.0)
*/
proc _refresh_tablist(@players) {
	foreach(@p in @players) {
		if(length(@p) > 14) {
			# max tab list length is 16 chars including colors
			set_list_name(@p, _colorname(@p).substr(@p, 0, 14));
		} else {
			set_list_name(@p, _colorname(@p).@p);
		}
	}
}


/*
	Returns world alias when given world folder name
*/
proc _worldname(@world) {
	@worlds = array(
		'world': 'Alpha', 
		'world_nether': 'Alpha Nether', 
		'world3': 'Delta', 
		'world3_nether': 'Delta Nether', 
		'world4': 'Gamma', 
		'world4_nether': 'Gamma Nether',
		'world_the_end': 'The End', 
		'custom': 'FrogPark', 
		'dev': 'Dev', 
		'outworld': 'Outworld', 
		'omega': 'Omega', 
		'omega_nether':	'Omega Nether',
		'outworld': 'Outworld',
		'outworld_nether': 'Outworld Nether',
	)
	if(array_index_exists(@worlds, to_lower(@world))) { 
		return(@worlds[to_lower(@world)])
	} else {
		return(to_lower(@world))
	}
}

/*
	Returns a world folder name when given a world alias
*/
proc _worldid(@world) {
	@worlds = array(
		'alpha': 'world', 
		'alphanether': 'world_nether', 
		'delta': 'world3', 
		'deltanether': 'world3_nether', 
		'gamma': 'world4', 
		'gammanether': 'world4_nether', 
		'theend': 'world_the_end', 
		'custom': 'custom', 
		'frogpark': 'custom', 
		'dev': 'dev', 
		'outworld': 'outworld', 
		'omega': 'omega', 
		'omeganether': 'omega_nether',
		'outworld': 'outworld',
		'outworldnether': 'outworld_nether',
	)
	@alias = to_lower(reg_replace('[_-]', '', @world))
	if(array_index_exists(@worlds, @alias)) { 
		return(@worlds[@alias])
	} else {
		return(to_lower(@world))
	}
}

/*
	Messsages every player within a WorldGuard region
*/
proc _regionmsg(@region, @msg) {
	foreach(@player in all_players()) {
		if(ponline(@player)
		&& array_contains(sk_current_regions(@player), @region)) {
			tmsg(@player, @msg)
		}
	}
}

/*
	Messsages every player within a world
*/
proc _worldmsg(@world, @msg) {
	foreach(@player in all_players(@world)) {
		if(ponline(@player)) {
			tmsg(@player, @msg)
		}
	}
}

/*
	Returns the width of the character
*/
proc _char_width(@char, @bold = 0) {
	# Thanks to Octopod for this list
	switch(@char) {
		case ',':
		case '!':
		case ':':
		case 'i':
		case '|':
		case '.':
			return(2 + @bold);
		case '`':
		case '\'':
		case 'l':
			return(3 + @bold);
		case '[':
		case ']':
		case ' ':
		case 'I':
		case 't':
			return(4 + @bold);
		case '*':
		case '>':
		case '<':
		case '{':
		case '}':
		case 'f':
		case 'k':
			return(5 + @bold);
		default:
			return(6 + @bold);
	}
}

/*
	Returns the pixel width of the string
*/
proc _string_width(@string) {
	@width = 0;
	@bold = 0;
	foreach(@i: @c in @string) {
		if(@c == '\u00a7') {
			if(@string[@i + 1] == 'l') {
				@bold = 1;
			} else if(reg_match('[0-9a-fr]', @string[@i + 1])) {
				@bold = 0;
			}
			continue(2);
		}
		@width += _char_width(@c, @bold);
	}
	return(@width);
}

/*
	Fills a string evenly with a character so that it extends to a full line
*/
proc _fill_string(@replaceChar, @fillChar, @string, @lineWidth = 320) {
	@width = _string_width(replace(@string, @replaceChar, ''));
	@fillCount = reg_count('\\'.@replaceChar, @string);
	
	@remainingWidth = @lineWidth - @width;
	@charWidth = _char_width(@fillChar);

	@fillWidth = (@remainingWidth / @charWidth) / @fillCount;
	
	@fillArray = array();
	array_resize(@fillArray, floor(@fillWidth), @fillChar);
	@fillString = array_implode(@fillArray, '');
	return(replace(@string, @replaceChar, @fillString));
}

/*
	Takes a string and returns an array of strings of the specified width.
	This will not split words.
*/
proc _wrap_string(@string, @width = 320) {
	@words = split(' ', @string);
	@lines = array();
	@linewidth = 0;
	@line = '';
	foreach(@word in @words) {
		@wordwidth = _string_width(@word);
		@linewidth += @wordwidth;
		if(@linewidth + 3 < @width) {
			if(length(@line) > 0) {
				@linewidth += 3;
				@line .= ' '.@word;
			} else {
				@line .= @word;
			}
		} else {
			@lines[] = @line;
			@linewidth = @wordwidth;
			@line = @word;
		}
	}
	@lines[] = @line;
	return(@lines);
}

/*
	Create clickable commands for a JSON message
*/
proc _click_tell(@recipients, @components) {
	@message = ' [""';
	foreach(@c in @components) {
		@message .= ',{text:"';
		if(!is_array(@c)) {
			@message .= colorize(@c).'"}';
		} else {
			@message .= colorize(@c[0]).'",clickEvent:{action:"run_command",value:"'.@c[1].'"}}';
		}
	}
	@message .= ']';
	foreach(@player in @recipients) {
		runas('~console', '/tellraw '.@player.@message);
	}
}

/*
	Returns how many of an item an inventory contains at a location.
	@item: 0:0 format
*/
proc _get_inventory_count(@loc, @item) {
	try(@inv = get_inventory(@loc), return(null))
	if(is_numeric(@item), @item = @item.':0')
	@count = 0
	foreach(@i in @inv) {
		if(!is_null(@i)
		&& (@i['type'].':'.@i['data'] == @item || @item == 'all')) {
			@count = @count + @i['qty']
		}
	}
	return(@count) 
}

/*
	Returns the max distance on the x or z axis between two locations
*/
proc _horizontal_distance(@loc1, @loc2) {
	return(max(sqrt((@loc1[0] - @loc2[0]) ** 2), sqrt((@loc1[2] - @loc2[2]) ** 2)))
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
	Retrieves a player's mojang UUID from the mojang api, and returns the results
	as an array that corresponds to the input array of player names.
	@param players An array of players that will be checked.
	@param closure The callback closure, which will be called once the
	request finishes. It will be sent the array of returned values.
*/
proc _player_uuid(@players, @closure) {
    @success = closure(@response){
        @array = json_decode(@response['body']);
        execute(@array, @closure);
    };
    @options = array(
        'method': 'POST',
        'headers': array('Content-Type': 'application/json'),
        'params': json_encode(@players),
        'success': @success,
    );
    http_request('https://api.mojang.com/profiles/minecraft', @options);
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
*/
proc _pdata(@player, @autocomplete = true) {
	@player = to_lower(@player);
	@pdata = import('pdata.'.@player);
	if(is_null(@pdata)) {
		@uuid = _get_uuid(@player, @autocomplete);
		@pdata = get_value('uuids', @uuid);
		if(is_null(@pdata)) {
			throw('NotFoundException', 'User data not stored in database: '.@uuid);
		}
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
	Adds an activity to the activities list.
	This is used for checking which games are running.
*/
proc _add_activity(@id, @title) {
	@activities = import('activities');
	if(is_null(@activities)) {
		@activities = array();
	}
	@activities[@id] = @title;
	export('activities', @activities);
	export('currently', @title);
}

/*
	Removes an activity from the activities list.
*/
proc _remove_activity(@id) {
	@activities = import('activities');
	if(!is_null(@activities) && array_index_exists(@activities, @id)) {
		array_remove(@activities, @id);
		export('activities', @activities);
		export('currently', null);
	}
}