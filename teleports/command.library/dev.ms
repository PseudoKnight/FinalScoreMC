register_command('dev', array(
	'description': 'Teleports you to your last known location in the dev world.',
	'usage': '/dev',
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		return(array());
	},
	'executor': closure(@alias, @sender, @args, @info) {
		if(pworld() == 'dev') {
			die(color('yellow').'You are already in dev.');
		}
		include('../includes.library/teleports.ms');
		@pdata = _pdata(player());
		if(array_index_exists(@pdata, 'dev')
		&& array_index_exists(@pdata['dev'], 'loc')) {
			_warmuptp(player(), @pdata['dev']['loc']);
		} else {
			@loc = get_spawn('dev');
			@loc = array(@loc[0] + 0.5, @loc[1] - 1, @loc[2] + 0.5, @loc[3]);
			_warmuptp(player(), @loc);
		}
	}
));
