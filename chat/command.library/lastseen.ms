register_command('lastseen', array(
	'description': 'Returns the last time this player exited the server.',
	'usage': '/lastseen <player>',
	'settabcompleter': closure(@alias, @sender, @args, @info) {
		return(array());
	},
	'executor': closure(@alias, @sender, @args, @info) {
		if(!@args) {
			return(false);
		}
		@player = @args[0];
		if(ponline(@player)) {
			die('Um, right now!');
		}
		@uuid = _get_uuid(to_lower(@player), true, false);
		@pdata = _pdata_by_uuid(replace(@uuid, '-', ''));
		@lastPlayed = plast_played(@uuid);
		@minutes = (time() - @lastPlayed) / 60000;
		@hours = @minutes / 60
		@days = @hours / 24
		msg(@pdata['name'].' was last seen '.
			if(@days > 14) {
				simple_date('MMMMM dd, YYYY', @lastPlayed)
			} else if(@days >= 3) {
				'over '.floor(@days).' days ago'
			} else if(@hours >= 2) {
				'over '.floor(@hours).' hours ago'
			} else {
				floor(@minutes).' minutes ago'
			}
		);
	}
));
