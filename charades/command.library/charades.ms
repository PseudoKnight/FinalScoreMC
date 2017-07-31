register_command('charades', array(
	'description': 'A visual game of charades in Minecraft',
	'usage': '/charades [word-type]',
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		if(array_size(@args) == 1) {
			include('../core.library/words.ms');
			return(_strings_start_with_ic(_get_word_types(), @args[-1]));
		}
	},
	'executor': closure(@alias, @sender, @args, @info) {
		if(array_contains(get_scoreboards(), 'charades')) {
			die(color('gold').'Already running.');
		}
		include('../core.library/words.ms');
		
		@wordTypes = _get_word_types();
		@wordType = '';
		if(@args) {
		    @wordType = @args[0];
			if(!array_contains(@wordTypes, @wordType)) {
				die(color('yellow').'Available word types: '.array_implode(@wordTypes, ', ').'.');
			}
		} else {
			@wordType = array_rand(@wordTypes, 1, false)[0];
		}
		
		@players = array();
		foreach(@p in all_players('custom')) {
			if(array_contains(sk_current_regions(@p), 'charades')) {
				@players[] = @p;
			}
		}
		//if(array_size(@players) < 3) {
		//	die(color('gold').'Requires at least 3 players.');
		//}
		export('charades', array('wordType': @wordType, 'playersLeft': @players, 'interval': 0));
		
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
			title_msg(@p, 'Charades', to_upper(@wordType), 20, 40, 20);
			set_ploc(@p, @spawn);
			set_pmode(@p, 'SPECTATOR');
			set_pscoreboard(@p, 'charades');
		}
		
		set_block_at(@spawn, 169);
		
		include('../core.library/rounds.ms');
		include('../core.library/util.ms');
		_start_round();
	}
));
