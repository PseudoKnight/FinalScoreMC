register_command('firstseen', array(
	'description': 'Returns the first time this player joined the server.',
	'usage': '/firstseen <player>',
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		return(array());
	},
	'executor': closure(@alias, @sender, @args, @info) {
		if(!@args) {
			return(false);
		}
		@player = @args[0];
		@uuid = _get_uuid(to_lower(@player), true, false);
		@pdata = _pdata_by_uuid(replace(@uuid, '-', ''));
		@firstPlayed = pfirst_played(@uuid);
		@minutes = (time() - @firstPlayed) / 60000;
		@hours = @minutes / 60
		@days = @hours / 24
		@date = simple_date('YYYY-MM-dd', @firstPlayed);
		msg('Bukkit says '.@pdata['name'].' was first seen '.
			if(@days > 14) {
				@date
			} else if(@days >= 3) {
				'over '.floor(@days).' days ago'
			} else if(@hours >= 2) {
				'over '.floor(@hours).' hours ago'
			} else {
				floor(@minutes).' minutes ago'
			}
		);
		if(array_index_exists(@pdata, 'joined') && @pdata['joined'] != @date) {
			msg('However, my current data shows '.@pdata['joined'].' was when they first joined.');
		}
	}
));
