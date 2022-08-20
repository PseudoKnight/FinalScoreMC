register_command('survival', array(
	description: 'Teleports you to your last known location in the survival worlds.',
	usage: '/survival',
	tabcompleter: closure(@alias, @sender, @args, @info) {
		return(array());
	},
	executor: closure(@alias, @sender, @args, @info) {
		if(_is_survival_world(pworld())) {
			die(color('yellow').'You are already in survival.');
		}
		include('includes.library/teleports.ms');
		@pdata = _pdata(player());
		if(array_index_exists(@pdata, 'survival')
		&& array_index_exists(@pdata['survival'], 'loc')
		&& (has_permission('group.member') || @pdata['survival']['loc'][3] != 'world')) {
			_warmuptp(player(), @pdata['survival']['loc']);
		} else {
			@loc = get_spawn('psi');
			@loc = array(@loc[0] + 0.5, @loc[1] - 1, @loc[2] + 0.5, @loc[3]);
			_warmuptp(player(), @loc);
		}
	}
));
