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

	@new = _get_build(@charades['category']);
	@charades['build'] = @new['build'];
	@charades['hint'] = @new['hint'];
	@charades['reroll'] = true;
	_msg_charades(color('yellow').color('bold').'Charades Category: '.color('yellow').replace(to_upper(@charades['category']), '_', ' '));
	_click_tell(array(@builder), array(
		'You must build '.color('green').color('bold').@charades['build'].color('reset').' ',
		array(color('yellow').'[Re-roll]', '/charades reroll')
	));
	title(@builder, 'Your turn to build!', '', 20, 40, 20);

	@timer = array(@charades['seconds']);
	@charades['interval'] = set_interval(500, closure(){
		try {
			@timer[0] -= 0.5;
			foreach(@t in get_teams('charades')) {
				if(@t['name'] == 'guessers') {
					foreach(@p in @t['players']) {
						if(!ponline(@p) || !array_contains(sk_current_regions(@p), 'charades')) {
							team_remove_player('guessers', @p, 'charades');
							array_remove_values(@charades['playersLeft'], @p);
							if(ponline(@p)) {
								set_ploc(@p, get_value('warp.charades'));
								_equip_kit(@p);
								_set_pactivity(@p, null);
							}
						}
					}
				}
			}
			if(!ponline(@builder) || !array_contains(sk_current_regions(@builder), 'charades')) {
				team_remove_player('builder', @builder, 'charades');
				if(ponline(@builder)) {
					set_ploc(@builder, get_value('warp.charades'));
					_equip_kit(@builder);
					_set_pactivity(@builder, null);
				}
				_end_build(null, @charades['build']);
			} else {
				_msg_charades(integer(@timer[0]), 'action');
				if(@timer[0] == 25) {
					if(@charades['hint']) {
						_msg_charades(color('bold').'Hint: '.@charades['hint']);
					}
				} else if(@timer[0] <= 0) {
					_end_build(null, @charades['build']);
				}
			}
		} catch(Exception @ex) {
			clear_task();
			console(@ex);
			_end_build();
		}
	});

	bind('player_chat', array('id': 'charades-guessing', 'priority': 'HIGH'), null, @event, @charades) {
		if(get_pscoreboard(player()) == 'charades') {
			consume();
			cancel();
			if(array_get(get_pteam(player(), 'charades'), 'name', null) == 'guessers') {
				@message = @event['message'];
				@timestamp = simple_date('h:mm');
				@name = display_name();
				if(_get_match(@message, @charades['build'])) {
					play_sound(ploc(), array('sound': 'ENTITY_PLAYER_LEVELUP'));
					_regionmsg('charades', colorize("&8@timestamp [Charades] @{name}&8: &r@message"));
					_end_build(player(), @charades['build']);
				} else {
					@message = _highlight_similarities(@message, @charades['build']);
					_regionmsg('charades', colorize("&8@timestamp [Charades] @{name}&8: &r@message"));
				}
			}
		}
	}
}

proc _end_build(@guesser, @word) {
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

	if(@guesser) {
		_regionmsg('charades', color('green').color('bold').@guesser.color('green').' correctly guessed "'.color('bold').@word.color('green').'"!');
		set_pscore('score', @guesser, get_pscore('score', @guesser, 'charades') + 1, 'charades');
	} else if(@word) {
		_regionmsg('charades', color('yellow').'The answer you were looking for was "'.color('bold').@word.color('yellow').'"!');
	} else {
		_regionmsg('charades', color('gold').'The game was called on account of rain.');
	}

	foreach(@t in get_teams('charades')) {
		if(@t['name'] == 'builder') {
			if(@t['players']) {
				@builder = @t['players'][0];
				if(@guesser) {
					set_pscore('score', @builder, get_pscore('score', @builder, 'charades') + 1, 'charades');
				}
				team_add_player('guessers', @builder, 'charades');
				_equip_kit(@builder);
				set_pmode(@builder, 'SPECTATOR');

				set_permission(@builder, 'command.skull', false);
			}
		}
	}

	set_timeout(7000, closure(){
		_remove_region_entities('charades');
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
			if(!_check_players(@charades)) {
				_end_game();
			} else {
				@charades['playersLeft'] = @charades['players'][];
				@charades['votes'] = associative_array();

				@page = '';
				@line = 1;
				foreach(@category in array_rand(_get_categories(), 10, false)) {
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
						if(!rand(3)) {
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
