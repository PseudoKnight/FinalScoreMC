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
		include('../core.library/game.ms');
		if(@args && @args[0] == 'reroll') {
			try {
				foreach(@team in get_teams('charades')) {
					if(@team['name'] == 'builder') {
						if(@team['players'] && @team['players'][0] == player()) {
							@charades = import('charades');
							if(@charades['reroll']) {
								_msg_charades(color('yellow').player().' re-rolled "'.@charades['word'].'"');
								@category = array_get(@charades, 'category', array_rand(_get_categories(), 1, false)[0]);
								@charades['word'] = _get_word(@category);
								@charades['reroll'] = false;
								_msg_charades(color('yellow').color('bold').'Charades Category: '.color('yellow').@category);
								msg('You must now build "'.color('green').color('bold').@charades['word'].color('reset').'"');
							} else {
								msg(color('gold').'You cannot re-roll again.');
							}
						} else {
							msg(color('gold').'You are not building.');
						}
					}
				}
			} catch(ScoreboardException @ex) {
				msg(color('gold').'Game is not running.');
			}
			return(true);
		}
		
		if(array_contains(get_scoreboards(), 'charades')) {
			die(color('gold').'Already running.');
		}
		
		_prepare_game(@args);
	}
));
