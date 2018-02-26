register_command('approve', array(
	'description': 'Approves a player so that they can build in survival.',
	'usage': '/approve',
	'permission': 'command.approve',
	'executor': closure(@alias, @sender, @args, @info) {
		if(!@args) {
			return(false);
		}
		@player = _find_player(@args[0]);
		if(@player == player()) {
			die(color('gold').'Are you that desperate for approval?');
		}
		include('includes.library/procedures.ms');
		if(_set_group(@player, 'member', true)) {
			msg(color('green').'Added player.');
			tmsg(@player, 'You have been added to the whitelist by '.color('yellow').player().color('white').'.');
			if(!has_permission('group.moderator')) {
				@pdata = _pdata(@player);
				@pdata['approval'] = player();
				_store_pdata(@player, @pdata);
			}
		}
	}
));
