proc _start_round() {
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
	
	_get_word(closure(@word) {
		title_msg(@builder, 'Your turn to build!', '"'.@word.'"', 20, 40, 20);
		tmsg(@builder, 'You must build "'.color('green').color('bold').@word.color('reset').'"');
			
		@timer = array(150.0);
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
					}
					_end_round(null, @word);
				} else if(pmode(@builder) != 'CREATIVE') {
					console('Builder\'s turn already ended.');
					clear_task();
				} else {
					_msg_charades(integer(@timer[0]), 'action');
					if(@timer[0] <= 0) {
						_end_round(null, @word);
					}
				}
			} catch(Exception @ex) {
				clear_task();
				console(@ex);
				_end_round(null, @word);
			}
		});
		
		bind(player_chat, array('id': 'charades-guessing', 'priority': 'HIGH'), null, @event, @word) {
			if(get_pscoreboard(player()) == 'charades') {
				try {
					if(get_pteam(player(), 'charades')['name'] == 'guessers') {
						consume();
						cancel();
						@letters = levenshtein(to_lower(@event['message']), to_lower(@word));
						if(@letters < 2) {
							play_sound(ploc(), array('sound': 'LEVEL_UP'));
							_end_round(player(), @word);
						} else {
							if(@letters == 3 && length(@word) > 6) {
								play_sound(ploc(), array('sound': 'VILLAGER_YES'), player());
							} else {
								play_sound(ploc(), array('sound': 'VILLAGER_NO'), player());
							}
							_regionmsg('charades', color(8).simple_date('h:mm').' [Charades] '.color('yellow').player().color(8).': '.color('r').@event['message']);
							msg(color('yellow').@letters.' letters don\'t match.');
						}
					}
				} catch(Exception @ex) {
					// they left the game, ignore
				}
			}
		}
	});
}

proc _end_round(@guesser, @word) {
	unbind('charades-guessing');
	
	@charades = import('charades');
	if(!@charades) {
		console('Charades ended already.');
		die();
	}
	if(@charades['interval']) {
		clear_task(@charades['interval']);
	}
	
	if(@guesser) {
		_regionmsg('charades', color('green').color('bold').@guesser.color('green').' correctly guessed "'.color('bold').@word.color('green').'"!');
		set_pscore('score', @guesser, get_pscore('score', @guesser, 'charades') + 1, 'charades');
	} else {
		_regionmsg('charades', color('yellow').color('yellow').'The answer you were looking for was "'.color('bold').@word.color('yellow').'"!');
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
		skcb_load('charades');
		skcb_paste(array(0, 0, 0, 'custom'), array('origin': true));
		_remove_region_entities('charades');
		
		if(@charades['playersLeft']) {
			_start_round();
		} else {
			// end game
			@center = sk_region_info('charades-beacon', 'custom', 0)[0];
			set_block_at(@center, '95:3');
			play_sound(@center, array('sound': 'UI_TOAST_CHALLENGE_COMPLETE', 'volume': 5));
			
			@top = 0;
			@topPlayers = array();
			@warp = get_value('warp.charades');
			foreach(@t in get_teams('charades')) {
				if(@t['name'] == 'guessers') {
					foreach(@p in @t['players']) {
						@s = get_pscore('score', @p, 'charades');
						if(@s > @top) {
							@top = @s;
							foreach(@index: @player in @topPlayers) {
								array_remove(@topPlayers, @index);
							}
							@topPlayers[] = @p;
						} else if(@s == @top) {
							@topPlayers[] = @p;
						}
						set_ploc(@p, @warp);
						_equip_kit(@p);
					}
				}
			}
			
			if(array_size(@topPlayers) == 1) {
				_regionmsg('charades', color('green').@topPlayers[0].' wins!');
			} else if(array_size(@topPlayers) > 1) {
				_regionmsg('charades', color('green').array_implode(@topPlayers, ' and ').' tied for the win!');
			} else {
				_regionmsg('charades', color('yellow').'Nobody wins! I\'M NOT SURE HOW THIS IS POSSIBLE. IS ANYONE THERE? WHY AM I YELLING?!');
			}
			_unbind_charade_events();
			export('charades', null);
			remove_scoreboard('charades');
		}
	});
}
