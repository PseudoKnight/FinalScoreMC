/*
	Snake data

	'loc': current location
	'dir': current direction
	'top': relative direction for clockwise rotation (eg. north)
	'head': the block type:data for the color of their block
	'tail': the block type:data for the color of their tail
	'blocks': an array of ordered block locations representing the tail, new ones pushed on end, such that
			  order is back of tail to head. This is used for removing blocks.
	'ability-count': the current ammo for each ability
	'alive': whether the snake is active or dead
	'click': set to true if an action is performed, set to false on update
	'region': the current worldguard region the snake is in
	'bot': the name of the bot, if a bot
	'target': the bot's current target location array
	'laser': timestamp when laser will stop firing, 0 if not firing
	'last-dir': cheap checks so bots can avoid looping in on themselves
	'sleep': how many ticks to sleep until updating
	'boost': boost speed multiplier
*/

proc _snake_add(@player, @game) {
	if(ponline(@player) && !_set_pactivity(@player, 'SNAKE')) {
		return(false);
	}
	
	@num = 0;
	@region = '';
	while(@num++ < @game['surfaces']) {
		@region = 'snake_'.@game['arena'].@num;
		@found = false;
		foreach(@snake in @game['snakes']) {
			if(@snake['region'] == @region) {
				@found = true;
				break();
			}
		}
		if(!@found) {
			break();
		}
	}
	if(@num > @game['surfaces']) {
		@region = 'snake_'.@game['arena'].rand(1, @game['surfaces'] + 1);
	} else {
		@region = 'snake_'.@game['arena'].@num;
	}
	@startLoc = _snake_valid_location(@region, 5);
	if(!@startLoc) {
		return(false);
	}
	@dir = _snake_direction_of(@startLoc, '0:0');
	@headLoc = _relative(@startLoc, @dir);
	@game['snakes'][@player] = array(
		'blocks': array(@startLoc, @headLoc),
		'ability-count': array(0, 0, 0, 0, 0),
		'head': '',
		'tail': '',
		'color': color('white'),
		'alive': true,
		'loc': @headLoc,
		'dir': @dir,
		'click': false,
		'region': @region,
		'bot': '',
		'target': null,
		'laser': 0,
		'last-dir': '',
		'sleep': 5,
		'boost': 0,
	);
	_snake_set_top(@game['snakes'][@player]);
	
	if(!get_pscore('alive', @player, 'snake')) {
		create_team(@player, 'snake');
		team_add_player(@player, @player, 'snake');
		set_pscore('alive', @player, 1, 'snake');
	}

	if(ponline(@player)) {
		@item = pinv(@player, 7);
		if(@item && (@item['name'] == 'STAINED_CLAY' || @item['name'] == 'CONCRETE')) {
			_snake_set_color(@player, @item['type'].':'.@item['data'], @game);
		}
		set_pscoreboard(@player, 'snake');
		set_ploc(@player, _relative(@headLoc, @game['snakes'][@player]['top'], 20));
		@yaw = get_yaw(ploc(@player), @headLoc);
		@pitch = get_pitch(ploc(@player), @headLoc);
		pfacing(@player, @yaw, @pitch);
		set_pmode(@player, 'SURVIVAL');
		set_pflight(@player, true);
		set_pflying(@player, true);
		runas('~console', '/jukebox show add '.@player.' @snake');
		_set_pactivity(@player, 'SNAKE');
	} else {
		@game['snakes'][@player]['bot'] = @player;
	}
	return(true);
}

proc _snake_set_color(@player, @color, @game,
@colors = array(
	array('159:11', '159:3', '9'), # blue
	array('159:13', '159:5', '2'), # green
	array('159:14', '159:6', 'c'), # red
	array('159:10', '159:2', '5'), # purple
	array('251:11', '251:3', 'b'), # neon blue
	array('251:1', '251:4', 'e'), # neon yellow
	array('251:13', '251:5', 'a'), # neon green
	array('251:14', '251:6', 'd'), # neon pink
	array('251:8', '251:0', 'f'), # neon white
)) {
	@snake = @game['snakes'][@player];
	foreach(@slot: @colorArray in @colors) {
		if(@colorArray[1] == @color) {
			if(array_contains(all_virtualchests(), 'snake')) {
				clear_virtualchest('snake', @slot);
			}
			@head = @colorArray[0];
			@tail = @colorArray[1];
			@text = color(@colorArray[2]);
			@snake['head'] = @head;
			@snake['tail'] = @tail;
			@snake['color'] = @text;
			set_team_display(@player, associative_array('prefix': @text), 'snake');
			set_block_at(@snake['loc'], @head, false);
			set_block_at(@snake['blocks'][0], @tail, false);
			if(ponline(@player)) {
				_clear_pinv(@player);
				@block = split(':', @colorArray[1]);
				set_pinv(@player, array(
					7: array('type': @block[0], 'data': @block[1]),
					8: array('name': 'REDSTONE_TORCH_ON', 'meta': associative_array('display': 'JOYSTICK')),
				));
			}
			break();
		}
	}
}

// Set colors for all snakes that don't have one set
proc _snake_set_colors(@game) {
	foreach(@name: @snake in @game['snakes']) {
		if(!@snake['head']) {
			@inv = get_virtualchest('snake');
			foreach(@slot in range(@game['numPlayers'])) {
				if(@inv[@slot]) {
					@item = @inv[@slot]['type'].':'.@inv[@slot]['data'];
					_snake_set_color(@name, @item, @game);
					break();
				}
			}
		} else {
			set_block_at(@snake['loc'], @snake['head'], false);
			set_block_at(@snake['blocks'][0], @snake['tail'], false);
		}
	}
}

proc _snake_remove(@player, @game) {
	array_remove(@game['snakes'], @player);
	if(ponline(@player)) {
		runas('~console', '/jukebox show remove '.@player.' @snake');
		_equip_kit(@player, array(7: pinv(@player, 7)));
		_set_pactivity(@player, null);
	}
}

proc _snake_kill(@player, @game) {
	@snake = @game['snakes'][@player];
	if(!@snake['alive']) {
		return();
	}
	@snake['alive'] = false;
	if(@game['mode'] == 'endless') {
		@block = @snake['blocks'][-1];
		@blockType = get_block_at(@block);
		if(@blockType == @snake['head']) {
			set_block_at(@block, @snake['tail'], false);
			play_effect(@block, 'PARTICLE_SMOKE', associative_array('particleCount': 8, 'speed': 0, 'offsetX': 1, 'offsetY': 1, 'offsetZ': 1, 'radius': 40));
		}
		foreach(@p: @s in @game['snakes']) {
			if(@s['alive']) {
				set_pscore('alive', @p, get_pscore('alive', @p, 'snake') + 1, 'snake');
			}
		}
		if(@snake['bot']) {
			@color = @snake['tail'];
			@abilities = @snake['ability-count'];
			if(_snake_add(@player, @game)) {
				_snake_set_color(@player, @color, @game); // keep color
				@game['snakes'][@player]['ability-count'] = @abilities; // keep abilities
			} else {
				set_pscore('alive', @player, 0, 'snake');
			}
		}
	} else {
		set_pscore('alive', @player, 0, 'snake');
		for(@i = array_size(@snake['blocks']) - 1, @i >= 0, @i -= 3) {
			queue_push(closure(){
				@n = 0;
				while(@n < 3) {
					try {
						@block = @snake['blocks'][@i - @n];
						@blockType = get_block_at(@block);
						if(@blockType == @snake['tail']) {
							set_block_at(@block, @snake['head'], false);
							play_effect(@block, 'PARTICLE_SMOKE', associative_array('particleCount': 8, 'speed': 0, 'offsetX': 1, 'offsetY': 1, 'offsetZ': 1, 'radius': 40));
						}
						@n++;
					} catch(Exception @ex) {
						break();
					}
				}
			}, @player);
		}
	}
	play_sound(@snake['loc'], associative_array('sound': 'ZOMBIE_DEATH', 'pitch': 2, 'volume': 4));
}

proc _snake_set_top(@snake) {
	@snake['top'] = _snake_direction_of(@snake['loc'], '166:0');
}

proc _snake_update(@player, @game) {
	@snake = @game['snakes'][@player];
	
	// Boost
	@snake['sleep'] = if(@game['botsOnly'], if(@snake['boost'], 1, 2), max(1, 5 - @snake['boost']));
	if(@snake['boost']) {
		@loc = @snake['loc'][];
		@loc[0] += 0.5;
		@loc[1] += 0.5;
		@loc[2] += 0.5;
		play_effect(@loc, 'HAPPY_VILLAGER', associative_array('particleCount': 8, 'offsetX': 0.6, 'offsetY': 0.6, 'offsetZ': 0.6, 'radius': 40));
	}
	
	set_block_at(@snake['loc'], @snake['tail'], false);
	@snake['loc'] = _relative(@snake['loc'], @snake['dir']);
	@block = get_block_at(@snake['loc']);
	@powerup = _snake_get_powerup_from(split(':', @block)[0]);
	
	// Air or powerup, move through
	if(@block == '0:0' || (@powerup && _snake_remove_powerup(@snake['loc'], @game))) {
		@snake['blocks'][] = @snake['loc'][];
		set_block_at(@snake['loc'], @snake['head'], false);
		@snake['click'] = false;
		if(_snake_powerup(@player, @powerup, @game)) {
			@snake['target'] = null;
		}
		return(true);
		
	// Sea lantern, check for adjacent surface to move to
	} else if(@block == '169:0') {
		@dir = _snake_dir_of_surface(@snake['loc'], _snake_opposite_dir(@snake['dir']));
		if(!@dir) {
			return(false);
		}
		@loc = _relative(@snake['loc'], @dir);
		@powerup = _snake_get_powerup_from(get_block_at(@loc));
		if(@powerup && _snake_remove_powerup(@loc, @game) && _snake_powerup(@player, @powerup, @game)) {
			@snake['target'] = null;
		}
		@snake['loc'] = @loc;
		@snake['dir'] = @dir;
		@snake['last-dir'] = @dir;
		@snake['blocks'][] = @snake['loc'][];
		set_block_at(@snake['loc'], @snake['head'], false);
		@snake['click'] = false;
		@snake['region'] = sk_regions_at(@snake['loc'])[1];
		_snake_set_top(@snake);
		return(true);
		
	// Laser, move through if snake is also shooting laser
	} else if(@block == '95:14' && @snake['laser']) {
		@snake['blocks'][] = @snake['loc'][];
		set_block_at(@snake['loc'], @snake['head'], false);
		@snake['click'] = false;
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
}
