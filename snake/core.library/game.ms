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
	@game['endless'] = (@mode == 'endless');
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
    	create_objective('alive', 'DUMMY', 'snake');
    	set_objective_display('alive', associative_array('displayname': 'SNAKE', 'slot': 'SIDEBAR'), 'snake');
    } catch(ScoreboardException @ex) {
        die(color('red').'Snake is still running.');
    }
	
	_snake_clean_surfaces(@game['arena'], @game['surfaces']);
	
	// Create color select menu
	create_virtualchest(array(
		'id': 'snake',
		'size': 9,
		'title': color('bold').'Choose Your Snake Color',
		'0': array('name': 'STAINED_CLAY', 'data': 3, 'meta': array('display': 'Blue')),
		'1': array('name': 'STAINED_CLAY', 'data': 5, 'meta': array('display': 'Green')),
		'2': array('name': 'STAINED_CLAY', 'data': 6, 'meta': array('display': 'Red')),
		'3': array('name': 'STAINED_CLAY', 'data': 2, 'meta': array('display': 'Purple')),
		'4': array('name': 'CONCRETE', 'data': 3, 'meta': array('display': 'Neon Blue')),
		'5': array('name': 'CONCRETE', 'data': 4, 'meta': array('display': 'Neon Yellow')),
		'6': array('name': 'CONCRETE', 'data': 5, 'meta': array('display': 'Neon Green')),
		'7': array('name': 'CONCRETE', 'data': 6, 'meta': array('display': 'Neon Pink')),
		'8': array('name': 'CONCRETE', 'data': 0, 'meta': array('display': 'Neon White')),
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
	if(@game['endless'] && array_size(@game['snakes']) == 0) {
		del_virtualchest('snake');
		remove_scoreboard('snake');
		export('snake', null);
		die(color('red').'No players in region in adventure mode.');
	}

	// Add bots to fill up slots
	@bots = _snake_bots();
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
					_snake_set_color(player(), @item['type'].':'.@item['data'], @game);
					clear_virtualchest('snake', @event['slot']);
					close_pinv();
				}
			}
		}
		bind(inventory_close, null, null, @event, @game) {
			set_timeout(50, closure() {
				if(array_contains(all_virtualchests(), 'snake') && !pviewing_virtualchest('snake')) {
					unbind();
					unbind('snake-invclick');
					queue_push(closure(){
						_snake_set_colors(@game);
						del_virtualchest('snake');
						_snake_countdown(@game);
					}, 'snake_cleanup');
				}
			});
		}
	} else {
		queue_push(closure(){
			_snake_set_colors(@game);
			del_virtualchest('snake');
			_snake_countdown(@game);
		}, 'snake_cleanup');
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
		color('red').color('bold').'SNAKE',
	);
	@countdown = array(8);
	set_interval(1000, closure(){
		foreach(@p in array_keys(@game['snakes'])) {
			if(!ponline(@p)) {
				continue();
			}
			if(@countdown[0]) {
				title_msg(@p, @countdown[0], array_get(@help, @countdown[0], ''), 0, 25, 0);
			} else {
				title_msg(@p, '', color('green').color('italic').'Go snake, go!', 0, 20, 20);
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
			if(@game['endless']) {
				_snake_end(null, @game);
			}
		}
		if((@alive < 2 && array_size(@game['snakes']) > 1) || @alive < 1) {
			_snake_end(@active, @game);
		}
	});
}

proc _snake_end(@winner, @game) {
	if(@game['endless']) {
		// Sort player scores
		@scores = array();
		foreach(@p: @snake in @game['snakes']) {
			if(ponline(@p)) {
				@pscore = get_pscore('alive', @p, 'snake');
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
				title_msg(@player, @title, @subtitle, 40, 80, 40);
			}
		}
		
	} else {
		@title = @game['snakes'][@winner]['color'].@winner.' wins!';
		foreach(@player in array_keys(@game['snakes'])) {
			if(ponline(@player)) {
				title_msg(@player, @title, '', 40, 80, 40);
			}
		}
	}
	_snake_cleanup(@game);
}

proc _snake_cleanup(@game) {
	_snake_unbind_events();
	_snake_stop_song();
	clear_task(@game['interval']);
	del_virtualchest('snake');
	set_timeout(7000, closure(){
		foreach(@player: @snake in @game['snakes']) {
			_snake_remove(@player, @game);
		}
		export('snake', null);
		remove_scoreboard('snake');
		_remove_activity('snake');
	});
}
