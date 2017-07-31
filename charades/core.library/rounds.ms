proc _start_round() {
	@charades = import('charades');
	@builder = '';
	do {
		@index = array_rand(@charades['playersLeft'], 1)[0];
		@builder = @charades['playersLeft'][@index];
		array_remove(@charades['playersLeft'], @index);
	} while(!ponline(@builder) || !array_contains(sk_current_regions(@builder), 'charades'));
	
	team_add_player('builder', @builder, 'charades');
	set_pmode(@builder, 'CREATIVE');
	
	_get_word(closure(@word) {
		tmsg(@builder, 'The word to build is '.color('green').color('bold').@word);
		
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
				if(!ponline(@builder) || !array_contains(sk_current_regions(@builder), 'charades') || get_pteam(@builder, 'charades')['name'] != 'builder') {
					team_remove_player('builder', @builder, 'charades');
					if(ponline(@builder)) {
						_equip_kit(@builder);
					}
					_end_round(null, @word);
				} else {
					_msg_charades(integer(@timer[0]), 'action');
					if(@timer[0] < 1) {
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
						if(levenshtein(to_lower(@event['message']), to_lower(@word)) < 2) {
							_end_round(player(), @word);
						} else {
							_msg_charades(color(8).simple_date('h:mm').' '.color('yellow').player().color(8).': '.color('r').@event['message']);
						}
					}
				} catch(Exception @ex) {
					// they left the game, ignore
				}
			}

		}
		
		bind(item_spawn, array('id': 'charades-item'), null, @event) {
			if(@event['location']['world'] == 'custom' && array_contains(sk_regions_at(@event['location']), 'charades-build')) {
				set_timeout(50, closure(){
					try(set_entity_gravity(@event['id'], false));
				});
			}
		}
	});
}

proc _end_round(@guesser, @word) {
	unbind('charades-guessing');
	unbind('charades-item');
	
	@charades = import('charades');
	if(!@charades) {
		die(); // already ended somehow
	}
	if(@charades['interval']) {
		clear_task(@charades['interval']);
	}
	
	if(@guesser) {
		_msg_charades(color('green').color('bold').@guesser.color('green').' correctly guessed the word: '.color('bold').@word.color('green').'!');
		set_pscore('score', @guesser, get_pscore('score', @guesser, 'charades') + 1, 'charades');
	} else {
		_msg_charades(color('yellow').color('bold').'Times up! '.color('yellow').'The word you were looking for was: '.color('bold').@word.color('yellow').'!');
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
			}
		}
	}
	
	set_timeout(5000, closure(){
		skcb_load('charades');
		skcb_paste(array(0, 0, 0, 'custom'), array('origin': true));
		_remove_region_entities('charades');
		
		if(@charades['playersLeft']) {
			_start_round();
		} else {
			// end game
			set_block_at(sk_region_info('charades-beacon', 'custom', 0)[0], '95:3');
			
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
				_msg_charades(color('green').@topPlayers[0].' wins!');
			} else if(array_size(@topPlayers) > 1) {
				_msg_charades(color('green').array_implode(@topPlayers, ' and ').' tied for the win!');
			} else {
				_msg_charades(color('green').'Nobody wins! I\'M NOT SURE HOW THIS IS POSSIBLE. IS ANYONE THERE? WHY AM I YELLING?!');
			}
			export('charades', null);
			remove_scoreboard('charades');
		}
	});
}
