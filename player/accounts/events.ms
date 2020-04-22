bind('player_login', null, null, @event) {
	if(@event['result'] !== 'ALLOWED') {
		die();
	}
	@update = false;
	@pdata = null;
	@uuidDashed = get_value('players', to_lower(@event['player']));
	if(is_null(@uuidDashed)) { # new player or changed name
		@uuid = replace(@event['uuid'], '-', '');
		@pdata = get_value('uuids', @uuid);
		store_value('players', to_lower(@event['player']), @event['uuid']);
		@update = true;
		if(@pdata) { # someone changed their name or name doesn't exist
			if(array_index_exists(@pdata, 'name')) {
				export('pdata.'.to_lower(@pdata['name']), null);
				if(!array_index_exists(@pdata, 'names')) {
					@pdata['names'] = array();
				}
				array_remove_values(@pdata['names'], @pdata['name']);
				@pdata['names'][] = @pdata['name'];
			} else {
				msg('WARNING: ' . @event['player'] . ' did not have their name stored.');
			}
			@pdata['name'] = @event['player'];
		} else { # new player!
			@pdata = array(
				'joined': simple_date('yyyy-MM-dd'),
				'name': @event['player'],
			);
		}

	} else { # existing player
		if(@uuidDashed != @event['uuid']) {
			modify_event('result', 'KICK_OTHER');
			modify_event('kickmsg', 'You seem to be using a reserved player name.'
				.' Please contact an administrator if this is in error.');
			die();
		}

		@uuid = replace(@uuidDashed, '-', '');
		@pdata = get_value('uuids', @uuid);

		if(is_null(@pdata)) {
			modify_event('result', 'KICK_OTHER');
			modify_event('kickmsg', 'ERROR: User data is missing for known player.');
			die();
		}

		if(!array_index_exists(@pdata, 'name')) {
			@pdata['name'] = @event['player'];
			@update = true;

		} else if(@pdata['name'] != @event['player']) {
			# player changed their name back or data was inaccurate
			if(!array_index_exists(@pdata, 'names')) {
				@pdata['names'] = array(); # data was probably inaccurate
			}
			array_remove_values(@pdata['names'], @event['player']);
			@pdata['names'][] = @pdata['name'];
			@pdata['name'] = @event['player'];
			@update = true;
		}
	}

	# Check if player is banned.
	if(array_index_exists(@pdata, 'ban')) {
		if(!array_index_exists(@pdata['ban'], 'time') || @pdata['ban']['time'] > time()) {
			modify_event('result', 'KICK_BANNED');
			if(array_index_exists(@pdata['ban'], 'message')) {
				modify_event('kickmsg', @pdata['ban']['message']);
			} else {
				modify_event('kickmsg', 'Banned. Appeal at FinalScoreMC.com');
			}
		} else {
			array_remove(@pdata, 'ban');
			console('Ban on '.@event['player'].' expired.', false);
			@update = true;
		}
	}

	if(!array_index_exists(@pdata, 'ips')) {
		@pdata['ips'] = array();
	}
	if(!array_contains(@pdata['ips'], @event['ip'])) {
		@pdata['ips'][] = @event['ip'];
		if(array_size(@pdata['ips']) > 2) {
			array_remove(@pdata['ips'], 0);
		}
		@update = true;
	}

	export('pdata.'.to_lower(@event['player']), @pdata);

	if(@update) {
		store_value('uuids', @uuid, @pdata);
	}
}
