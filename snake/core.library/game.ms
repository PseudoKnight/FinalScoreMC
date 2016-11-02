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
*/

include('util.ms');
include('powerups.ms');
include('snake.ms');
include('events.ms');
include('bot.ms');

proc _snake_queue(@args) {
	// Default options
	@game = associative_array();
	@game['arena'] = 'plane';
	@game['surfaces'] = 5;
	@game['snakes'] = associative_array();
	@game['powerups'] = array();
	@game['extraBlocks'] = array();
	@game['numPowerups'] = 15;
	@game['numPlayers'] = 7
	@game['botsOnly'] = false;

	// Command options
	foreach(@arg in @args) {
		@split = split(':', @arg);
		if(array_size(@split) < 2) {
			die('Invalid setting: '.@arg);
		}
		@key = @split[0];
		@value = @split[1];
		@game[@key] = @value;
	}

	// Create scoreboard
    try {
    	create_scoreboard('snake');
    	create_objective('alive', 'DUMMY', 'snake');
    	set_objective_display('alive', associative_array('displayname': 'SNAKE', 'slot': 'SIDEBAR'), 'snake');
    } catch(ScoreboardException @ex) {
        die('Snake is still running.');
    }

	// Add players in region
	foreach(@p in all_players()) {
		if(array_contains(sk_current_regions(@p), 'snake') && pmode(@p) == 'ADVENTURE') {
			_snake_add(@p, @game);
		}
		if(array_size(@game['snakes']) == @game['numPlayers']) {
			break();
		}
	}

	@bots = array('Grumpy','BatSnake','SharkBot');
	while(array_size(@game['snakes']) < @game['numPlayers'] && @bots) {
		@index = array_rand(@bots)[0];
		_snake_add(@bots[@index], @game);
		array_remove(@bots, @index);
	}

	// Start countdown
	@help = array(
		'',
		'Press \'f\' to activate ability',
		'Press \'f\' to activate ability',
		'To turn, click left or right mouse buttons',
		'To turn, click left or right mouse buttons',
		'SNAKE',
		'SNAKE',
	);
	@countdown = array(6);
	set_interval(1000, closure(){
		if(@countdown[0] > 0) {
			foreach(@p in array_keys(@game['snakes'])) {
				if(!ponline(@p)) {
					continue();
				}
				title_msg(@p, @countdown[0], array_get(@help, @countdown[0], ''), 0, 25, 0);
			}
		} else {
			clear_task();
			_snake_bind_events(@game);
			_snake_add_powerup(@game);
			_snake_start_task(@game);
			_snake_play_song();
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
		foreach(@player: @snake in @game['snakes']) {
			if(!@snake['bot'] && (!ponline(@player) || !array_contains(sk_current_regions(@player), 'snake'))) {
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
		if(array_size(@game['powerups']) < @game['numPowerups']) {
			_snake_add_powerup(@game);
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
		remove_scoreboard('snake');
		_remove_activity('snake');
	});
}
