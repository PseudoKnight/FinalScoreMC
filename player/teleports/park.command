register_command('park', array(
	'description': 'Teleports you to your last known location in the park.',
	'usage': '/park',
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		return(array());
	},
	'executor': closure(@alias, @sender, @args, @info) {
		if(pworld() == 'custom') {
			die(color('yellow').'You are already in Frog Park.');
		}
		include('includes.library/teleports.ms');
		@pdata = _pdata(player());
		if(array_index_exists(@pdata, 'minigames')
		&& array_index_exists(@pdata['minigames'], 'loc')) {
			_warmuptp(player(), @pdata['minigames']['loc'], false, true);
		} else {
			@loc = get_spawn('custom');
			@loc = array(@loc[0] + 0.5, @loc[1] - 1, @loc[2] + 0.5, @loc[3]);
			_warmuptp(player(), @loc);
		}
	}
));
