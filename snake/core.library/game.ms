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

proc _snake_queue(@mode) {
	// Default options
	@game = associative_array();
	@game['arena'] = '';
	@game['surfaces'] = 0;
	@game['snakes'] = associative_array();
	@game['powerups'] = array();
	@game['numPowerups'] = 15;
	@game['numPlayers'] = 9;
	@game['botsOnly'] = false;
	@game['missiles'] = associative_array();
	@game['tnt'] = array();
	@game['mode'] = @mode;
	@game['nukes'] = array();
	@game['teams'] = array(array(), array());
	@game['flags'] = array(null, null);
	export('snake', @game);

	// Get arena
	foreach(@region in sk_current_regions()) {
		if(string_starts_with(@region, 'snake_')) {
			@game['arena'] = substr(@region, 6);
			break();
		}
	}
	if(!@game['arena']) {
		die(color('red').'Not in a snake region.');
	}
	
	// Get region count
	while(sk_region_exists('custom', 'snake_'.@game['arena'].(@game['surfaces'] + 1))) {
		@game['surfaces']++;
	}

	// Create scoreboard
	try {
		create_scoreboard('snake');
		create_objective('score', 'DUMMY', 'snake');
		@display = 'SNAKE: First to 3!';
		if(@game['mode'] == 'endless') {
			@display = 'SNAKE: Survive!';
		} else if(@game['mode'] == 'capture') {
			create_objective('teamscore', 'DUMMY', 'snake');
			set_pscore('teamscore', 'BLUE', 0, 'snake');
			set_pscore('teamscore', 'RED', 0, 'snake');
			@display = color('red').'0'.color('reset').' : '.color('blue').'0';
		}
		set_objective_display('score', associative_array('displayname': @display, 'slot': 'SIDEBAR'), 'snake');
	} catch(ScoreboardException @ex) {
		die(color('red').'Snake is still running.');
	}
	
	_snake_clean_surfaces(@game);
	
	// Create color select menu
	create_virtual_inventory('snake', 9, color('bold').'Choose Your Snake Color', array(
		'0': array('name': 'STAINED_CLAY', 'data': 3, 'meta': array('display': 'Blue')),
		'1': array('name': 'CONCRETE', 'data': 3, 'meta': array('display': 'Neon Blue')),
		'2': array('name': 'STAINED_CLAY', 'data': 5, 'meta': array('display': 'Green')),
		'3': array('name': 'CONCRETE', 'data': 5, 'meta': array('display': 'Neon Green')),
		'4': array('name': 'STAINED_CLAY', 'data': 6, 'meta': array('display': 'Red')),
		'5': array('name': 'CONCRETE', 'data': 6, 'meta': array('display': 'Neon Pink')),
		'6': array('name': 'STAINED_CLAY', 'data': 2, 'meta': array('display': 'Purple')),
		'7': array('name': 'CONCRETE', 'data': 4, 'meta': array('display': 'Neon Yellow')),
		'8': array('name': 'CONCRETE', 'data': 0, 'meta': array('display': 'Neon White')),
	));

	// Add players in region
	if(@game['mode'] == 'capture') {
		@game['numPlayers'] = 8; // max
	}
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
	if(@game['mode'] == 'capture') {
		@loadMenu = false;
	}
	
	if(@game['mode'] == 'endless' && array_size(@game['snakes']) == 0
	|| @game['mode'] == 'versus' && array_size(@game['snakes']) < 2) {
		delete_virtual_inventory('snake');
		remove_scoreboard('snake');
		foreach(@player: @snake in @game['snakes']) {
			_snake_remove(@player, @game);
		}
		export('snake', null);
		die(color('red').'Not enough players in region in adventure mode.');
	}
	
	_add_activity('snake', 'Snake');

	// Add bots to fill up slots
	if(@game['mode'] != 'versus') {
		if(@game['mode'] == 'capture') {
			@game['numPlayers'] = array_size(@game['snakes']) + array_size(@game['snakes']) % 2; // min
		}
		@bots = _snake_bots();
		while(array_size(@game['snakes']) < @game['numPlayers'] && @bots) {
			@index = array_rand(@bots)[0];
			_snake_add(@bots[@index], @game);
			array_remove(@bots, @index);
		}
	}

	// Optionally open color select menu
	if(@loadMenu) {
		foreach(@player: @snake in @game['snakes']) {
			if(ponline(@player) && !@snake['head']) {
				popen_inventory(@player, 'snake');
			}
		}
		bind('inventory_click', array('id': 'snake-invclick'), array('virtual': true), @event, @game) {
			if(pinventory_holder(player()) == 'snake' && array_index_exists(@game['snakes'], player())) {
				@item = @event['slotitem'];
				if(@item) {
					_snake_set_color(player(), @item['type'].':'.@item['data'], @game);
					set_inventory_item('snake', @event['slot'], null);
					close_pinv();
				}
			}
		}
		bind('inventory_close', null, null, @event, @game) {
			set_timeout(50, closure() {
				if(array_contains(get_virtual_inventories(), 'snake') && !get_inventory_viewers('snake')) {
					unbind();
					unbind('snake-invclick');
					_snake_set_colors(@game);
					delete_virtual_inventory('snake');
					_snake_countdown(@game);
				}
			});
		}
	} else {
		_snake_set_colors(@game);
		delete_virtual_inventory('snake');
		_snake_countdown(@game);
	}
}

proc _snake_countdown(@game) {
	// Start countdown
	@help = array(
		'',
		'Press '.color('green').'slot #'.color('reset').' to activate pickup',
		'Press '.color('green').'slot #'.color('reset').' to activate pickup',
		'Press '.color('green').'slot #'.color('reset').' to activate pickup',
		'Use '.color('green').'left and right mouse buttons'.color('reset').' to turn',
		'Use '.color('green').'left and right mouse buttons'.color('reset').' to turn',
		'Use '.color('green').'left and right mouse buttons'.color('reset').' to turn',
		color('red').color('bold').'SNAKE: '.to_upper(@game['mode']),
	);
	@countdown = array(8);
	set_interval(1000, closure(){
		_snake_set_colors(@game);
		foreach(@p in array_keys(@game['snakes'])) {
			if(!ponline(@p)) {
				continue();
			}
			if(@countdown[0]) {
				title(@p, @countdown[0], array_get(@help, @countdown[0], ''), 0, 25, 0);
			} else {
				title(@p, '', color('green').color('italic').'Go snake, go!', 0, 20, 20);
			}
			set_pheld_slot(@p, 8);
		}
		if(@countdown[0] == 6) {
			_snake_play_song(@game);
		}
		if(@countdown[0] == 0) {
			if(!queue_running('snake_cleanup')) {
				clear_task();
				_snake_bind_events(@game);
				_snake_add_powerup(@game);
				_snake_start_task(@game);
			}
		} else {
			@countdown[0] -= 1;
		}
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
			} else if(@snake['alive']) {
				if(!@snake['bot']) {
					@playersAlive++;
				}
				if(!(@snake['sleep']--)) {
					if(@snake['bot']) {
						_snake_bot_update(@player, @game);
					}
					if(_snake_move(@player, @game)) {
						if(@snake['laser']) {
							_snake_update_laser(@player, @game);
						}
						@snake['turned'] = false;
						@alive++;
						@active = @player;
					} else {
						_snake_kill(@player, @game);
					}
				} else {
					@alive++;
					@active = @player;
				}
			}
		}
		if(@game['mode'] == 'capture') {
			foreach(@team: @flag in @game['flags']){
				if(!@flag) {
					_snake_spawn_flag(@team, @game);
				}
			}
		}
		if(@game['mode'] != 'capture' && (!@playersAlive || !@alive)) {
			if(@game['mode'] == 'endless' || !@alive) {
				_snake_end(null, @game);
			} else {
				@game['botsOnly'] = true;
			}
		}
		if(@alive < 2) {
			_snake_end(@active, @game);
		}
	});
}

proc _snake_end(@winner, @game) {
	if(@game['mode'] == 'capture') {
		if(@winner != 'No one') {
			@team = @game['snakes'][@winner]['team'];
			foreach(@player in array_keys(@game['snakes'])) {
				if(ponline(@player)) {
					title(@player, '', @winner.' won the game for team '.if(@team, color('red').'RED', color('blue').'BLUE'), 40, 80, 40);
				}
			}
		}
		_snake_cleanup(@game);
	} else if(@game['mode'] == 'versus' || @game['mode'] == 'elimination') {
		if(array_size(@game['snakes'][@winner]['blocks']) == 2) {
			console(@game);
		}
		@endgame = false;
		if(@winner && @winner != 'No one') {
			@title = @game['snakes'][@winner]['color'].@winner.' wins ';
			set_pscore('score', @winner, get_pscore('score', @winner, 'snake') + 1, 'snake');
			if(get_pscore('score', @winner, 'snake') == 3) {
				@endgame = true;
				@title .= 'the game!';
			} else {
				@title .= 'this round!';
			}
			foreach(@player in array_keys(@game['snakes'])) {
				if(ponline(@player)) {
					title(@player, '', @title, 40, 80, 40);
				}
			}
		} else {
			@endgame = true;
		}
		
		if(@endgame) {
			_snake_cleanup(@game);
		} else {
			_snake_clean_surfaces(@game);
			_snake_cleanup_round(@game);
			foreach(@player: @snake in @game['snakes']) {
				_snake_spawn(@player, @game);
			}
			_snake_countdown(@game);
		}
		
	} else if(@game['mode'] == 'endless') {
		// Sort player scores
		@scores = array();
		foreach(@p: @snake in @game['snakes']) {
			if(ponline(@p)) {
				@pscore = get_pscore('score', @p, 'snake');
				@array = array('name': @p, 'value': @pscore, 'highscore': false, 'topscore': false);
				foreach(@i: @score in @scores) {
					if(@pscore > @score['value']) {
						array_insert(@scores, @array, @i);
						break();
					} else if(@i == array_size(@scores) - 1) {
						@scores[] = @array;
					}
				} else {
					@scores[] = @array;
				}
			}
		}
		
		// Store and set highscores and topscores
		@topscores = get_value('snake.endless.top');
		if(!@topscores) {
			@topscores = array();
		}
		@updateTopScores = false;
		foreach(@score in @scores) {
			@uuid = puuid(@score['name'], true);
			@pscore = get_value('snake.endless', @uuid);
			if(!@pscore || @score['value'] > @pscore) {
				store_value('snake.endless', @uuid, @score['value']);
				@score['highscore'] = true;
				
				@coins = @score['value'] - @pscore;
				_acc_add(@score['name'], @coins);
				tmsg(@score['name'], color('gold').'+'.@coins.' coins');
				
				@array = array('uuid': @uuid, 'value': @score['value']);
				@remove = false;
				foreach(@i: @topscore in @topscores) {
					if(@topscore['uuid'] == @uuid) {
						if(@remove) {
							array_remove(@topscores, @i);
						} else {
							@topscores[@i] = @array;
							@score['topscore'] = true;
						}
						break();
					} else if(@remove) {
						continue();
					}
					if(@score['value'] > @topscore['value']) {
						array_insert(@topscores, @array, @i);
						@score['topscore'] = true;
						@remove = true;
					} else if(@i == array_size(@topscores) - 1) {
						@topscores[] = @array;
						@score['topscore'] = true;
					}
				} else {
					@topscores[] = @array;
					@score['topscore'] = true;
				}
				if(@score['topscore']) {
					@updateTopScores = true;
				}
			}
		}
		if(@updateTopScores) {
			store_value('snake.endless.top', @topscores);
		}
		
		// Display scores
		if(@scores) {
			@topPlayer = @scores[0]['name'];
			@title = '['.@scores[0]['value'].'] '.@game['snakes'][@topPlayer]['color'].@topPlayer
					.if(@scores[0]['topscore'], color('bold').' TOPSCORE!', if(@scores[0]['highscore'], color('bold').' HIGHSCORE!'));
			@subtitle = '';
			if(array_size(@scores) > 1) {
				@secondPlayer = @scores[1]['name'];
				@subtitle = '['.@scores[1]['value'].'] '.@game['snakes'][@secondPlayer]['color'].@secondPlayer
						.if(@scores[1]['topscore'], color('bold').' TOPSCORE!', if(@scores[1]['highscore'], color('bold').' HIGHSCORE!'));
			}
			foreach(@player in array_keys(@game['snakes'])) {
				if(ponline(@player)) {
					title(@player, @title, @subtitle, 40, 80, 40);
				}
			}
		}
		_snake_cleanup(@game);
	}
}

proc _snake_cleanup_round(@game) {
	@game['botsOnly'] = false;
	@game['powerups'] = array();
	@game['missiles'] = associative_array();
	@game['tnt'] = array();
	@game['nukes'] = array();
	_snake_unbind_events();
	_snake_stop_song();
	if(array_index_exists(@game, 'interval')) {
		clear_task(@game['interval']);
	}
}

proc _snake_cleanup(@game) {
	_snake_cleanup_round(@game);
	delete_virtual_inventory('snake');
	set_timeout(7000, closure(){
		foreach(@player: @snake in @game['snakes']) {
			_snake_remove(@player, @game);
		}
		export('snake', null);
		remove_scoreboard('snake');
		_remove_activity('snake');
	});
}
