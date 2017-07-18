register_command('accept', array(
	'description': 'Accepts a teleport request.',
	'usage': '/accept',
	'executor': closure(@alias, @sender, @args, @info) {
		include('../includes.library/teleports.ms');
		@requests = import('requests');
		if(!array_index_exists(@requests, player()) || @requests[player()][2] + 300000 < time()) {
			die(color('gold').'There is no request to accept from the last 5 minutes.');
		}
		if(!ponline(@requests[player()][1])) {
			die(color('gold').'That player is no longer online.');
		}
		if(@requests[player()][0] === 'invite') {
			if(!has_permission('command.join.from')) {
				die(color('gold').'You cannot do that from here.');
			}
			if(!has_permission(@requests[player()][1], 'command.join.to')) {
				@warps = get_values('warp');
				@closest = null;
				@closestDistance = 10000;
				@loc = ploc(@requests[player()][1]);
				foreach(@warp in @warps) {
					if(@warp[3] == @loc['world']) {
						@dist = sqrt(((@warp[0] - @loc[0]) ** 2) + ((@warp[2] - @loc[2]) ** 2));
						if(@dist < @closestDistance) {
							@closest = @warp;
							@closestDistance = @dist;
						}
					}
				}
				if(is_null(@closest)) {
					die(color('gold').'You cannot join a player in '._worldname(pworld(@requests[player()][1])));
				}
				_warmuptp(player(), @closest, @closest[3] == 'custom');
				die(color('b').'Teleporting you near '.@requests[player()][1]);
			}
			msg(color('b').'Teleporting to '.@requests[player()][1].'...');
			tmsg(@requests[player()][1], color('b').'Teleporting '.player().'...');
			_warmuptp(player(), ploc(@requests[player()][1]));
		} else {
			if(!has_permission('command.join.to')) {
				die(color('gold').'You cannot do that from here.');
			}
			if(!has_permission(@requests[player()][1], 'command.join.from')) {
				die(color('gold').'That player is out of reach.');
			}
			msg(color('b').'Teleporting '.@requests[player()][1].'...');
			tmsg(@requests[player()][1], color('b').'Teleporting to '.player().'...');
			_warmuptp(@requests[player()][1], ploc());
		}
		array_remove(@requests, player());
		export('requests', @requests);
	}
));
