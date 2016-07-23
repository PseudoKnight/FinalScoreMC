set_uncaught_exception_handler(closure(@ex){
	msg(color('red').@ex['message']);
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
				return(1.06)
			}
			return(0.53);
		case 'G#':
			if(@octave == 1) {
				return(1.12)
			}
			return(0.56);
		case 'A':
			if(@octave == 1) {
				return(1.19)
			}
			return(0.6);
		case 'A#':
			if(@octave == 1) {
				return(1.26)
			}
			return(0.63);
		case 'B':
			if(@octave == 1) {
				return(1.33)
			}
			return(0.67);
		case 'C':
			if(@octave == 1) {
				return(1.41)
			}
			return(0.7);
		case 'C#':
			if(@octave == 1) {
				return(1.50)
			}
			return(0.75);
		case 'D':
			if(@octave == 1) {
				return(1.59)
			}
			return(0.79);
		case 'D#':
			if(@octave == 1) {
				return(1.68)
			}
			return(0.84);
		case 'E':
			if(@octave == 1) {
				return(1.78)
			}
			return(0.89);
		case 'F':
			if(@octave == 1) {
				return(1.89)
			}
			return(0.94);
		default:
			return(1.0);
	}
}

/*
	Sets a player's inventory with a preset kit
*/
proc _equip_kit(@player, @kit = 'adventure') {
	if(!@player) {
		@player = player();
	}

	if(_is_survival_world(pworld(@player))) {
		return();
	}

	switch(@kit) {
		case 'adventure':
			@mode = pmode(@player);
			if(@mode == 'SURVIVAL') {
				set_pmode(@player, 'ADVENTURE');
			}
			_clear_pinv(@player);
			@pdata = _pdata(@player);
			set_pinv(@player, associative_array(
				2: associative_array('name': 'BOOK', 'meta': associative_array(
					'display': 'Park Directory',
				)),
				3: associative_array('name': 'COOKED_MUTTON', 'qty': 64, 'meta': associative_array(
					'display': 'Frog Legs',
					'lore': array('Good eatin\''),
				)),
				4: if(array_index_exists(@pdata, 'support') && @pdata['support'] >= 10) {
					associative_array(
						'name': 'FIREWORK',
						'meta': associative_array(
							'display': colorize('&r&kX&a&l Random Firework &r&kX'),
							'lore': array(
								color('f').'Available to ',
								color('f').'server supporters',
							)
						)
					)
				} else {
					null
				},
			));
			set_pflight(@player, false);

		case 'creative':
			_clear_pinv(@player);
			set_pinv(@player, associative_array(
				0: associative_array('name': 'COMPASS', 'meta': associative_array(
					'display': 'Teleporter',
				)),
				1: associative_array('name': 'GOLD_AXE', 'meta': associative_array(
					'display': 'WorldEdit Selector',
				)),
			));
	}
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
	Compacts all an inventory array by removing unnecessary keys in item arrays
*/
proc _minify_inv(@inv, @keepnulls = false) {
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
			if(array_size(@item['meta']['flags']) == 0) {
				array_remove(@item['meta'], 'flags');
			}
		}
	}

	if(array_index_exists(@inv, 'type')) {
		_minify_item(@inv);
	} else {
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
}

/*
	Returns a new shifted location from origin based on a single direction and distance
*/
proc _relative(@originloc, @dir, @amount = 1) {
	@loc = @originloc[]
	switch(@dir) {
	case 'down':
		if(array_index_exists(@loc, 'y')) {
			@loc['y'] -= @amount
		}
		@loc[1] -= @amount

	case 'up':
		if(array_index_exists(@loc, 'y')) {
			@loc['y'] += @amount
		}
		@loc[1] += @amount

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

	case 'west':
		if(array_index_exists(@loc, 'x')) {
			@loc['x'] -= @amount
		}
		@loc[0] -= @amount

	case 'east':
		if(array_index_exists(@loc, 'x')) {
			@loc['x'] += @amount
		}
		@loc[0] += @amount

	default:
		console('Error: unhandled relative direction: '.@dir, false);

	}
	return(@loc)
}

/*
	Returns a new shifted location from the origin based on relative Minecraft coordinate inputs
*/
proc _relative_coords(@originloc, @x, @y, @z) {
	@loc = @originloc[]
	if(@x[0] === '~') {
		if(@x === '~') {
			@loc['x'] = @originloc['x']
		} else {
			@loc['x'] = @originloc['x'] + substr(@x, 1)
		}
	} else {
		@loc['x'] = @x
	}
	if(@y[0] === '~') {
		if(@y === '~') {
			@loc['y'] = @originloc['y']
		} else {
			@loc['y'] = @originloc['y'] + substr(@y, 1)
		}
	} else {
		@loc['y'] = @y
	}
	if(@z[0] === '~') {
		if(@z === '~') {
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
	set_pinv(@player, associative_array(
		0: null, 1: null, 2: null, 3: null, 4: null, 5: null, 6: null, 7: null, 8: null,
		9: null, 10: null, 11: null, 12: null, 13: null, 14: null, 15: null, 16: null, 17: null,
		18: null, 19: null, 20: null, 21: null, 22: null, 23: null, 24: null, 25: null, 26: null,
		27: null, 28: null, 29: null, 30: null, 31: null, 32: null, 33: null, 34: null, 35: null,
		100: null, 101: null, 102: null, 103: null, -106: null
	));
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
	if(!array_index_exists(@pdata, 'coins'), @pdata['coins'] = 100)
	@pdata['coins'] = @pdata['coins'] + @amount
	_store_pdata(@player, @pdata)
	return(true)
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
	if(!array_index_exists(@pdata, 'coins'), @pdata['coins'] = 100)
	@pdata['coins'] = @pdata['coins'] - @amount
	_store_pdata(@player, @pdata)
	return(true)
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
proc _remove_region_entities(@region, @entities) {
	@world = 'custom'; # we don't need this for other worlds
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
	} else if(has_permission(@player, 'group.builder')) {
		@color = 'gold';
	} else if(has_permission(@player, 'group.member')) {
		@color = 'yellow';
	}
	return(color(@color));
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
	Returns the character width map
*/
proc _char_width() {
	# Thanks to Octopod for this list
	return(associative_array(
		',': 2,
		'!': 2,
		':': 2,
		'i': 2,
		'|': 2,
		'.': 2,
		'`': 3,
		'\'': 3,
		'l': 3,
		'[': 4,
		']': 4,
		' ': 4,
		'I': 4,
		't': 4,
		'*': 5,
		'>': 5,
		'<': 5,
		'{': 5,
		'}': 5,
		'f': 5,
		'k': 5,
	));
}

/*
	Returns the pixel width of the string
*/
proc _string_width(@string) {
	@width = 0;
	@bold = 0;
	@chars = _char_width();
	foreach(@i: @c in @string) {
		if(@c === '\u00a7') {
			if(@string[@i + 1] === 'l') {
				@bold = 1;
			} else if(reg_match('[0-9a-fr]', @string[@i + 1])) {
				@bold = 0;
			}
			continue(2);
		}
		if(array_index_exists(@chars, @c)) {
			@width += @chars[@c] + @bold;
		} else {
			@width += 6 + @bold;
		}
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
	@charWidth = 6;
	@chars = _char_width();
	if(array_index_exists(@chars, @fillChar)) {
		@charWidth = @chars[@fillChar];
	}

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
		@message .= ',{"text":"';
		if(!is_array(@c)) {
			@message .= colorize(@c).'"}';
		} else {
			@message .= colorize(@c[0]).'","clickEvent":{"action":"run_command","value":"'.@c[1].'"}}';
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
	try {
		@inv = get_inventory(@loc);
	} catch(FormatException @ex) {
		return(null);
	}
	if(is_numeric(@item), @item = @item.':0')
	@count = 0
	foreach(@i in @inv) {
		if(!is_null(@i)
		&& (@i['type'].':'.@i['data'] === @item || @item === 'all')) {
			@count = @count + @i['qty']
		}
	}
	return(@count)
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
