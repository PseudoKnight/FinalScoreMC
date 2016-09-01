/*
	Snake data

	'loc': current location
	'dir': current direction
	'top': relative direction for clockwise rotation (eg. north)
	'head': the block type:data for the color of their block
	'tail': the block type:data for the color of their tail
	'blocks': an array of ordered block locations representing the tail, new ones pushed on end, such that
			  order is back of tail to head. This is used for removing blocks.
	'ability': a powerup ability
	'ability-count': the current ammo (used for bots)
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
		'ability': '',
		'ability-count': 0,
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

	if(ponline(@player)) {
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
	} else {
		@game['snakes'][@player]['bot'] = @player;
	}
}

proc _snake_remove(@player, @game) {
	foreach(@block in @game['snakes'][@player]['blocks']) {
		set_block_at(@block, 0, false);
	}
	array_remove(@game['snakes'], @player);
	if(ponline(@player) && pworld(@player) == 'custom') {
		_equip_kit(@player);
	}
}

proc _snake_kill(@player, @game) {
	@snake = @game['snakes'][@player];
	foreach(@block in @snake['blocks']) {
		set_block_at(@block, @snake['head'], false);
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
	@snake['sleep'] = max(1, 5 - @snake['boost']);
	set_block_at(@snake['loc'], @snake['tail'], false);
	if(@snake['boost']) {
		play_effect(@snake['loc'], 'HAPPY_VILLAGER', associative_array('particleCount': 8, 'offsetX': 0.6, 'offsetY': 0.6, 'offsetZ': 0.6, 'radius': 40));
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
		@snake['blocks'][] = @snake['loc'][];
		set_block_at(@snake['loc'], @snake['head'], false);
		@snake['click'] = false;
		@snake['region'] = sk_regions_at(@snake['loc'])[1];
		@snake['target'] = null;
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

proc _snake_turn(@rotation, @snake) {
	if(@snake['click']) {
		return();
	}
	@snake['click'] = true;
	switch(@snake['top']) {
		case 'north':
			switch(@snake['dir']) {
				case 'east':
					if(@rotation == 'right') {
						@snake['dir'] = 'up';
					} else {
						@snake['dir'] = 'down';
					}

				case 'west':
					if(@rotation == 'right') {
						@snake['dir'] = 'down';
					} else {
						@snake['dir'] = 'up';
					}

				case 'up':
					if(@rotation == 'right') {
						@snake['dir'] = 'west';
					} else {
						@snake['dir'] = 'east';
					}

				case 'down':
					if(@rotation == 'right') {
						@snake['dir'] = 'east';
					} else {
						@snake['dir'] = 'west';
					}
			}

		case 'south':
			switch(@snake['dir']) {
				case 'east':
					if(@rotation == 'right') {
						@snake['dir'] = 'down';
					} else {
						@snake['dir'] = 'up';
					}

				case 'west':
					if(@rotation == 'right') {
						@snake['dir'] = 'up';
					} else {
						@snake['dir'] = 'down';
					}

				case 'up':
					if(@rotation == 'right') {
						@snake['dir'] = 'east';
					} else {
						@snake['dir'] = 'west';
					}

				case 'down':
					if(@rotation == 'right') {
						@snake['dir'] = 'west';
					} else {
						@snake['dir'] = 'east';
					}
			}

		case 'east':
			switch(@snake['dir']) {
				case 'north':
					if(@rotation == 'right') {
						@snake['dir'] = 'down';
					} else {
						@snake['dir'] = 'up';
					}

				case 'south':
					if(@rotation == 'right') {
						@snake['dir'] = 'up';
					} else {
						@snake['dir'] = 'down';
					}

				case 'up':
					if(@rotation == 'right') {
						@snake['dir'] = 'north';
					} else {
						@snake['dir'] = 'south';
					}

				case 'down':
					if(@rotation == 'right') {
						@snake['dir'] = 'south';
					} else {
						@snake['dir'] = 'north';
					}
			}

		case 'west':
			switch(@snake['dir']) {
				case 'north':
					if(@rotation == 'right') {
						@snake['dir'] = 'up';
					} else {
						@snake['dir'] = 'down';
					}

				case 'south':
					if(@rotation == 'right') {
						@snake['dir'] = 'down';
					} else {
						@snake['dir'] = 'up';
					}

				case 'up':
					if(@rotation == 'right') {
						@snake['dir'] = 'south';
					} else {
						@snake['dir'] = 'north';
					}

				case 'down':
					if(@rotation == 'right') {
						@snake['dir'] = 'north';
					} else {
						@snake['dir'] = 'south';
					}
			}

		case 'up':
			switch(@snake['dir']) {
				case 'north':
					if(@rotation == 'right') {
						@snake['dir'] = 'east';
					} else {
						@snake['dir'] = 'west';
					}

				case 'south':
					if(@rotation == 'right') {
						@snake['dir'] = 'west';
					} else {
						@snake['dir'] = 'east';
					}

				case 'east':
					if(@rotation == 'right') {
						@snake['dir'] = 'south';
					} else {
						@snake['dir'] = 'north';
					}

				case 'west':
					if(@rotation == 'right') {
						@snake['dir'] = 'north';
					} else {
						@snake['dir'] = 'south';
					}
			}


		case 'down':
			switch(@snake['dir']) {
				case 'north':
					if(@rotation == 'right') {
						@snake['dir'] = 'west';
					} else {
						@snake['dir'] = 'east';
					}

				case 'south':
					if(@rotation == 'right') {
						@snake['dir'] = 'east';
					} else {
						@snake['dir'] = 'west';
					}

				case 'east':
					if(@rotation == 'right') {
						@snake['dir'] = 'north';
					} else {
						@snake['dir'] = 'south';
					}

				case 'west':
					if(@rotation == 'right') {
						@snake['dir'] = 'south';
					} else {
						@snake['dir'] = 'north';
					}
			}

	}
}
