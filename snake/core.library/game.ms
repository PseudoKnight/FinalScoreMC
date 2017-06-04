/*
	Game data

	'arena': the arena name, used to get region names for valid spawn locations
	'surfaces': the number of regions where valid spawn locations exist
	'snakes': an array of arrays of snake data for each player (see snake.ms)
	'powerups': an array of arrays of current powerups in the game
	'speed': a game option that controls the interval frequency (how often the snakes update)
	'numPowerups': the number of powerups that can exist in the game at any given time
	'extraBlocks': extraneous obstacle blocks to clean-up
	'numPlayers': the number of snakes in the game
	'botsOnly': indicated if only bots are left in the game
	'missiles': an array of flying missiles
	'tnt': an array of primed tnt entities
*/

include('util.ms');
include('powerups.ms');
include('snake.ms');
include('events.ms');
include('bot.ms');

proc _snake_queue(@args) {
	// Default options
	@game = associative_array();
	@game['arena'] = '';
	@game['surfaces'] = 0;
	@game['snakes'] = associative_array();
	@game['powerups'] = array();
	@game['extraBlocks'] = array();
	@game['numPowerups'] = 15;
	@game['numPlayers'] = 7
	@game['botsOnly'] = false;
	@game['missiles'] = associative_array();
	@game['tnt'] = array();
	export('snake', @game);

	// Command options
	if(pisop()) {
		foreach(@arg in @args) {
			@split = split(':', @arg);
			if(array_size(@split) < 2) {
				die('Invalid setting: '.@arg);
			}
			@key = @split[0];
			@value = @split[1];
			@game[@key] = @value;
		}
	}
	
	// Get arena
	foreach(@region in sk_current_regions()) {
		if(string_starts_with(@region, 'snake_')) {
			@game['arena'] = substr(@region, 6);
			break();
		}
	}
	if(!@game['arena']) {
		die('Not in a snake region.');
	}
	
	// Get region count
	while(sk_region_exists('custom', 'snake_'.@game['arena'].(@game['surfaces'] + 1))) {
		@game['surfaces']++;
	}

	// Create scoreboard
    try {
    	create_scoreboard('snake');
    	create_objective('alive', 'DUMMY', 'snake');
    	set_objective_display('alive', associative_array('displayname': 'SNAKE', 'slot': 'SIDEBAR'), 'snake');
    } catch(ScoreboardException @ex) {
        die('Snake is still running.');
    }
	
	// Create color select menu
	create_virtualchest(array(
		'id': 'snake',
		'size': 9,
		'title': 'Choose your color',
		'0': array('name': 'STAINED_CLAY', 'data': 11),
		'1': array('name': 'STAINED_CLAY', 'data': 1),
		'2': array('name': 'STAINED_CLAY', 'data': 13),
		'3': array('name': 'STAINED_CLAY', 'data': 14),
		'4': array('name': 'STAINED_CLAY', 'data': 8),
		'5': array('name': 'STAINED_CLAY', 'data': 10),
		'6': array('name': 'STAINED_CLAY', 'data': 15),
	));

	// Add players in region
	@loadMenu = false;
	foreach(@p in all_players()) {
		if(array_contains(sk_current_regions(@p), 'snake_'.@game['arena']) && pmode(@p) == 'ADVENTURE') {
			if(_snake_add(@p, @game) && !@game['snakes'][@p]['head']) {
				@loadMenu = true;
			}
		}
		if(array_size(@game['snakes']) == @game['numPlayers']) {
			break();
		}
	}

	@bots = array('Grumpy','BatSnake','SharkBot','CrazyBot');
	while(array_size(@game['snakes']) < @game['numPlayers'] && @bots) {
		@index = array_rand(@bots)[0];
		_snake_add(@bots[@index], @game);
		array_remove(@bots, @index);
	}

	// Optionally open color select menu
	if(@loadMenu) {
		foreach(@player: @snake in @game['snakes']) {
			if(ponline(@player) && !@snake['head']) {
				popen_virtualchest(@player, 'snake');
			}
		}
		bind(inventory_click, array('id': 'snake-invclick'), null, @event, @game) {
			if(pget_virtualchest(player()) == 'snake' && array_index_exists(@game['snakes'], player())) {
				@item = @event['slotitem'];
				if(@item) {
					_snake_set_color(player(), @item['data'], @game);
					clear_virtualchest('snake', @event['slot']);
					close_pinv();
				}
			}
		}
		bind(inventory_close, null, null, @event, @game) {
			set_timeout(50, closure() {
				if(!pviewing_virtualchest('snake')) {
					unbind();
					unbind('snake-invclick');
					_snake_set_colors(@game);
					del_virtualchest('snake');
					_snake_countdown(@game);
				}
			});
		}
	} else {
		_snake_set_colors(@game);
		del_virtualchest('snake');
		_snake_countdown(@game);
	}
}

proc _snake_countdown(@game) {
	// Start countdown
	@help = array(
		'',
		'Press slot # to activate ability',
		'Press slot # to activate ability',
		'Press slot # to activate ability',
		'To turn, click left or right mouse buttons',
		'To turn, click left or right mouse buttons',
		'To turn, click left or right mouse buttons',
		'SNAKE',
	);
	@countdown = array(7);
	set_interval(1000, closure(){
		foreach(@p in array_keys(@game['snakes'])) {
			if(!ponline(@p)) {
				continue();
			}
			if(@countdown[0]) {
				title_msg(@p, @countdown[0], array_get(@help, @countdown[0], ''), 0, 25, 0);
			} else {
				title_msg(@p, '', color('italic').'Go snake, go!', 0, 20, 20);
			}
			set_pheld_slot(@p, 8);
		}
		if(@countdown[0] == 6) {
			_snake_play_song(@game);
		}
		if(@countdown[0] == 0) {
			clear_task();
			_snake_bind_events(@game);
			_snake_add_powerup(@game);
			_snake_start_task(@game);
			_add_activity('snake', 'Snake');
		}
		@countdown[0] -= 1;
	});
}

proc _snake_start_task(@game) {
	@game['interval'] = set_interval(50, closure() {
		@alive = 0;
		@active = 'No one';
		@playersAlive = 0;
		while(array_size(@game['powerups']) < @game['numPowerups']) {
			_snake_add_powerup(@game);
		}
		foreach(@player: @snake in @game['snakes']) {
			if(!@snake['bot'] && (!ponline(@player) || !array_contains(sk_current_regions(@player), 'snake_'.@game['arena']))) {
				_snake_remove(@player, @game);
				continue();
			}
			if(@snake['alive']) {
				if(!(@snake['sleep']--)) {
					if(@snake['bot']) {
						_snake_bot_update(@player, @game);
					} else {
						@playersAlive++;
					}
					if(_snake_update(@player, @game)) {
						@alive++;
						@active = @player;
					} else {
						_snake_kill(@player, @game);
					}
				} else {
					if(!@snake['bot']) {
						@playersAlive++;
					}
					@alive++;
					@active = @player;
				}
			}
		}
		if(@playersAlive == 0) {
			@game['botsOnly'] = true;
		}
		if((@alive < 2 && array_size(@game['snakes']) > 1) || @alive < 1) {
			clear_task();
			_snake_end(@active, @game);
		}
	});
}

proc _snake_end(@winner, @game) {
	foreach(@player in array_keys(@game['snakes'])) {
		if(ponline(@player)) {
			title_msg(@player, @winner.' wins!', '', 20, 60, 20);
		}
	}
	_snake_unbind_events();
	_snake_stop_song();
	set_timeout(3000, closure(){
		foreach(@player: @snake in @game['snakes']) {
			_snake_remove(@player, @game);
		}
		_snake_remove_all_powerups(@game);
		foreach(@loc in @game['extraBlocks']) {
			set_block_at(@loc, 0, false);
		}
		export('snake', null);
		remove_scoreboard('snake');
		_remove_activity('snake');
	});
}
