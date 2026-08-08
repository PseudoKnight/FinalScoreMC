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
	'mode': the game mode (elimination, territory, endless, capture)
	'nukes': an array of regions that are getting nuked
	'teams': an array of two arrays containing the list of players on that team
	'flags': an array of two location arrays or player names where the team flags are in capture mode
	'fire': an array of location arrays where decaying fire blocks are located
	'debug': if the game should display debug info (e.g. current bot targets)
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
	@game['numPowerups'] = 1;
	@game['botsOnly'] = false;
	@game['missiles'] = associative_array();
	@game['tnt'] = array();
	@game['mode'] = @mode;
	@game['nukes'] = array();
	@game['teams'] = array(array(), array());
	@game['flags'] = array(null, null);
	@game['fire'] = array();
	@game['maxWidth'] = 0;
	@game['displays'] = array(null);
	@game['state'] = 0;
	@game['debug'] = false;
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
		@coords = sk_region_info(@game['region'].@game['surfaces'], 'custom', 0);
		@xWidth = @coords[0][0] - @coords[1][0] + 1;
		@yWidth = @coords[0][1] - @coords[1][1] + 1;
		@zWidth = @coords[0][2] - @coords[1][2] + 1;
		@game['maxWidth'] = max(@xWidth, @yWidth, @zWidth, @game['maxWidth']);
		@game['displays'][] = null;
	}
	@game['numPowerups'] = @game['surfaces'] * if(@mode === 'endless', 3, 5);

	// Create scoreboard
	try {
		create_scoreboard('snake');
		create_objective('score', 'DUMMY', 'snake');
		@display = 'First to 2 Wins!';
		if(@game['mode'] === 'endless') {
			@display = 'Survive!';
		} else if(@game['mode'] === 'pit') {
			@display = 'Protect the Pit!';
		} else if(@game['mode'] === 'capture') {
			create_objective('teamscore', 'DUMMY', 'snake');
			set_pscore('teamscore', 'BLUE', 0, 'snake');
			set_pscore('teamscore', 'RED', 0, 'snake');
			@display = color('red').'0'.color('reset').' : '.color('blue').'0';
		}
		set_objective_display('score', array(displayname: @display, slot: 'SIDEBAR'), 'snake');
	} catch(ScoreboardException @ex) {
		die(color('red').'Snake is still running.');
	}

	_snake_clean_surfaces(@game);

	// Create color select menu
	create_virtual_inventory('snake', 9, color('bold').'Choose Your Snake Color', array(
		array(name: 'LIGHT_BLUE_TERRACOTTA', meta: array(display: 'Blue')),
		array(name: 'LIGHT_BLUE_CONCRETE', meta: array(display: 'Neon Blue')),
		array(name: 'LIME_TERRACOTTA', meta: array(display: 'Green')),
		array(name: 'LIME_CONCRETE', meta: array(display: 'Neon Green')),
		array(name: 'PINK_TERRACOTTA', meta: array(display: 'Red')),
		array(name: 'PINK_CONCRETE', meta: array(display: 'Neon Pink')),
		array(name: 'MAGENTA_TERRACOTTA', meta: array(display: 'Purple')),
		array(name: 'YELLOW_CONCRETE', meta: array(display: 'Neon Yellow')),
		array(name: 'WHITE_CONCRETE', meta: array(display: 'Neon White')),
	));

	// Add players in region
	@numPlayers = 9;
	if(@game['mode'] === 'capture') {
		@numPlayers = 8; // max
	}
	@loadMenu = false;
	foreach(@p in all_players()) {
		if(array_contains(sk_current_regions(@p), @game['region']) && pmode(@p) === 'ADVENTURE') {
			if(_snake_add(@p, @game) && !@game['snakes'][@p]['head']) {
				@loadMenu = true;
			}
		}
		if(array_size(@game['snakes']) == @numPlayers) {
			break();
		}
	}
	if(@game['mode'] === 'capture') {
		@loadMenu = false;
	}

	if(@game['mode'] !== 'elimination' && !@game['snakes']) {
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
	if(@game['mode'] === 'capture') {
		@numPlayers = array_size(@game['snakes']) + array_size(@game['snakes']) % 2; // min
	}

	@bots = _snake_bots();
	while(array_size(@game['snakes']) < @numPlayers && @bots) {
		@index = array_rand(@bots)[0];
		_snake_add(@index, @game);
		array_remove(@bots, @index);
	}

	if(@game['mode'] === 'pit') {
		_snake_display(@game['surfaces'], array(name: 'LIME_STAINED_GLASS'), @game);
		for(@i = 1, @i < @game['surfaces'], @i++) {
			_snake_display(@i, null, @game);
		}
	} else if(@game['mode'] === 'capture') {
		_snake_display(2, array(name: 'BLUE_STAINED_GLASS'), @game);
		_snake_display(4, array(name: 'RED_STAINED_GLASS'), @game);
	}

	if(@game['mode'] === 'endless' || @game['mode'] === 'pit') {
		@scoreboardCount = array_size(@game['snakes']);
		@personalBests = associative_array();
		@minScore = math_const('INTEGER_MAX');
		foreach(@player: @snake in @game['snakes']) {
			if(!ponline(@player)) {
				continue();
			}
			@uuid = puuid(@player, true);
			@score = get_value('snake', @game['mode'], @uuid);
			if(@score) {
				@minScore = min(@minScore, @score);
				@scoreboardCount++;
				@personalBests[@uuid] = array(name: @player, score: @score);
			} else {
				@minScore = 0;
			}
		}
		if(@scoreboardCount < 15) {
			foreach(@index: @entry in get_value('snake', @game['mode'], 'top')) {
				@rank = string(@index + 1);
				switch(@rank) {
					case 1:
						@rank = '1st';
					case 2:
						@rank = '2nd';
					case 3:
						@rank = '3rd';
					default:
						@rank .= 'th';
				}
				@name = '';
				if(array_index_exists(@personalBests, @entry['uuid'])) {
					@name = array_remove(@personalBests, @entry['uuid'])['name'];
				} else {
					@name = _pdata_by_uuid(@entry['uuid'])['name'];
					@scoreboardCount++;
				}
				set_pscore('score', @rank.' '.@name, @entry['value'], 'snake');
				if(@scoreboardCount >= 15) {
					break();
				}
				if(@entry['value'] < @minScore) {
					break();
				}
			}
		}
		foreach(@uuid: @entry in @personalBests) {
			set_pscore('score', '-PB '.@entry['name'], @entry['score'], 'snake');
		}
	}

	// Optionally open color select menu
	if(@loadMenu) {
		foreach(@player: @snake in @game['snakes']) {
			if(ponline(@player) && !@snake['head']) {
				popen_inventory(@player, 'snake');
			}
		}
		bind('inventory_click', array(id: 'snake-invclick'), array(virtual: true), @event, @game) {
			if(pinventory_holder(player()) === 'snake' && array_index_exists(@game['snakes'], player())) {
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
					_snake_set_equipment(@game);
					delete_virtual_inventory('snake');
					_snake_countdown(@game);
				}
			});
		}
	} else {
		_snake_set_colors(@game);
		_snake_set_equipment(@game);
		delete_virtual_inventory('snake');
		_snake_countdown(@game);
	}
}

proc _snake_countdown(@game) {
	// Start 
	@game['state'] = 1;
	@help = array(
		color('red').color('bold').'SNAKE: '.to_upper(@game['mode']),
		'Use '.color('green').'left and right mouse buttons'.color('reset').' to turn',
		'Press '.color('green').'slot #'.color('reset').' to activate pickup',
		color('green').color('italic').'Go snake, go!'
	);
	@secondsLeft = array(8);
	set_interval(1000, 0, closure(){
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
	@game['state'] = 2;
	if(@game['mode'] === 'pit' || @game['mode'] === 'endless') {
		@song = array(sound: 'MUSIC_OVERWORLD_FOREST', category: 'RECORDS', seed: 18);
		if(@game['mode'] === 'endless') {
			@song = array(sound: 'MUSIC_CREDITS', category: 'RECORDS', seed: 0);
		}
		foreach(@player: @snake in @game['snakes']) {
			if(!@snake['bot']) {
				play_sound(puuid(@player), @song, @player);
			}
		}
	}
	@totalTicks = mutable_primitive(0);
	@scoreSeconds = mutable_primitive(0);
	@game['interval'] = set_interval(50, closure() {
		if(@game['mode'] === 'endless') {
			@totalTicks++;
			if(@totalTicks % 20 == 0) {
				@scoreSeconds++;
			}
		} else if(@game['mode'] === 'pit') {
			@totalTicks++;
		}
		while(array_size(@game['powerups']) < @game['numPowerups']) {
			_snake_add_powerup(@game);
		}
		@alive = 0;
		@active = 'No one';
		@playersAlive = 0;
		@botsInPit = false;
		@playersInPit = false;
		foreach(@player: @snake in @game['snakes']) {
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
				if(@snake['alive']) {
					if(@game['mode'] === 'endless' && (!@snake['bot'] || !@snake['deaths'])) {
						set_pscore('score', @player, @scoreSeconds, 'snake');
					} else if(@game['mode'] === 'pit' && @snake['region'] === @game['region'].@game['surfaces']) {
						if(@snake['bot']) {
							@botsInPit = true;
						} else {
							@playersInPit = true;
						}
					}
				}
			} else if(@snake['bot'] && (@game['mode'] === 'endless' || @game['mode'] === 'pit')) {
				@abilities = @snake['ability-count'];
				@abilities[4] = 0; // do not respawn with nuke
				if(_snake_spawn(@player, @game)) {
					@game['snakes'][@player]['ability-count'] = @abilities; // keep abilities
				}
			}
		}

		if(@game['mode'] === 'pit' && @totalTicks % 20 == 0) {
			if(@playersInPit && !@botsInPit) {
				@scoreSeconds++;
				foreach(@player: @snake in @game['snakes']) {
					if(@snake['bot'] || !@snake['alive']) {
						continue();
					}
					set_pscore('score', @player, @scoreSeconds, 'snake');
					if(@scoreSeconds <= 1) {
						stop_sound(@player, 'MUSIC_OVERWORLD_FOREST', 'RECORDS');
						play_sound(puuid(@player), array(sound: 'MUSIC_DISC_TEARS', category: 'RECORDS', pitch: 1.215, seed: 0), @player);
					}
					play_sound(ploc(@player), array(sound: 'UI_BUTTON_CLICK', pitch: 2.0), @player);
				}
				if(@scoreSeconds <= 1) {
					set_entity_spec(@game['displays'][5], array(item: null));
				}
				for(@i = 1, @i < @game['surfaces'], @i++) {
					set_entity_spec(@game['displays'][@i], array(item: array(name: 'YELLOW_STAINED_GLASS')));
				}
			} else if(@scoreSeconds > 0) {
				if(@playersInPit && @botsInPit) {
					for(@i = 1, @i < @game['surfaces'], @i++) {
						set_entity_spec(@game['displays'][@i], array(item: array(name: 'RED_STAINED_GLASS')));
					}
				} else if(!@playersInPit && @botsInPit) {
					_snake_end(null, @game);
					return();
				}
			}
		}

		if(@game['fire']) {
			@chance = array_size(@game['fire']) * 0.005;
			while(@chance > 0 && @chance > rand()) {
				@r = rand(0, array_size(@game['fire']));
				if(get_block(@game['fire'][@r]) === 'FIRE') {
					set_block(@game['fire'][@r], 'AIR', false);
				}
				array_remove(@game['fire'], @r);
				@chance -= 1.0;
			}
		}

		switch(@game['mode']) {
			case 'elimination':
				if(!@alive) {
					_snake_end(null, @game);
				} else if(@alive < 2) {
					_snake_end(@active, @game);
				} else if(!@playersAlive) {
					@game['botsOnly'] = true;
				}
			case 'endless':
			case 'pit':
				if(!@playersAlive) {
					_snake_end(null, @game);
				}
			case 'capture':
				foreach(@team: @flag in @game['flags']){
					if(!@flag) {
						_snake_spawn_flag(@team, @game);
					}
				}
				if(!@playersAlive && array_size(@game['snakes']) < 2) {
					_snake_end(null, @game);
				}
		}
	});
}

proc _snake_end(@winner, @game) {
	if(@game['mode'] === 'capture') {
		if(@winner != 'No one') {
			@team = @game['snakes'][@winner]['team'];
			foreach(@player in array_keys(@game['snakes'])) {
				if(ponline(@player)) {
					title(@player, '', @winner.' won the game for team '.if(@team, color('red').'RED', color('blue').'BLUE'), 40, 80, 40);
				}
			}
		}
		_snake_cleanup(@game);
	} else if(@game['mode'] === 'elimination') {
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
				if(ponline(@player)) {
					_snake_spawn(@player, @game);
				}
			}
			foreach(@player: @snake in @game['snakes']) {
				if(@snake['bot']) {
					_snake_spawn(@player, @game);
				}
			}
			_snake_countdown(@game);
		}

	} else if(@game['mode'] === 'endless' || @game['mode'] === 'pit') {
		// Sort player scores
		@scores = array();
		@allies = array();
		foreach(@p: @snake in @game['snakes']) {
			if(!ponline(@p)) {
				continue();
			}
			@allies[] = @p;
			@pscore = get_pscore('score', @p, 'snake');
			@array = array(name: @p, value: @pscore, highscore: false, topscore: false);
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

		// Store and set highscores and topscores
		@topscores = get_value('snake', @game['mode'], 'top');
		if(!@topscores) {
			@topscores = array();
		}
		@updateTopScores = false;
		foreach(@score in @scores) {
			@uuid = puuid(@score['name'], true);
			@pscore = get_value('snake', @game['mode'], @uuid);
			if(!is_null(@pscore) && @score['value'] <= @pscore) {
				continue();
			}
			store_value('snake', @game['mode'], @uuid, @score['value']);
			if(@score['value'] <= 0) {
				continue();
			}
			@score['highscore'] = true;

			@coins = @score['value'] - @pscore;
			_acc_add(@score['name'], @coins);
			tmsg(@score['name'], color('gold').'+'.@coins.' coins');

			@array = array(uuid: @uuid, value: @score['value']);
			if(@game['mode'] === 'pit' && array_size(@allies) > 1) {
				@array['allies'] = @allies[];
				array_remove_values(@array['allies'], @score['name']);
			}
			@remove = false;
			foreach(@i: @topscore in @topscores) {
				if(@topscore['uuid'] === @uuid) {
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
		if(@updateTopScores) {
			store_value('snake', @game['mode'], 'top', @topscores);
		}

		// Display scores
		if(@scores) {
			@output = array();
			foreach(@score in @scores) {
				@player = @score['name'];
				@output[] = '['.@score['value'].'] '.@game['snakes'][@player]['color'].@player
					.if(@score['topscore'], color('bold').' TOPSCORE!', if(@score['highscore'], color('bold').' HIGHSCORE!'));
			}
			foreach(@player in array_keys(@game['snakes'])) {
				if(ponline(@player)) {
					foreach(@line in @output) {
						tmsg(@player, @line);
					}
				}
			}
		}
		_snake_cleanup(@game);
	}
}

proc _snake_cleanup_round(@game) {
	@game['state'] = 3;
	foreach(@entity in @game['displays']) {
		if(@entity && entity_exists(@entity)) {
			entity_remove(@entity);
		}
	}
	@game['botsOnly'] = false;
	@game['powerups'] = array();
	@game['missiles'] = associative_array();
	@game['tnt'] = array();
	@game['nukes'] = array();
	@game['fire'] = array();
	_snake_unbind_events();
	foreach(@player: @snake in @game['snakes']) {
		if(ponline(@player) && pworld(@player) === 'custom') {
			set_pinv(@player, array(0: null, 1: null, 2: null, 3: null, 4: null));
			stop_sound(@player, 'MUSIC_OVERWORLD_FOREST', 'RECORDS');
			stop_sound(@player, 'MUSIC_DISC_TEARS', 'RECORDS');
			stop_sound(@player, 'MUSIC_CREDITS', 'RECORDS');
		}
	}
	if(array_index_exists(@game, 'interval')) {
		clear_task(@game['interval']);
	}
}

proc _snake_cleanup(@game) {
	_snake_cleanup_round(@game);
	@game['state'] = 4;
	delete_virtual_inventory('snake');
	set_timeout(8000, closure(){
		foreach(@player: @snake in @game['snakes']) {
			_snake_remove(@player, @game);
		}
		@game['state'] = 5;
		export('snake', null);
		remove_scoreboard('snake');
		_remove_activity('snake');
	});
}
