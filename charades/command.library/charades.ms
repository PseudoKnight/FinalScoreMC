register_command('charades', array(
	'description': 'A visual game of charades in Minecraft',
	'usage': '/charades [category]',
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		if(array_size(@args) == 1) {
			include('../core.library/words.ms');
			return(_strings_start_with_ic(_get_categories(), @args[-1]));
		}
	},
	'executor': closure(@alias, @sender, @args, @info) {
		if(@args && @args[0] == 'reroll') {
			try {
				foreach(@team in get_teams('charades')) {
					if(@team['name'] == 'builder') {
						if(@team['players'] && @team['players'][0] == player()) {
							include('../core.library/words.ms');
							include('../core.library/util.ms');
							@charades = import('charades');
							if(@charades['reroll']) {
								_msg_charades(color('yellow').player().' re-rolled "'.@charades['word'].'"');
								@category = array_get(@charades, 'category', array_rand(_get_categories(), 1, false)[0]);
								@charades['word'] = _get_word(@category);
								@charades['reroll'] = false;
								_msg_charades(color('yellow').color('bold').'Charades Category: '.color('yellow').@category);
								tmsg(@builder, 'You must now build "'.color('green').color('bold').@charades['word'].color('reset').'"');
							} else {
								msg('You cannot re-roll again.');
							}
						} else {
							msg('You are not building.');
						}
					}
				}
			} catch(ScoreboardException @ex) {
				msg('Game is not running.');
			}
			return(true);
		}
		
		if(array_contains(get_scoreboards(), 'charades')) {
			die(color('gold').'Already running.');
		}
		include('../core.library/words.ms');
		
		@categories = _get_categories();
		@category = '';
		if(@args) {
			@category = @args[0];
			if(!array_contains(@categories, @category)) {
				die(color('yellow').'Available categories: '.array_implode(@categories, ', ').'.');
			}
		}
		
		@players = array();
		foreach(@p in all_players('custom')) {
			if(array_contains(sk_current_regions(@p), 'charades')) {
				@players[] = @p;
			}
		}
		if(array_size(@players) < 3) {
			die(color('gold').'Requires at least 3 players.');
		}
		
		if(@category) {
			export('charades', array('category': @category, 'playersLeft': @players, 'interval': 0));
		} else {
			export('charades', array('playersLeft': @players, 'interval': 0));
		}
		
		create_scoreboard('charades');
		create_objective('score', 'DUMMY', 'charades');
		set_objective_display('score', array('displayname': 'Scores', 'slot': 'SIDEBAR'), 'charades');
		create_team('guessers', 'charades');
		create_team('builder', 'charades');
		set_team_display('builder', array('prefix': color('green')), 'charades');
		
		@spawn = sk_region_info('charades-beacon', 'custom', 0)[0];
		foreach(@p in @players) {
			set_pscore('score', @p, 0, 'charades');
			team_add_player('guessers', @p, 'charades');
			title(@p, 'Charades', to_upper(@category), 20, 60, 40);
			set_ploc(@p, @spawn);
			set_pmode(@p, 'SPECTATOR');
			set_pscoreboard(@p, 'charades');
			_set_pactivity(@p, 'charades');
		}
		
		set_block_at(@spawn, 169);
		
		include('../core.library/game.ms');
		
		_bind_charade_events();
		try {
			_start_round();
		} catch(Exception @ex) {
			console('Exception encountered in Charades.', false);
			console(@ex['classType'].': '.@ex['message'], false);
			foreach(@trace in @ex['stackTrace']) {
				console(split('LocalPackages', @trace['file'])[-1].':'.@trace['line'].' '.@trace['id'], false);
			}
			_end_game();
		}
	}
));
