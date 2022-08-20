register_command('join', array(
	description: 'Sends a teleport request to another player.',
	usage: '/join <player>',
	aliases: array('tpa'),
	executor: closure(@alias, @sender, @args, @info) {
		if(!@args) {
			return(false);
		}
		@player = _find_player(@args[0]);
		if(!has_permission('command.join.from')) {
			die(color('gold').'You cannot use teleport commands in '._worldname(pworld()));
		}
		include('includes.library/teleports.ms');
		if(!has_permission(@player, 'command.join.to')) {
			@warps = get_values('warp');
			@closest = null;
			@closestDistance = 10000;
			@loc = ploc(@player);
			foreach(@warp in @warps) {
				if(@warp[3] == @loc['world']) {
					@dist = distance(@warp, @loc);
					if(@dist < @closestDistance) {
						@closest = @warp;
						@closestDistance = @dist;
					}
				}
			}
			if(is_null(@closest)) {
				die(color('gold').'You cannot directly join a player who is in '._worldname(pworld(@player)));
			}
			_warmuptp(player(), @closest, @closest[3] == 'custom');
			die(color('b').'Teleporting you near '.@player);
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
		
		@pdata = _pdata(@player);
		if(array_index_exists(@pdata, 'joinaccept') && entity_grounded(puuid(@player))) {
			_warmuptp(player(), ploc(@player));
			die();
		}

		@requests = import('requests');
		if(array_index_exists(@requests, @player)
		&& @requests[@player][0] === 'join'
		&& @requests[@player][1] == player()
		&& @requests[@player][2] + 300000 > time()) { // 5 minutes
			die(color('gold').'You\'ve already sent a join request to this player in the last 5 minutes.');
		}
		@requests[@player] = array('join', player(), time());
		export('requests', @requests);
		tmsg(@player, color('dark_gray').simple_date('h:mm').' '.color('b').player().' has requested to join you. /accept');
		msg(color('dark_gray').simple_date('h:mm').' '.color('b').'Request to join sent to '.@player.'.');
	}
));
