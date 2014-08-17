proc(_equip_park) {
	_clear_pinv()
	
	if(has_permission('group.moderators')) {
		@guide = get_value('book', 'guide')
		set_pinv(player(), array(
			1: array('type': 340, 'meta': array('display': 'Park Directory')),
			2: @guide,
		))
	}
	
	@pdata = get_value('players', to_lower(player()))
	if(!is_null(@pdata) 
	&& array_index_exists(@pdata, 'support')
	&& @pdata['support'] >= 15) {
		set_pinv(player(), array(
			4: array(
				'type': 401, 
				'meta': array(
					'display': color('green').'Random Firework',
					'lore': array(
						color('f').'Available to ',
						color('f').'server supporters',
						color('f').'for $15+',
					)
				)
			),
		))
	}

}

proc(_item_meta, @item, @index) {
	if(is_null(@item)
	|| is_null(@item['meta'])) {
		return(null)
	}
	return(@item['meta'][@index])
}

proc(_relative, @originloc, @dir, @amount = 1) {
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

proc(_relative_coords, @originloc, @x, @y, @z) {
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

proc(_clear_pinv, @player) {
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
}

proc(_acc_add, @player, @amount) {
	@pdata = get_value('players', to_lower(@player))
	if(!@pdata, return(false))
	if(!array_index_exists(@pdata, 'coins'), @pdata['coins'] = 100)
	@pdata['coins'] = @pdata['coins'] + @amount
	store_value('players', to_lower(@player), @pdata)
	return(true)
}

proc(_acc_subtract, @player, @amount) {
	@pdata = get_value('players', to_lower(@player))
	if(!@pdata, return(false))
	if(!array_index_exists(@pdata, 'coins'), @pdata['coins'] = 100)
	@pdata['coins'] = @pdata['coins'] - @amount
	store_value('players', to_lower(@player), @pdata)
	return(true)
}

proc(_acc_balance, @player) {
	@pdata = get_value('players', to_lower(@player))
	if(!@pdata, return(null))
	if(!array_index_exists(@pdata, 'coins')) {
		return(100)
	} else {
		return(@pdata['coins'])
	}
}

proc(_get_effects) {
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
}

# Removes all specified entities from region.
# Since this loads entities by chunks it has a loose entity selection
proc(_remove_region_entities, @region, @entities = array()) {
	if(get_command_block(), @world = get_command_block()['world'], @world = pworld())
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

# Remove all potion effects from a player
proc(_clear_peffects, @player) {
	if(!@player, @player = player())
	@effects = get_peffect(@player)
	foreach(@e in @effects) {
		set_peffect(@player, @e['id'], 0, 0)
	}
}

#color display name
proc(_colorname, @player) {
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
}

#returns world alias when given world folder name
proc(_worldname, @world) {
	@worlds = array('world': 'Alpha', 'world_nether': 'Alpha Nether', 'world3': 'Delta', 'world3_nether': 'Delta Nether', 'world4': 'Gamma', 'world4_nether': 'Gamma Nether', 'world_the_end': 'The End', 'custom': 'FrogPark', 'dev': 'Dev', 'outworld': 'Outworld', 'omega': 'Omega', 'omega_nether', 'Omega Nether')
	if(array_index_exists(@worlds, to_lower(@world))) { 
		return(@worlds[to_lower(@world)])
	} else {
		return(to_lower(@world))
	}
}

#returns world folder name when given world alias
proc(_worldid, @world) {
	@worlds = array('alpha': 'world', 'alphanether': 'world_nether', 'delta': 'world3', 'deltanether': 'world3_nether', 'gamma': 'world4', 'gammanether': 'world4_nether', 'theend': 'world_the_end', 'custom': 'custom', 'frogpark': 'custom', 'dev': 'dev', 'outworld': 'outworld', 'omega': 'omega', 'omeganether': 'omega_nether')
	if(array_index_exists(@worlds, to_lower(@world))) { 
		return(@worlds[to_lower(@world)])
	} else {
		return(to_lower(@world))
	}
}

#Messsages every player within the specified region
proc(_regionmsg, @region, @msg) {
	foreach(@player in all_players()) {
		if(ponline(@player)
		&& array_contains(sk_current_regions(@player), @region)) {
			tmsg(@player, @msg)
		}
	}
}

#Messsages every player within the specified world
proc(_worldmsg, @world, @msg) {
	foreach(@player in all_players(@world)) {
		if(ponline(@player)) {
			tmsg(@player, @msg)
		}
	}
}

#get qty of specific item in chest
proc(_get_inventory_count, @loc, @item) {
	try(@size = get_inventory_size(@loc), return(null))
	if(is_numeric(@item), @item = @item.':0')
	@count = 0
	for(@i = 0, @i < @size, @i++) {
		if(is_null(assign(@slot, get_inventory_item(@loc, @i))), continue())
		if(@slot['type'].':'.@slot['data'] == @item || @item == 'all') {
			@count = @count + @slot['qty']
		}
	}
	return(@count) 
}

proc(_horizontal_distance, @loc1, @loc2) {
	return(max(sqrt((@loc1[0] - @loc2[0]) ** 2), sqrt((@loc1[2] - @loc2[2]) ** 2)))
}
