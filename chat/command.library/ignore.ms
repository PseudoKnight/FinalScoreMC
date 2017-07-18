register_command('ignore', array(
	'description': 'Sets a player as ignored, preventing you from seeing any messages from them.',
	'usage': '/ignore <player|all>',
	'executor': closure(@alias, @sender, @args, @info) {
		if(!@args) {
			return(false);
		}
		@player = @args[0];
		if(@player != 'all') {
			@player = _find_player(@player);
		}
		@ignorelist = import('ignorelist');
		if(!array_index_exists(@ignorelist, @player)) {
			@ignorelist[@player] = array();
		}
		if(array_contains_ic(@ignorelist[@player], player())) {
			die(color('yellow').'You are already ignoring '.@player.'.');
		}
		@ignorelist[@player][] = player();
		msg(color('green').'You are now ignoring '.@player.'.');
		export('ignorelist', @ignorelist);
	}
));
