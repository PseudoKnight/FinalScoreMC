/*
	Snake data

	'loc': current location
	'dir': current direction
	'top': relative direction for clockwise rotation (eg. north)
	'head': the block type:data for the color of their block
	'tail': the block type:data for the color of their tail
	'blocks': an array of ordered block locations representing the tail, new ones pushed on end, such that
			  order is back of tail to head. This is used for removing blocks.
	'max': maximum number of blocks for the tail (0 is infinite)
	'ability-count': the current ammo for each ability
	'alive': whether the snake is active or dead
	'turned': set to true if an action is performed, set to false on update
	'region': the current worldguard region the snake is in
	'bot': the name of the bot, if a bot
	'target': the bot's current target location array
	'laser': timestamp when laser will stop firing, 0 if not firing
	'laser-blocks': the block locations that constitute this snake's laser
	'last-dir': cheap checks so bots can avoid looping in on themselves
	'sleep': how many ticks to sleep until updating
	'boost': boost speed multiplier
*/

proc _snake_add(@player, @game) {
	if(ponline(@player) && !_set_pactivity(@player, 'Snake')) {
		return(false);
	}

	@game['snakes'][@player] = array(
		'head': '',
		'tail': '',
		'color': color('white'),
		'bot': '',
	);

	if(!get_pscore('score', @player, 'snake')) {
		try {
			create_team(@player, 'snake');
			team_add_player(@player, @player, 'snake');
			set_pscore('score', @player, 0, 'snake');
		} catch(ScoreboardException @ex) {
			// team probably exists already, ignore
		}
	}

	@team = null;
	if(@game['mode'] == 'capture') {
		@team = rand(2);
		if(array_size(@game['teams'][0]) > array_size(@game['teams'][1])) {
			@team = 1;
		} else if(array_size(@game['teams'][0]) < array_size(@game['teams'][1])) {
			@team = 0;
		}
		@game['snakes'][@player]['team'] = @team;
		@game['teams'][@team][] = @player;
	} else if(ponline(@player)) {
		@item = pinv(@player, 7);
		if(@item && _is_snake_tail(@item['name'])) {
			_snake_set_color(@player, @item['name'], @game);
		}
	}

	@i = 10;
	while(!_snake_spawn(@player, @game)) {
		if(--@i <= 0) {
			if(@game['mode'] != 'endless') {
				array_remove(@game['snakes'], @player);
				remove_team(@player, 'snake');
				if(@game['mode'] == 'capture') {
					array_remove_values(@game['teams'][@team], @player);
				}
			}
			return(false);
		}
	}

	if(ponline(@player)) {
		@snake = @game['snakes'][@player];
		set_ploc(@player, location_shift(@snake['loc'], @snake['top'], 20));
		@yaw = get_yaw(ploc(@player), @snake['loc']);
		@pitch = get_pitch(ploc(@player), @snake['loc']);
		if(@yaw == NaN) {
			// probably directly above snake location
			@yaw = 0;
		}
		pfacing(@player, @yaw, @pitch);

		set_pscoreboard(@player, 'snake');
		set_pmode(@player, 'SURVIVAL');
		set_pflight(@player, true);
		set_pflying(@player, true);
		_set_pactivity(@player, 'Snake');
	} else {
		@game['snakes'][@player]['bot'] = @player;
	}

	return(true);
}

proc _snake_spawn(@player, @game) {
	@region = '';
	@startLoc = null;
	if(@game['mode'] == 'capture') {
		@region = @game['region'].(@game['snakes'][@player]['team'] * 2 + 2);
		@startLoc = _snake_valid_location(@region, 8);
	} else {
		@num = 0;
		while(@num++ < @game['surfaces']) {
			@region = @game['region'].@num;
			@found = false;
			foreach(@snake in @game['snakes']) {
				if(array_index_exists(@snake, 'region') && @snake['region'] == @region) {
					@found = true;
					break();
				}
			}
			if(!@found) {
				@startLoc = _snake_valid_location(@region, if(ponline(@player), 5, 1));
				if(@startLoc) {
					break();
				}
			}
		}
		if(@num > @game['surfaces']) {
			@region = @game['region'].rand(1, @game['surfaces'] + 1);
			@startLoc = _snake_valid_location(@region, if(ponline(@player), 5, 1));
		}
	}
	if(!@startLoc) {
		return(false);
	}
	@dir = _snake_direction_of(@startLoc, 'AIR');
	if(!@dir) {
		return(false);
	}
	@headLoc = _snake_shift(@startLoc, @dir);

	@snake = @game['snakes'][@player];
	@snake['ability-count'] = array(0, 0, 0, 0, 0);
	@snake['blocks'] = array(@startLoc, @headLoc);
	@snake['max'] = 0;
	@snake['loc'] = @headLoc;
	@snake['dir'] = @dir;
	@snake['region'] = @region;
	@snake['turned'] = false;
	@snake['alive'] = true;
	@snake['target'] = null;
	@snake['laser'] = 0;
	@snake['laser-blocks'] = null;
	@snake['last-dir'] = '';
	@snake['sleep'] = 5;
	@snake['boost'] = 0;

	_snake_set_top(@snake);

	if(ponline(@player) && @game['mode'] == 'capture' && @snake['tail']) {
		_clear_pinv(@player);
		set_pinv(@player, array(
			7: array('name': @snake['tail']),
			8: array('name': 'REDSTONE_TORCH', 'meta': associative_array('display': 'JOYSTICK')),
		));
	}
	return(true);
}

proc _snake_set_color(@player, @color, @game,
@colors = array(
	array('BLUE_TERRACOTTA', 'LIGHT_BLUE_TERRACOTTA', 'DARK_BLUE'), # blue
	array('BLUE_CONCRETE', 'LIGHT_BLUE_CONCRETE', 'BLUE'), # neon blue
	array('GREEN_TERRACOTTA', 'LIME_TERRACOTTA', 'DARK_GREEN'), # green
	array('GREEN_CONCRETE', 'LIME_CONCRETE', 'GREEN'), # neon green
	array('RED_TERRACOTTA', 'PINK_TERRACOTTA', 'DARK_RED'), # red
	array('RED_CONCRETE', 'PINK_CONCRETE', 'RED'), # neon pink
	array('PURPLE_TERRACOTTA', 'MAGENTA_TERRACOTTA', 'DARK_PURPLE'), # purple
	array('ORANGE_CONCRETE', 'YELLOW_CONCRETE', 'YELLOW'), # neon yellow
	array('LIGHT_GRAY_CONCRETE', 'WHITE_CONCRETE', 'WHITE'), # neon white
)) {
	@snake = @game['snakes'][@player];
	foreach(@slot: @colorArray in @colors) {
		if(@colorArray[1] == @color) {
			if(has_inventory('snake')) {
				set_inventory_item('snake', @slot, null);
			}
			@head = @colorArray[0];
			@tail = @colorArray[1];
			@text = @colorArray[2];
			@snake['head'] = @head;
			@snake['tail'] = @tail;
			@snake['color'] = color(@text);
			set_team_display(@player, array('color': @text), 'snake');
			break();
		}
	}
}

// Set colors for all snakes that do not have one set
proc _snake_set_colors(@game) {
	foreach(@name: @snake in @game['snakes']) {
		if(!@snake['head']) {
			@inv = get_inventory('snake');
			foreach(@slot in range(9)) {
				if(@inv[@slot] && (!array_index_exists(@snake, 'team') || integer(@slot / 4) == @snake['team'])) {
					@item = @inv[@slot]['name'];
					_snake_set_color(@name, @item, @game);
					break();
				}
			}
		}
		set_block(@snake['loc'], @snake['head'], false);
		set_block(@snake['blocks'][0], @snake['tail'], false);
		if(ponline(@name)) {
			_clear_pinv(@name);
			set_pinv(@name, array(
				7: array('name': @snake['tail']),
				8: array('name': 'REDSTONE_TORCH', 'meta': associative_array('display': 'JOYSTICK')),
			));
		}
	}
}

proc _snake_remove(@player, @game) {
	@snake = array_remove(@game['snakes'], @player);
	if(is_array(@snake)) {
		@snake['alive'] = false;
	}
	if(ponline(@player)) {
		set_pflight(@player, false);
		_equip_kit(@player, array(7: pinv(@player, 7)));
		_set_pactivity(@player, null);
	}
}

proc _snake_kill(@player, @game) {
	@snake = @game['snakes'][@player];
	if(!@snake['alive']) {
		return();
	}
	if(@snake['laser']) {
		_snake_clear_laser(@player, @game)
	}
	@snake['alive'] = false;
	if(@game['mode'] == 'endless') {
		@block = @snake['blocks'][-1];
		@blockType = get_block(@block);
		if(@blockType == @snake['head']) {
			set_block(@block, @snake['tail'], false);
			spawn_particle(@block, array('particle': 'SMOKE_NORMAL', 'count': 8, 'xoffset': 1, 'yoffset': 1, 'zoffset': 1));
		}
		foreach(@p: @s in @game['snakes']) {
			if(@s['alive']) {
				set_pscore('score', @p, get_pscore('score', @p, 'snake') + 1, 'snake');
			}
		}
	} else {
		for(@i = array_size(@snake['blocks']) - 1, @i >= 0, @i -= 3) {
			queue_push(closure(){
				@n = 0;
				while(@n < 3) {
					try {
						@block = @snake['blocks'][@i - @n];
						@blockType = get_block(@block);
						if(@blockType == @snake['tail']) {
							set_block(@block, if(@game['mode'] == 'capture' || @game['mode'] == 'gluttony', 'AIR', @snake['head']), false);
							spawn_particle(@block, array('particle': 'SMOKE_NORMAL', 'count': 8, 'xoffset': 1, 'yoffset': 1, 'zoffset': 1));
						}
						@n++;
					} catch(Exception @ex) {
						break();
					}
				}
			}, @player);
		}
		if(@game['mode'] == 'capture') {
			@otherteam = abs(@snake['team'] - 1);
			if(@game['flags'][@otherteam] == @player) {
				_snake_spawn_flag(@otherteam, @game);
			}
			queue_push(closure(){
				_snake_spawn(@player, @game);
			}, @player);
		}
	}
	play_sound(@snake['loc'], associative_array('sound': 'ENTITY_ZOMBIE_DEATH', 'pitch': 2, 'volume': 4));
}

proc _snake_set_top(@snake) {
	@snake['top'] = _snake_direction_of(@snake['loc'], 'BARRIER');
}

proc _snake_move(@player, @game) {
	@snake = @game['snakes'][@player];

	// Boost
	@snake['sleep'] = if(@game['mode'] == 'gluttony', 1,
		if(@game['botsOnly'], 
			if(@snake['boost'], 1, 2),
			max(1, 5 - @snake['boost'])))
	if(@snake['boost']) {
		@loc = @snake['loc'][];
		@loc[0] += 0.5;
		@loc[1] += 0.5;
		@loc[2] += 0.5;
		spawn_particle(@loc, array('particle': 'VILLAGER_HAPPY', 'count': 8, 'xoffset': 0.6, 'yoffset': 0.6, 'zoffset': 0.6,));
	}

	set_block(@snake['loc'], @snake['tail'], false);
	@snake['loc'] = _snake_shift(@snake['loc'], @snake['dir']);
	@block = get_block(@snake['loc']);
	@powerup = _snake_get_powerup_from(@block);

	// Air or pickup, move through
	if(@block == 'AIR'
	|| (@powerup && _snake_remove_powerup(@snake['loc'], @game))
	|| (@game['mode'] == 'capture' && (@block == 'CYAN_GLAZED_TERRACOTTA' || @block == 'RED_GLAZED_TERRACOTTA'))) {
		@snake['blocks'][] = @snake['loc'][];
		set_block(@snake['loc'], @snake['head'], false);
		if(_snake_powerup(@player, @powerup, @game)) {
			@snake['target'] = null;
		} else if(@game['mode'] == 'capture') {
			@team = @snake['team'];
			@otherteam = abs(@team - 1);
			if(_snake_loc_equals(@game['flags'][@team], @snake['loc'])) {
				if(@game['flags'][@otherteam] == @player) {
					// flag returned
					@score = get_pscore('score', @player, 'snake') + 1;
					set_pscore('score', @player, @score, 'snake');
					@teamname = if(@team, 'RED', 'BLUE');
					@teamscore = get_pscore('teamscore', @teamname, 'snake') + 1;
					set_pscore('teamscore', @teamname, @teamscore, 'snake');
					set_objective_display('score',
						color('red').get_pscore('teamscore', 'RED', 'snake').color('reset')
						.' : '.color('blue').get_pscore('teamscore', 'BLUE', 'snake'), 'snake');
					play_sound(@snake['loc'], array('sound': 'ENTITY_ZOMBIE_ATTACK_IRON_DOOR', 'volume': 4));
					if(@teamscore == 3) {
						_snake_end(@player, @game);
					} else {
						_snake_spawn_flag(@otherteam, @game);
					}
				}
				_snake_spawn_flag(@team, @game);
			} else if(_snake_loc_equals(@game['flags'][@otherteam], @snake['loc'])) {
				@game['flags'][@otherteam] = @player;
				play_sound(@snake['loc'], array('sound': 'ENTITY_ENDER_DRAGON_FLAP', 'pitch': 0, 'volume': 4));
			}
		}
		return(true);

	// Sea lantern, check for adjacent surface to move to
	} else if(@block == 'SEA_LANTERN') {
		@dir = _snake_dir_of_surface(@snake['loc'], _snake_opposite_dir(@snake['dir']));
		if(!@dir) {
			return(false);
		}
		@loc = _snake_shift(@snake['loc'], @dir);
		@block = get_block(@loc);
		@powerup = _snake_get_powerup_from(@block);
		if(@powerup && _snake_remove_powerup(@loc, @game) && _snake_powerup(@player, @powerup, @game)) {
			@snake['target'] = null;
		} else if(!(@block == 'AIR' || @block == 'RED_STAINED_GLASS' && @snake['laser'])) {
			return(false);
		}
		@snake['loc'] = @loc;
		@snake['dir'] = @dir;
		@snake['last-dir'] = @dir;
		@snake['blocks'][] = @snake['loc'][];
		set_block(@snake['loc'], @snake['head'], false);
		@snake['region'] = sk_regions_at(@snake['loc'])[1];
		_snake_set_top(@snake);
		return(true);

	// Laser, move through if snake is also shooting laser
	} else if(@block == 'RED_STAINED_GLASS' && @snake['laser']) {
		@snake['blocks'][] = @snake['loc'][];
		set_block(@snake['loc'], @snake['head'], false);
		@snake['turned'] = false;
		return(true);
	}

	// Hit non-traversable block, dead
	return(false);
}

proc _snake_turn(@top, @dir) {
	switch(@top) {
		case 'north':
			switch(@dir) {
				case 'east':
					return(array('down', 'up'));
				case 'west':
					return(array('up', 'down'));
				case 'up':
					return(array('east', 'west'));
				case 'down':
					return(array('west', 'east'));
			}

		case 'south':
			switch(@dir) {
				case 'east':
					return(array('up', 'down'));
				case 'west':
					return(array('down', 'up'));
				case 'up':
					return(array('west', 'east'));
				case 'down':
					return(array('east', 'west'));
			}

		case 'east':
			switch(@dir) {
				case 'north':
					return(array('up', 'down'));
				case 'south':
					return(array('down', 'up'));
				case 'up':
					return(array('south', 'north'));
				case 'down':
					return(array('north', 'south'));
			}

		case 'west':
			switch(@dir) {
				case 'north':
					return(array('down', 'up'));
				case 'south':
					return(array('up', 'down'));
				case 'up':
					return(array('north', 'south'));
				case 'down':
					return(array('south', 'north'));
			}

		case 'up':
			switch(@dir) {
				case 'north':
					return(array('west', 'east'));
				case 'south':
					return(array('east', 'west'));
				case 'east':
					return(array('north', 'south'));
				case 'west':
					return(array('south', 'north'));
			}


		case 'down':
			switch(@dir) {
				case 'north':
					return(array('east', 'west'));
				case 'south':
					return(array('west', 'east'));
				case 'east':
					return(array('south', 'north'));
				case 'west':
					return(array('north', 'south'));
			}

	}
	return(array('up', 'down'));
}
