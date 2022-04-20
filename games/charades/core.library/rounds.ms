proc _queue_next_builder() {
	@charades = import('charades');
	@builder = '';
	do {
		@index = array_rand(@charades['playersLeft'], 1)[0];
		@builder = @charades['playersLeft'][@index];
		array_remove(@charades['playersLeft'], @index);
	} while(!ponline(@builder) || !array_contains(sk_current_regions(@builder), 'charades'));

	if(!@charades['playersLeft']) {
		_msg_charades(color('yellow').color('bold').'Last turn!');
	}

	team_add_player('builder', @builder, 'charades');
	set_pmode(@builder, 'CREATIVE');
	_clear_pinv(@builder);

	set_permission(@builder, 'command.skull', true);

	if(@charades['category'] == 'person_or_character' && !rand(10)) {
		// occasionally get player name instead for this category
		@charades['build'] = array_get_rand(get_teams('charades')['guessers']['players']);
		@charades['hint'] = '';
	} else {
		@new = _get_build(@charades['category']);
		@charades['build'] = @new['build'];
		@charades['hint'] = @new['hint'];
	}
	@charades['reroll'] = 2;
	_msg_charades(color('yellow').color('bold').'Charades Category: '.color('yellow').replace(to_upper(@charades['category']), '_', ' '));
	_msg_charades(color('yellow').color('bold').'You must guess: '.color('reset').reg_replace('[a-zA-Z0-9]', '_', @charades['build']));
	_click_tell(array(@builder), array(
		'You must build: '.color('green').color('bold').@charades['build'].color('reset').' ',
		array(color('yellow').'[Re-roll]', '/charades reroll')
	));
	title(@builder, 'Your turn to build!', '', 20, 40, 20);

	@timer = array(@charades['seconds']);
	@charades['interval'] = set_interval(500, closure(){
		try {
			@timer[0] -= 0.5;
			@guessers = get_teams('charades')['guessers']['players'];
			foreach(@p in @guessers) {
				if(!ponline(@p) || !array_contains(sk_current_regions(@p), 'charades')) {
					_charades_remove_player(@p);
					array_remove_values(@charades['playersLeft'], @p);
				}
			}
			foreach(@p in all_players(@charades['world'])) {
				if(@p != @builder && !array_contains(@guessers, @p)
				&& array_contains(sk_current_regions(@p), 'charades')) {
					_charades_add_player(@p);
				}
			}
			if(!ponline(@builder) || !array_contains(sk_current_regions(@builder), 'charades')) {
				team_remove_player('builder', @builder, 'charades');
				_charades_remove_player(@builder);
				_end_build();
			} else {
				_msg_charades(integer(@timer[0]), 'action');
				if(@timer[0] == 20) {
					if(@charades['hint']) {
						_msg_charades(color('yellow').color('bold').'Hint: '.@charades['hint']);
					}
				} else if(@timer[0] <= 0) {
					_end_build();
				}
			}
		} catch(Exception @ex) {
			clear_task();
			console(@ex);
			_end_build();
		}
	});

	bind('player_chat', array('id': 'charades-guessing', 'priority': 'HIGH'), null, @event, @charades, @timer) {
		if(get_pscoreboard(player()) == 'charades') {
			if(@event['message'][0] == '!') {
				modify_event('message', @event['message'][1..]);
			} else {
				consume();
				cancel();
				if(array_get(get_pteam(player(), 'charades'), 'name', null) == 'guessers') {
					@message = @event['message'];
					@timestamp = simple_date('h:mm');
					@name = display_name();
					if(_is_match(@message, @charades['build'])) {
						play_sound(ploc(), array('sound': 'ENTITY_PLAYER_LEVELUP'));
						@charades['buffer'][player()] = colorize("&8@timestamp [Charades] @{name}&8: &r&a&l@message");
						_msg_charades(color('green').player().' guessed correctly!');
						if(@timer[0] > 3) {
							@timer[0] = 3.0;
						}
					} else {
						@message = _show_matches(@message, @charades['build']);
						_msg_charades(colorize("&8@timestamp [Charades] @{name}&8: &r@message"));
					}
				}
			}
		}
	}
}

proc _end_build() {
	unbind('charades-guessing');

	@charades = import('charades');
	if(!@charades) {
		console('Charades ended already.');
		die();
	}
	if(@charades['interval']) {
		clear_task(@charades['interval']);
		@charades['interval'] = 0;
	}

	@points = if(@charades['finalRound'], 2, 1);

	if(@charades['buffer']) {
		foreach(@guesser: @guess in @charades['buffer']) {
			_msg_charades(@guess);
			set_pscore('score', @guesser, get_pscore('score', @guesser, 'charades') + @points, 'charades');
		}
	} else if(@charades['build']) {
		_msg_charades(color('gold').'The answer you were looking for was "'.color('bold').@charades['build'].color('gold').'"!');
	} else {
		_msg_charades(color('gold').'The game was called on account of rain.');
	}

	foreach(@t in get_teams('charades')) {
		if(@t['name'] == 'builder') {
			if(@t['players']) {
				@builder = @t['players'][0];
				if(@charades['buffer']) {
					set_pscore('score', @builder, get_pscore('score', @builder, 'charades') + @points, 'charades');
					@charades['buffer'] = associative_array();
				}
				team_add_player('guessers', @builder, 'charades');
				_equip_kit(@builder);
				set_pmode(@builder, 'SPECTATOR');

				set_permission(@builder, 'command.skull', false);
			}
		}
	}

	set_timeout(7000, closure(){
		_remove_region_entities('charades', array(), @charades['world'], true);
		// delay before paste to prevent entity issues
		set_timeout(50,closure(){
			try {
				skcb_load('charades-'.@charades['world']);
				skcb_paste(array(0, 0, 0, @charades['world']), array('origin': true));
			} catch(IOException @ex) {
				console('Could not load charades schematic for world: '.@charades['world']);
			}
		});

		if(@charades['playersLeft'] && ponline(@charades['playersLeft'][0])) {
			try {
				_queue_next_builder();
			} catch(Exception @ex) {
				console(@ex);
				_end_game();
			}
		} else {
			if(@charades['finalRound'] || !_check_players(@charades)) {
				_end_game();
			} else {
				@charades['playersLeft'] = @charades['players'][];
				@charades['votes'] = associative_array();

				@page = '';
				@line = 1;
				foreach(@category in array_rand(_get_categories(), 9, false)) {
					if(@line == 1) {
						@page .= '["",{"color":"red","bold":true,"text":"Vote for Next Category:\n"}';
						@line++;
					}
					@page .= ',{"text":"'.'\n \u27a2 '.replace(to_upper(@category), '_', ' ')
							.'","clickEvent":{"action":"run_command","value":"/charades vote '.@category.'"}}';
					@line++;
					if(@line == 15) {
						break();
					}
				}
				@page .= ',{"text":"'.'\n \u27a2 Final Round","clickEvent":{"action":"run_command","value":"/charades vote final_round"}}';
				@page .= ']';
				@pages = array(@page);
				foreach(@p in @charades['players']) {
					open_book(@p, @pages);
				}
				set_timeout(10000, closure(){
					if(!_check_players(@charades) || array_size(@charades['votes']) == 0) {
						_end_game();
					} else {
						@player = array_rand(@charades['votes'], 1)[0];
						@charades['category'] = @charades['votes'][@player];
						_msg_charades(color('yellow').@player.' chose '.replace(to_upper(@charades['category']), '_', ' '));

						if(@charades['category'] == 'final_round') {
							_msg_charades(color('aqua').color('bold').'FINAL ROUND! '.color('aqua').'RANDOM CATEGORY! DOUBLE POINTS! SHORTER CLOCK!');
							@charades['category'] = array_get_rand(_get_categories());
							@charades['seconds'] = 100.0;
							@charades['finalRound'] = true;
						} else if(!rand(3)) {
							@charades['seconds'] = 50.0;
							_msg_charades(color('red').'SPEED ROUND!');
						} else {
							@charades['seconds'] = 150.0;
						}
						try {
							_queue_next_builder();
						} catch(Exception @ex) {
							_end_game();
						}
					}
				});
			}
		}
	});
}
