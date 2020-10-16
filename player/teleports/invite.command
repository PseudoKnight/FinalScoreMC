register_command('invite', array(
	'description': 'Sends a teleport invite to another player.',
	'usage': '/invite <player>',
	'aliases': array('tpahere'),
	'executor': closure(@alias, @sender, @args, @info) {
		if(!@args) {
			return(false);
		}
		@player = _find_player(@args[0]);
		if(!has_permission(@player, 'command.join.from')) {
			die(color('gold').'That player is out of reach.');
		}

		# Check it the player is being ignored
		@ignorelist = import('ignorelist');
		if(array_index_exists(@ignorelist, player())) {
			if(array_contains(@ignorelist[player()], @player) || array_contains(@ignorelist[player()], 'all')) {
				die();
			}
		}
		if(array_index_exists(@ignorelist, 'all') && array_contains(@ignorelist['all'], @player)) {
			die();
		}

		@requests = import('requests');
		if(array_index_exists(@requests, @player)
		&& @requests[@player][0] === 'invite'
		&& @requests[@player][1] == player()
		&& @requests[@player][2] + 300000 > time()) { // 5 minutes
			die(color('gold').'You\'ve already sent an invite request to this player in the last 5 minutes.');
		}
		@requests[@player] = array('invite', player(), time());
		export('requests', @requests);
		tmsg(@player, color('dark_gray').simple_date('h:mm').' '.color('b').player().' has requested that you join them. /accept');
		msg(color('dark_gray').simple_date('h:mm').' '.color('b').'Invitation sent to '.@player.'.');
	}
));
