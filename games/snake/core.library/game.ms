/*
	Game data

	'region': the region name, used to get sub region names for valid spawn locations
	'surfaces': the number of regions where valid spawn locations exist
	'snakes': an array of arrays of snake data for each player (see snake.ms)
	'powerups': an array of arrays of current powerups in the game
	'numPowerups': the number of powerups that can exist in the game at any given time
	'numPlayers': the number of snakes in the game
	'botsOnly': indicated if only bots are left in the game
	'missiles': an array of flying missiles
	'tnt': an array of primed tnt entities
	'mode': the game mode (elimination, versus, endless, capture)
	'nukes': an array of regions that are getting nuked
	'teams': an array of two arrays containing the list of players on that team
	'flags': an array of two location arrays or player names where the team flags are in capture mode
	'fire': an array of location arrays where decaying fire blocks are located
*/

include('util.ms');
include('powerups.ms');
include('snake.ms');
include('events.ms');
include('bot.ms');

proc _snake_queue(@mode) {
	// Default options
	@game = associative_array();
	@game['region'] = '';
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
	@game['fire'] = array();
	export('snake', @game);

	// Get arena
	foreach(@region in sk_current_regions()) {
		if(string_starts_with(@region, 'snake_')) {
			@game['region'] = @region;
			break();
		}
	}
	if(!@game['region']) {
		die(color('red').'Not in a snake region.');
	}

	// Get region count
	while(sk_region_exists('custom', @game['region'].(@game['surfaces'] + 1))) {
		@game['surfaces']++;
	}

	// Create scoreboard
	try {
		create_scoreboard('snake');
		create_objective('score', 'DUMMY', 'snake');
		@display = 'SNAKE: First to 2 wins!';
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
		'0': array('name': 'LIGHT_BLUE_TERRACOTTA', 'meta': array('display': 'Blue')),
		'1': array('name': 'LIGHT_BLUE_CONCRETE', 'meta': array('display': 'Neon Blue')),
		'2': array('name': 'LIME_TERRACOTTA', 'meta': array('display': 'Green')),
		'3': array('name': 'LIME_CONCRETE', 'meta': array('display': 'Neon Green')),
		'4': array('name': 'PINK_TERRACOTTA', 'meta': array('display': 'Red')),
		'5': array('name': 'PINK_CONCRETE', 'meta': array('display': 'Neon Pink')),
		'6': array('name': 'MAGENTA_TERRACOTTA', 'meta': array('display': 'Purple')),
		'7': array('name': 'YELLOW_CONCRETE', 'meta': array('display': 'Neon Yellow')),
		'8': array('name': 'WHITE_CONCRETE', 'meta': array('display': 'Neon White')),
	));

	// Add players in region
	if(@game['mode'] == 'capture') {
		@game['numPlayers'] = 8; // max
	}
	@loadMenu = false;
	foreach(@p in all_players()) {
		if(array_contains(sk_current_regions(@p), @game['region']) && pmode(@p) == 'ADVENTURE') {
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
					_snake_set_color(player(), @item['name'], @game);
					set_inventory_item('snake', @event['slot'], null);
					close_pinv();
				}
			}
		}
		bind('inventory_close', null, null, @event, @game) {
			set_timeout(1, closure() {
				if(has_inventory('snake') && !get_inventory_viewers('snake')) {
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
	// Start 
	@help = array(
		color('red').color('bold').'SNAKE: '.to_upper(@game['mode']),
		'Use '.color('green').'left and right mouse buttons'.color('reset').' to turn',
		'Press '.color('green').'slot #'.color('reset').' to activate pickup',
		color('green').color('italic').'Go snake, go!'
	);
	@secondsLeft = array(10);
	set_interval(1000, closure(){
		@secondsLeft[0]--;
		_snake_set_colors(@game);
		@title = if(@secondsLeft[0], @secondsLeft[0], '');
		@subtitle = array_get(@help, -ceil(@secondsLeft[0] / 3) - 1, '');
		foreach(@p in array_keys(@game['snakes'])) {
			if(!ponline(@p) || !array_contains(sk_current_regions(@p), @game['region'])) {
				continue();
			}
			title(@p, @title, @subtitle, 0, 25, 20);
			set_pheld_slot(@p, 8);
		}
		if(@secondsLeft[0] == 0) {
			if(!queue_running('snake_cleanup')) {
				clear_task();
				_snake_bind_events(@game);
				_snake_add_powerup(@game);
				_snake_start_task(@game);
			}
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
			try {
				if(!@snake['bot'] && (!ponline(@player) || !array_contains(sk_current_regions(@player), @game['region']))) {
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
				} else if(@game['mode'] == 'endless' && @snake['bot']) {
					@color = @snake['tail'];
					@abilities = @snake['ability-count'];
					if(_snake_add(@player, @game)) {
						_snake_set_color(@player, @color, @game); // keep color
						@game['snakes'][@player]['ability-count'] = @abilities; // keep abilities
					}
				}
			} catch (IndexOverflowException @ex) {
				console(@ex);
				_snake_remove(@player, @game);
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
		if(@game['fire']) {
			@r = rand(0, array_size(@game['fire']));
			set_block(@game['fire'][@r], 'AIR', false);
			array_remove(@game['fire'], @r);
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
		@endgame = false;
		if(@winner && @winner != 'No one') {
			@title = @game['snakes'][@winner]['color'].@winner.' wins ';
			set_pscore('score', @winner, get_pscore('score', @winner, 'snake') + 1, 'snake');
			if(get_pscore('score', @winner, 'snake') == 2) {
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
