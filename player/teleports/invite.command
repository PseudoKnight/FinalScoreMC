register_command('invite', array(
	description: 'Sends a teleport invite to a specific player, world group, or all players.',
	usage: '/invite <player|all|park|dev|survival>',
	aliases: array('tpahere'),
	tabcompleter: closure(@alias, @sender, @args, @info) {
		if(array_size(@args) == 1) {
			@completions = array_merge(array('all', 'dev', 'park', 'survival'), all_players());
			return(_strings_start_with_ic(@completions, @args[-1]));
		}
		return(array());
	},
	executor: closure(@alias, @sender, @args, @info) {
		if(!@args) {
			return(false);
		}
		@input = @args[0];
		@players = null;
		if(@input == 'all') {
			@players = all_players();
			array_remove_values(@players, player());
		} else if(array_contains(array('survival', 'dev', 'park'), @input)) {
			@players = all_players();
			foreach(@index: @player in @players) {
				if(@player == player() || _world_group(pworld(@player)) != @input) {
					array_remove(@players, @index);
				}
			}
		} else {
			@players = array(_find_player(@input));
		}
		
		@requests = import('requests');
		foreach(@player in @players) {
			if(!has_permission(@player, 'command.join.from')) {
				msg(color('gold').@player.' is out of reach.');
				continue();
			}

			# Check it the player is being ignored
			@ignorelist = import('ignorelist');
			if(array_index_exists(@ignorelist, player())) {
				if(array_contains(@ignorelist[player()], @player) || array_contains(@ignorelist[player()], 'all')) {
					continue();
				}
			}
			if(array_index_exists(@ignorelist, 'all') && array_contains(@ignorelist['all'], @player)) {
				continue();
			}

			if(array_index_exists(@requests, @player)
			&& @requests[@player][0] === 'invite'
			&& @requests[@player][1] == player()
			&& @requests[@player][2] + 300000 > time()) { // 5 minutes
				msg(color('gold').'You\'ve already sent an invite request to '.@player.' in the last 5 minutes.');
				continue();
			}
			@requests[@player] = array('invite', player(), time());
			@time = _timestamp();
			tmsg(@player, @time.color('b').player().' has requested that you join them. /accept');
			msg(@time.color('b').'Invitation sent to '.@player.'.');
		}
		export('requests', @requests);
	}
));
