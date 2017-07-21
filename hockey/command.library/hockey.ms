register_command('hockey', array(
	'description': 'Starts a hockey game.',
	'usage': '/hockey',
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		return(array());
	},
	'executor': closure(@alias, @sender, @args, @info) {
		if(array_contains(get_scoreboards(), 'hockey')) {
			die(color('gold').'Hockey already running.');
		}
		include('../includes.library/game.ms');
		@players = array();
		foreach(@p in all_players(pworld())) {
			if(array_contains(sk_current_regions(@p), 'hockey')) {
				@players[] = @p;
			}
		}
		if(array_size(@players) < 1) {
			die(color('gold').'Not enough players.');
		} else if(array_size(@players) % 2 == 1) {
			//die('Teams are not even.');
		}
		_queue_game(@players);
	}
));
