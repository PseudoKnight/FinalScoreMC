register_command('player', array(
	description: 'Displays information about the given player.',
	usage: '/player <player>',
	permission: 'command.player',
	tabcompleter: closure(@alias, @sender, @args, @info) {
		return(array());
	},
	executor: closure(@alias, @sender, @args, @info) {
		if(!@args) {
			return(false);
		}
		@player = @args[0];
		@uuid = '';
		@pdata = null;
		try {
			# ONLINE INFO
			@player = player(@player);
			@uuid = puuid(@player);
			@pdata = _pdata(@player);
			@onlineinfo = pinfo(@player);
			msg(color('gray').'--[ '.color('l').@player.color('gray').' ]-------------------------');
			msg(color('gray').'UUID: '.color('r').@uuid);
			msg(color('gray').'Location: '.color('r')._worldname(@onlineinfo[7]).'('.@onlineinfo[7].') '
					.floor(@onlineinfo[1][0]).','.floor(@onlineinfo[1][1]).','.floor(@onlineinfo[1][2]));
			if(pmode(@player) === 'CREATIVE') {
				msg(color('gray').'Gamemode: '.color('r').'CREATIVE');
			}
			msg(color('gray').'IP: '.color('r').@onlineinfo[3]);
			msg(color('gray').'Hostname: '.color('r').@onlineinfo[10]);
			@ignorelist = import('ignorelist')
			if(array_index_exists(@ignorelist, @player)) {
				if(array_contains(@ignorelist[@player], 'all')) {
					msg(color('r').'MUTED');
				} else {
					msg(color('gray').'Ignored by: '.color('r').array_implode(@ignorelist[@player], ', '));
				}
			}

		} catch(PlayerOfflineException @ex) {
			# OFFLINE INFO
			@uuid = _get_uuid(to_lower(@player), true, false);
			@pdata = _pdata_by_uuid(replace(@uuid, '-', ''));
			@lastPlayed = plast_played(@pdata['name']);
			@minutes = (time() - @lastPlayed) / 60000;
			@hours = @minutes / 60;
			@days = @hours / 24;
			msg(color('gray').'--[ '.color('l').@pdata['name'].color('gray').' ]-------------------------')
			msg(color('gray').'UUID: '.color('r').@uuid);

			if(array_index_exists(@pdata, 'ban'), msg(color('red').'Banned '.color('r')
				.if(array_index_exists(@pdata['ban'], 'by'), 'by '.@pdata['ban']['by'].' ')
				.if(array_index_exists(@pdata['ban'], 'time'), 'temporarily ')
				.if(array_index_exists(@pdata['ban'], 'message'), '- "'.@pdata['ban']['message'].'"')))
			msg(color('gray').'Last Played: '.color('r').
			if(@days > 14) {
				simple_date('MMMMM dd, yyyy', @lastPlayed, 'US/Central');
			} else if(@days >= 3) {
				'Over '.floor(@days).' days ago'
			} else if(@hours >= 2) {
				'Over '.floor(@hours).' hours ago'
			} else {
				floor(@minutes).' minutes ago'
			})
			if(array_index_exists(@pdata, 'homeless'), msg(color('gray').'Homeless: '.color('r').'TRUE'));
			if(array_index_exists(@pdata, 'ips'), msg(color('gray').'IPs: '.color('r').array_implode(@pdata['ips'], ' ')));
			if(array_index_exists(@pdata, 'world'), msg(color('gray').'World: '.color('r').@pdata['world']));
		}
		msg(color('gray').'Group: '.color('r').array_get(@pdata, 'group', 'default'));
		if(array_index_exists(@pdata, 'names'), msg(color('gray').'Aliases: '.color('r').array_implode(@pdata['names'], ', ')));
		if(array_index_exists(@pdata, 'joined'), msg(color('gray').'Joined: '.color('r').@pdata['joined']));
		if(array_index_exists(@pdata, 'approval'), msg(color('gray').'Approved by: '.color('r').@pdata['approval']));
		if(array_index_exists(@pdata, 'coins'), msg(color('gray').'Coins: '.color('r').@pdata['coins']));
		if(array_index_exists(@pdata, 'support'), msg(color('gray').'Support: '.color('r').'$'.@pdata['support']));
		_bm_request('lookup_uuid', 'a1634f37480a4bb9a0b2200266597ac0', array('user_uuid': replace(@uuid, '-', '')), closure(@result) {
			if(@result) {
				msg(color('gray').'Notes: '.color('r').@result['user']['notes']);
				msg(color('gray').'Relations: '.color('r').@result['user']['relations']);
			}
		});
	}
));
