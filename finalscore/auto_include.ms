proc('_line_distance', @p1, @p2, @p3, @p4) {
	@p13 = array()
	@p43 = array()
	@p21 = array()
	
	@p13['x'] = @p1['x'] - @p3['x'];
	@p13['y'] = @p1['y'] - @p3['y'];
	@p13['z'] = @p1['z'] - @p3['z'];
	
	@p43['x'] = @p4['x'] - @p3['x'];
	@p43['y'] = @p4['y'] - @p3['y'];
	@p43['z'] = @p4['z'] - @p3['z'];
	
	@p21['x'] = @p2['x'] - @p1['x'];
	@p21['y'] = @p2['y'] - @p1['y'];
	@p21['z'] = @p2['z'] - @p1['z'];

	@d1343 = @p13['x'] * @p43['x'] + @p13['y'] * @p43['y'] + @p13['z'] * @p43['z'];
	@d4321 = @p43['x'] * @p21['x'] + @p43['y'] * @p21['y'] + @p43['z'] * @p21['z'];
	@d1321 = @p13['x'] * @p21['x'] + @p13['y'] * @p21['y'] + @p13['z'] * @p21['z'];
	@d4343 = @p43['x'] * @p43['x'] + @p43['y'] * @p43['y'] + @p43['z'] * @p43['z'];
	@d2121 = @p21['x'] * @p21['x'] + @p21['y'] * @p21['y'] + @p21['z'] * @p21['z'];

	@mua = (@d1343 * @d4321 - @d1321 * @d4343) / (@d2121 * @d4343 - @d4321 * @d4321);
	@mub = (@d1343 + @d4321 * @mua) / @d4343;

	msg(@mua)
	msg(@mub)
	
	@pa = array()
	@pb = array()
	
	@pa['x'] = @p1['x'] + (@mua * @p21['x']);
	@pa['y'] = @p1['y'] + (@mua * @p21['y']);
	@pa['z'] = @p1['z'] + (@mua * @p21['z']);
	
	@pb['x'] = @p3['x'] + (@mub * @p43['x']);
	@pb['y'] = @p3['y'] + (@mub * @p43['y']);
	@pb['z'] = @p3['z'] + (@mub * @p43['z']);
	
	return(sqrt(((@pa['x'] - @pb['x']) ** 2) + ((@pa['y'] - @pb['y']) ** 2) + ((@pa['z'] - @pb['z']) ** 2)))
}

proc('_squared_distance_to_segment', @p1, @p2a, @p2b) {
	@vx = @p2b['x'] - @p2a['x'];
	@vy = @p2b['y'] - @p2a['y'];
	@vz = @p2b['z'] - @p2a['z'];

	@wx = @p1['x'] - @p2a['x'];
	@wy = @p1['y'] - @p2a['y'];
	@wz = @p1['z'] - @p2a['z'];

	@c1 = @wx * @vx + @wy * @vy + @wz * @vz;
	if(@c1 <= 0) {
		return(((@p1['x'] - @p2a['x']) ** 2) + ((@p1['y'] - @p2a['y']) ** 2) + ((@p1['z'] - @p2a['z']) ** 2));
	}

	@c2 = @vx * @vx + @vy * @vy + @vz * @vz;
	if(@c2 <= @c1) {
		return(((@p1['x'] - @p2b['x']) ** 2) + ((@p1['y'] - @p2b['y']) ** 2) + ((@p1['z'] - @p2b['z']) ** 2));
	}

	@b = @c1 / @c2;
	@bx = @p2a['x'] + @b * @vx;
	@by = @p2a['y'] + @b * @vy;
	@bz = @p2a['z'] + @b * @vz;
	return(((@p1['x'] - @bx) ** 2) + ((@p1['y'] - @by) ** 2) + ((@p1['z'] - @bz) ** 2));
}

proc('_relative', @originloc, @dir, @amount = 1) {
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
		
	}
	return(@loc)
}

proc('_relative_coords', @originloc, @x, @y, @z) {
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

proc('_clear_pinv', @player,
	if(!@player) {
		@player = player()
	}
	@world = pworld(@player)
	if(@world != 'custom' && @world != 'dev') {
		return()
	}
	set_pinv(@player, array(
		null, null, null, null, null, null, null, null, null,
		null, null, null, null, null, null, null, null, null,
		null, null, null, null, null, null, null, null, null,
		null, null, null, null, null, null, null, null, null,
		100: null, 101: null, 102: null, 103: null
	))
)

proc('_acc_add', @player, @amount,
	@pdata = get_value('player.'.to_lower(@player))
	if(!@pdata, return(false))
	if(!array_index_exists(@pdata, 'coins'), @pdata['coins'] = 100)
	@pdata['coins'] = @pdata['coins'] + @amount
	store_value('player.'.to_lower(@player), @pdata)
	return(true)
)

proc('_acc_subtract', @player, @amount,
	@pdata = get_value('player.'.to_lower(@player))
	if(!@pdata, return(false))
	if(!array_index_exists(@pdata, 'coins'), @pdata['coins'] = 100)
	@pdata['coins'] = @pdata['coins'] - @amount
	store_value('player.'.to_lower(@player), @pdata)
	return(true)
)

proc('_acc_balance', @player,
	@pdata = get_value('player.'.to_lower(@player))
	if(!@pdata, return(null))
	if(!array_index_exists(@pdata, 'coins')) {
		return(100)
	} else {
		return(@pdata['coins'])
	}
)

proc('_get_effects',
	return(array(
		'speed': 1,
		'slowness': 2,
		'haste': 3,
		'fatigue': 4,
		'strength': 5,
		'health': 6,
		'damage': 7,
		'jump': 8,
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
)

# Removes all specified entities from region.
# Since this loads entities by chunks it has a loose entity selection
proc('_remove_region_entities', @region, @entities = array(),
	if(get_command_block(), @world = get_command_block()['world'], @world = pworld())
	if(!sk_region_exists(@world, @region)) {
		console('Can\'t remove entities because region doesn\'t exist: '.@region)
		return(false)
	}
	@loc = sk_region_info(@region, @world)[0]
	if(array_size(@loc) > 2) {
		console('Can\'t remove entities because region isn\'t a cuboid: '.@region)
		return(false)
	}
	for(@x = @loc[1][0], @x < (@loc[0][0] + 15), inc(@x, 16),
		if(@x > @loc[0][0], @x = @loc[0][0])
		for(@z = @loc[1][2], @z < (@loc[0][2] + 15), inc(@z, 16),
			if(@z > @loc[0][2], @z = @loc[0][2])
			foreach(all_entities(array(@x, 64, @z, @world)), @entity,
				@type = entity_type(@entity)
				if((!@entities && !array_contains(array('PLAYER', 'COMPLEX_PART', 'ITEM_FRAME', 'PAINTING', 'UNKNOWN'), @type))
				|| array_contains(@entities, @type)) {
					try(
					entity_remove(@entity)
					, # if fail
						console('Entity not found when trying to remove from region.')
						console('Region: '.@region.', EntityID: '.@entity)
					)
				}
			)
		)
	)
	return(true)
)

# Remove all potion effects from a player
proc('_clear_peffects', @player,
	if(!@player, @player = player())
	@effects = get_peffect(@player)
	foreach(@effects, @e,
		set_peffect(@player, @e['id'], 0, 0)
	)
)

#color display name
proc('_colorname', @player,
	if(!@player, @player = player())
	ifelse(has_permission(@player, 'group.moderators'),
		@color = 'aqua',
		has_permission(@player, 'group.builders'),
		@color = 'gold',
		has_permission(@player, 'group.donors'),
		@color = 'green',
		has_permission(@player, 'group.everyone'),
		@color = 'yellow',
		@color = 'white'
	)
	return(color(@color))
)

#returns world alias when given world folder name
proc('_worldname', @world,
	@worlds = array('world': 'Alpha', 'world_nether': 'Alpha Nether', 'world3': 'Delta', 'world3_nether': 'Delta Nether', 'world4': 'Gamma', 'world4_nether': 'Gamma Nether', 'world_the_end': 'The End', 'custom': 'FrogPark', 'dev': 'Dev', 'outworld': 'Outworld', 'omega': 'Omega', 'omega_nether', 'Omega Nether')
	if(array_index_exists(@worlds, to_lower(@world))) { 
		return(@worlds[to_lower(@world)])
	} else {
		return(to_lower(@world))
	}
)

#returns world folder name when given world alias
proc('_worldid', @world,
	@worlds = array('alpha': 'world', 'alphanether': 'world_nether', 'delta': 'world3', 'deltanether': 'world3_nether', 'gamma': 'world4', 'gammanether': 'world4_nether', 'theend': 'world_the_end', 'custom': 'custom', 'frogpark': 'custom', 'dev': 'dev', 'outworld': 'outworld', 'omega': 'omega', 'omeganether': 'omega_nether')
	if(array_index_exists(@worlds, to_lower(@world))) { 
		return(@worlds[to_lower(@world)])
	} else {
		return(to_lower(@world))
	}
)

#Messsages every player within the specified region
proc('_regionmsg', @region, @msg,
	foreach(all_players(), @player) {
		if(ponline(@player)
		&& array_contains(sk_current_regions(@player), @region)) {
			tmsg(@player, @msg)
		}
	}
)

#Messsages every player within the specified world
proc('_worldmsg', @world, @msg,
	foreach(all_players(@world), @player) {
		if(ponline(@player)) {
			tmsg(@player, @msg)
		}
	}
)

#get qty of specific item in chest
proc('_get_inventory_count', @loc, @item,
	try(@size = get_inventory_size(@loc), return(null))
	if(is_numeric(@item), @item = @item.':0')
	@count = 0
	for(@i = 0, @i < @size, @i++,
		if(is_null(assign(@slot, get_inventory_item(@loc, @i))), continue())
		if(@slot['type'].':'.@slot['data'] == @item || @item == 'all') {
			@count = @count + @slot['qty']
		}
	)
	return(@count) 
)

proc('_horizontal_distance', @loc1, @loc2,
	return(max(sqrt((@loc1[0] - @loc2[0]) ** 2), sqrt((@loc1[2] - @loc2[2]) ** 2)))
)

#Given two blocks, iterates through all the blocks inside the cuboid, and calls the 
#user defined function on them. The used defined procedure should accept 3 parameters,
#the x, y, and z coordinates of the block.
proc('_iterate_cuboid', @b1, @b2, @proc_name,
	for(@x = min(@b1[0], @b2[0]), @x <= max(@b1[0], @b2[0]), @x++,
		for(@y = min(@b1[1], @b2[1]), @y <= max(@b1[1], @b2[1]), @y++,
			for(@z = min(@b1[2], @b2[2]), @z <= max(@b1[2], @b2[2]), @z++,
				call_proc(@proc_name, @x, @y, @z)
			)
		)
	)
)

# Makes a call to the ban manager. Requires the CHCrypto extension.
# This takes 5 parameters:
# @endpoint - String - The action to take in the ban manager.
# @player - String - The player name making the call to the ban manager, or the UUID of the player. This player must be an admin or moderator.
# @params - Associative Array - The parameters to post to the ban manager.
# @success - Closure (Optional) - Closure to execute when the request returns successfully. The closure is passed the response as an 
# associative array. Defaults to printing success to the user.
# @error - Closure (Optional) - Closure to execute when the request returns an error. The closure is passed the error message. Defaults to 
# printing the error message to the user.
proc('_bm_request', @endpoint, @player, @params, assign(@success, closure(@result, msg('Success'))), 
	assign(@error, closure(@error_msg, msg(color('red').'Error: '.color('white').@error_msg)))) {
	
		# Add the authentication parameters
		@params['accessor_token'] = 'final-score-minecraft-server'
		@params['timestamp'] = simple_date('yyyy-MM-dd HH:mm:ss Z')
		@params['nonce'] = rand()
		# Try to get the player's UUID
		try(@uuid = entity_uuid(pinfo(@player, 13)), 
			@uuid = @player)
		@params['uuid'] = @uuid
		
		# Generate the HMAC
		@hmac_key = read('key.txt')
		@msg = ''
		foreach(array_keys(@params), @key,
			@msg .= @key . @params[@key]
		)
		@params['hmac'] = hmac_sha1(@hmac_key, @msg)
		
		http_request('http://finalscoremc.com/fsmcbm/ban-manager.php?action='.@endpoint, array(
			'method': 'POST',
			'params': @params,
			'success': closure(@response){
				@result = json_decode(@response['body'])
				if(array_index_exists(@result, 'error')) {
					# Error
					execute(@result['error'], @error)
				} else {
					# Successful
					execute(@result, @success)
				}
			}
		))
}
