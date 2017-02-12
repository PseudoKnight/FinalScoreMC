/*
	Snake data

	'loc': current location
	'dir': current direction
	'top': relative direction for clockwise rotation (eg. north)
	'head': the block type:data for the color of their block
	'tail': the block type:data for the color of their tail
	'blocks': an array of ordered block locations representing the tail, new ones pushed on end, such that
			  order is back of tail to head. This is used for removing blocks.
	'ability': a powerup abilities
	'ability-count': the current ammo for each ability
	'alive': whether the snake is active or dead
	'click': set to true if an action is performed, set to false on update
	'region': the current worldguard region the snake is in
	'bot': the name of the bot, if a bot
	'target': the bot's current target location array
	'laser-immune': whether or not a snake can pass through a laser (set to true when firing a laser)
	'last-dir': cheap checks so bots can avoid looping in on themselves
	'sleep': how many ticks to sleep until updating
	'boost': boost speed multiplier
*/

proc _snake_add(@player, @game) {
	@colors = array(
		array('159:11', '159:3', '9'), # blue
		array('159:1', '159:4', '6'), # orange
		array('159:13', '159:5', 'a'), # green
		array('159:14', '159:6', 'c'), # red
		array('159:8', '159:0', 'f'), # white
		array('159:10', '159:2', 'd'), # purple
		array('159:15', '159:7', '8'), # black
	);
	@region = 'snake_'.@game['arena'].rand(1, @game['surfaces'] + 1);
	@startLoc = _snake_valid_location(@region, 4);
	if(!@startLoc) {
		return();
	}
	@dir = _snake_direction_of(@startLoc, '0:0');
	@headLoc = _relative(@startLoc, @dir);
	@head = @colors[array_size(@game['snakes'])][0];
	@tail = @colors[array_size(@game['snakes'])][1];
	@color = @colors[array_size(@game['snakes'])][2];
	@game['snakes'][@player] = associative_array(
		'blocks': array(@startLoc, @headLoc),
		'ability': array('', ''),
		'ability-count': array(0, 0),
		'head': @head,
		'tail': @tail,
		'alive': true,
		'loc': @headLoc,
		'dir': @dir,
		'click': false,
		'region': @region,
		'bot': '',
		'target': null,
		'laser-immune': false,
		'last-dir': '',
		'sleep': 5,
		'boost': 0,
	);
	set_block_at(@headLoc, @head, false);
	set_block_at(@startLoc, @tail, false);
	_snake_set_top(@game['snakes'][@player]);

	create_team(@player, 'snake');
	set_team_display(@player, associative_array('prefix': color(@color)), 'snake');
	team_add_player(@player, @player, 'snake');
	set_pscore('alive', @player, 1, 'snake');

	if(ponline(@player) && _set_pstate_activity(@player, 'SNAKE')) {
		set_pscoreboard(@player, 'snake');
		set_ploc(@player, _relative(@headLoc, @game['snakes'][@player]['top'], 20));
		@yaw = get_yaw(ploc(@player), @headLoc);
		@pitch = get_pitch(ploc(@player), @headLoc);
		pfacing(@player, @yaw, @pitch);
		set_pmode(@player, 'SURVIVAL');
		set_pflight(@player, true);
		set_pflying(@player, true);
		_clear_pinv(@player);
		set_pinv(@player, associative_array(
			-106: associative_array(
				'name': 'STICK',
				'meta': associative_array('display': 'JOYSTICK'),
			),
		));
		set_pheld_slot(@player, 0);
		_set_pstate_activity(@player, 'SNAKE');
	} else {
		@game['snakes'][@player]['bot'] = @player;
	}
}

proc _snake_remove(@player, @game) {
	foreach(@block in @game['snakes'][@player]['blocks']) {
		set_block_at(@block, 0, false);
	}
	array_remove(@game['snakes'], @player);
	if(ponline(@player)) {
		_equip_kit(@player);
		_set_pstate_activity(@player, null);
	}
}

proc _snake_kill(@player, @game) {
	@snake = @game['snakes'][@player];
	for(@i = array_size(@snake['blocks']) - 1, @i >= 0, @i -= 3) {
		queue_push(closure(){
			@n = 0;
			while(@n < 3) {
				try {
					@block = @snake['blocks'][@i - @n];
					if(get_block_at(@block) == @snake['tail']) {
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
	@snake['alive'] = false;
	set_pscore('alive', @player, 0, 'snake');
	play_sound(@snake['loc'], associative_array('sound': 'ZOMBIE_DEATH', 'pitch': 2, 'volume': 3));
}

proc _snake_set_top(@snake) {
	@snake['top'] = _snake_direction_of(@snake['loc'], '166:0');
}

proc _snake_update(@player, @game) {
	@snake = @game['snakes'][@player];
	@snake['sleep'] = if(@game['botsOnly'], if(@snake['boost'], 1, 2), max(1, 5 - @snake['boost']));
	set_block_at(@snake['loc'], @snake['tail'], false);
	if(@snake['boost']) {
		@loc = @snake['loc'][];
		@loc[0] += 0.5;
		@loc[1] += 0.5;
		@loc[2] += 0.5;
		play_effect(@loc, 'HAPPY_VILLAGER', associative_array('particleCount': 8, 'offsetX': 0.6, 'offsetY': 0.6, 'offsetZ': 0.6, 'radius': 40));
	}
	@snake['loc'] = _relative(@snake['loc'], @snake['dir']);
	@block = get_block_at(@snake['loc']);
	@powerup = _snake_get_powerup_from(split(':', @block)[0]);
	if(@block == '0:0' || (@powerup && _snake_remove_powerup(@snake['loc'], @game))) {
		@snake['blocks'][] = @snake['loc'][];
		set_block_at(@snake['loc'], @snake['head'], false);
		@snake['click'] = false;
		if(_snake_powerup(@player, @powerup, @game)) {
			@snake['target'] = null;
		}
		return(true);
	} else if(@block == '169:0') {
		@dir = '';
		@loc = null;
		foreach(@d in array('down', 'up', 'north', 'south', 'east', 'west')) {
			if(@d != @snake['dir']) {
				@loc = _relative(@snake['loc'], @d);
				@block = get_block_at(@loc);
				if(@block == '0:0' || (@powerup = _snake_get_powerup_from(@block))) {
					@dir = @d;
					break();
				}
			}
		}
		if(!@dir) {
			return(false);
		}
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
	} else if(@block == '95:14' && @snake['laser-immune']) {
		@snake['blocks'][] = @snake['loc'][];
		set_block_at(@snake['loc'], @snake['head'], false);
		@snake['click'] = false;
		return(true);
	}
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
