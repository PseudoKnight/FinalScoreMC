register_command('charades', array(
	'description': 'A visual game of charades in Minecraft',
	'usage': '/charades [category]',
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		if(array_size(@args) == 1) {
			include('core.library/words.ms');
			return(_strings_start_with_ic(_get_categories(), @args[-1]));
		}
	},
	'executor': closure(@alias, @sender, @args, @info) {
		include('core.library/game.ms');
		array_resize(@args, 1, '');
		switch(@args[0]) {
			case 'reroll':
				try {
					foreach(@team in get_teams('charades')) {
						if(@team['name'] == 'builder') {
							if(@team['players'] && @team['players'][0] == player()) {
								@charades = import('charades');
								if(@charades['reroll']) {
									_msg_charades(color('yellow').player().' re-rolled "'.@charades['build'].'"');
									@new = _get_word(@charades['category']);
									@charades['build'] = @new['build'];
									@charades['hint'] = @new['hint'];
									@charades['reroll'] = false;
									msg('You must now build "'.color('green').color('bold').@charades['build'].color('reset').'"');
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
				
			case 'vote':
				if(array_size(@args) < 2) {
					die(color('gold').'You must specify a category.');
				}
				@category = @args[1];
				@charades = import('charades');
				if(!@charades) {
					die(color('gold').'Game is not running.');
				}
				@charades['votes'][player()] = @category;
				
			default:
				if(array_contains(get_scoreboards(), 'charades')) {
					die(color('gold').'Already running.');
				}
				_prepare_game(@args[0]);
		}
	}
));
