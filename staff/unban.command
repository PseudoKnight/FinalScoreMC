register_command('unban', array(
	description: 'Unbans an account from entering the server.',
	usage: '/unban <account>',
	permission: 'command.unban',
	executor: closure(@alias, @sender, @args, @info) {
		if(!@args) {
			return(false);
		}
		@player = @args[0];
		@pdata = _pdata(@player);
		if(!array_index_exists(@pdata, 'ban')) {
			die(color('gold').'That player is not banned.');
		}
		array_remove(@pdata, 'ban');
		_store_pdata(@player, @pdata);
		msg(color('green').@player.' is now unbanned.');
		console(player().' unbanned '.@player, false);
	}
));
