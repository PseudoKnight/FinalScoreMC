register_command('mute', array(
	'description': 'Mutes a player for all other players',
	'usage': '/mute <player>',
	'permission': 'command.mute',
	'executor': closure(@alias, @sender, @args, @info) {
		if(!@args) {
			return(false);
		}
		@player = _find_player(@args[0]);
		@ignorelist = import('ignorelist');
		if(!array_index_exists(@ignorelist, @player)) {
			@ignorelist[@player] = array();
		}
		if(array_contains(@ignorelist[@player], 'all')) {
			die(color('yellow').'Already muted.');
		}
		@ignorelist[@player][] = 'all';
		msg(color('green').@player.' is now muted.');
		export('ignorelist', @ignorelist);
	}
));
