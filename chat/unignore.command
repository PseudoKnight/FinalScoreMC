register_command('unignore', array(
	description: 'Unsets a player as ignored, allowing you to see messages from them.',
	usage: '/unignore <player|all>',
	tabcompleter: closure(@alias, @sender, @args, @info) {
		if(array_size(@args) == 1) {
			@players = all_players();
			@players[] = 'all';
			return(_strings_start_with_ic(@players, @args[-1]));
		}
		return(array());
	},
	executor: closure(@alias, @sender, @args, @info) {
		if(!@args) {
			return(false);
		}
		@player = @args[0];
		if(@player != 'all') {
			@player = _find_player(@player);
		}
		@ignorelist = import('ignorelist');
		if(!array_index_exists(@ignorelist, @player)) {
			die(color('yellow').'Was not ignored.');
		} else if(!array_contains_ic(@ignorelist[@player], player())) {
			die(color('yellow').'You have not ignored that player.');
		}
		for(@i = 0, @i < array_size(@ignorelist[@player]), @i++) {
			if(@ignorelist[@player][@i] == player()) {
				array_remove(@ignorelist[@player], @i);
				msg(color('green').'You are no longer ignoring '.@player.'.');
				break();
			}
		}
		export('ignorelist', @ignorelist);
	}
));
