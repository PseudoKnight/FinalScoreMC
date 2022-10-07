register_command('player', array(
	description: 'Displays information about an online or offline player.',
	usage: '/player <player>',
	tabcompleter: closure(@alias, @sender, @args, @info) {
		return(array());
	},
	executor: closure(@alias, @sender, @args, @info) {
		if(!@args) {
			return(false);
		}
		@extendedInfo = has_permission('group.moderator');
		@player = @args[0];
		@uuid = '';
		@pdata = null;

		try {
			# ONLINE INFO
			@player = player(@player);
			@uuid = puuid(@player);
			@pdata = _pdata(@player);
			@color = _colorname(@player);
			@world = pworld(@player);
			msg(colorize("&7&m⎯⎯&7[&l@color @player &7]&m⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯"));
			msg(color('gray').' UUID: '.color('white').@uuid);
			msg(color('gray').' Gamemode: '.color('white').to_lower(pmode(@player)));
			msg(color('gray').' World: '.color('white')._worldname(@world).' ('._world_group(@world).')');

			if(@extendedInfo) {
				@info = pinfo(@player);
				@x = floor(@info[1][0]);
				@y = floor(@info[1][1]);
				@z = floor(@info[1][2]);
				msg(color('gray')." Position: x: @x y: @y z: @z");
				@ignorelist = import('ignorelist');
				if(array_index_exists(@ignorelist, @player)) {
					if(array_contains(@ignorelist[@player], 'all')) {
						msg(color('gray').' Muted by Moderator');
					} else {
						msg(color('gray').' Ignored by: '.array_implode(@ignorelist[@player], ', '));
					}
				}
				if(player() == '~console' || pisop()) {
					msg(color('gray').' IP: '.@info[3]);
					msg(color('gray').' Hostname: '.@info[10]);
				}
			}

		} catch(PlayerOfflineException @ex) {
			# OFFLINE INFO
			@uuid = _get_uuid(to_lower(@player), true, false);
			@pdata = _pdata_by_uuid(replace(@uuid, '-', ''));
			@player = @pdata['name'];
			@color = _colorname(@player);
			msg(colorize("&7&m⎯⎯&7[&l@color @player &7]&m⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯"));
			msg(color('gray').' UUID: '.color('white').@uuid);

			if(@extendedInfo) {
				if(array_index_exists(@pdata, 'ban')) {
					msg(color('red').' Banned '
							.if(array_index_exists(@pdata['ban'], 'by'), 'by '.@pdata['ban']['by'].' ')
							.if(array_index_exists(@pdata['ban'], 'time'), 'temporarily ')
							.if(array_index_exists(@pdata['ban'], 'message'), '- "'.@pdata['ban']['message'].'"'));
				}
				if((player() == '~console' || pisop()) && array_index_exists(@pdata, 'ips')) {
					msg(color('gray').' IPs: '.array_implode(@pdata['ips'], ' '));
				}
				if(array_index_exists(@pdata, 'homeless')) {
					msg(color('gray').' Homeless: Player was in Outworld when it was reset.');
				}
			}

			if(array_index_exists(@pdata, 'world')) {
				msg(color('gray').' Last World: '.color('white')._worldname(@pdata['world']).' ('._world_group(@pdata['world']).')');
			}
			@lastPlayed = plast_played(@pdata['name']);
			@minutes = (time() - @lastPlayed) / 60000;
			@hours = @minutes / 60;
			@days = @hours / 24;
			@lastPlayedOutput = '';
			if(@days > 14) {
				@lastPlayedOutput = simple_date('MMMMM dd, yyyy', @lastPlayed, 'US/Central');
			} else if(@days >= 3) {
				@lastPlayedOutput = 'Less than '.ceil(@days).' days ago';
			} else if(@hours >= 2) {
				@lastPlayedOutput = 'Less than '.ceil(@hours).' hours ago';
			} else {
				@lastPlayedOutput = floor(@minutes).' minutes ago';
			}
			msg(color('gray').' Last Played: '.color('white').@lastPlayedOutput);
		}

		@firstPlayed = simple_date('MMMMM dd, yyyy', pfirst_played(@pdata['name']), 'US/Central');
		@joined = if(array_index_exists(@pdata, 'joined'), color('gray').' ('.@pdata['joined'].')', '');
		msg(color('gray').' First Played: '.color('white').@firstPlayed.@joined);
		msg(color('gray').' Group: '.color('white').array_get(@pdata, 'group', 'default'));
		if(array_index_exists(@pdata, 'names')) {
			msg(color('gray').' Aliases: '.color('white').array_implode(@pdata['names'], ', '));
		}
		if(array_index_exists(@pdata, 'approval')) {
			msg(color('gray').' Approved by: '.color('white').@pdata['approval']);
		}

		if(@extendedInfo) {
			if(array_index_exists(@pdata, 'coins')) {
				msg(color('gray').' Coins: '.@pdata['coins']);
			}
			if(array_index_exists(@pdata, 'support'), msg(color('gray').' Support: $'.@pdata['support']));
			_bm_request('lookup_uuid', 'a1634f37480a4bb9a0b2200266597ac0', array('user_uuid': replace(@uuid, '-', '')), closure(@result) {
				if(@result) {
					msg(color('gray').' Notes: '.@result['user']['notes']);
					msg(color('gray').' Relations: '.@result['user']['relations']);
				}
			});
		}
	}
));
