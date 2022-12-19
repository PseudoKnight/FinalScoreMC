register_command('unmute', array(
	description: 'Unmutes a player for all other players',
	usage: '/unmute <player>',
	permission: 'command.mute',
	executor: closure(@alias, @sender, @args, @info) {
		if(!@args) {
			return(false);
		}
		@player = _find_player(@args[0]);
		@ignorelist = import('ignorelist')
		if(!array_index_exists(@ignorelist, @player) || !array_contains(@ignorelist[@player], 'all')) {
			die(color('yellow').'That player is not muted.');
		}
		for(@i = 0, @i < array_size(@ignorelist[@player]), @i++) {
			if(@ignorelist[@player][@i] === 'all') {
				array_remove(@ignorelist[@player], @i);
				msg(color('green').@player.' is no longer muted.');
				break();
			}
		}
		export('ignorelist', @ignorelist);
	}
));
