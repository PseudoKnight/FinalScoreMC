# Player join messages and tab list colors
bind('player_join', null, null, @event) {
	modify_event('join_message', null);
	@lastPlayed = if(!@event['first_login'], plast_played(), null);

	# BLOCK CODES
	# Disables cheat features in mods that play nice.
	/*
	msg(colorize('&f &f &2 &0 &4 &8 ')); # Zombe zcheat
	msg(colorize('&f &f &4 &0 &9 &6 ')); # Zombe noclip
	msg(colorize('&f &f &1 &0 &2 &4 ')); # Zombe fly
	msg(colorize('&3 &9 &2 &0 &0 &2 ')); # CJB xray
	msg(colorize('&3 &9 &2 &0 &0 &1 ')); # CJB fly
	msg(colorize('&3 &9 &2 &0 &0 &3 ')); # CJB radar
	msg(colorize('&0&0&1&e&f')); # Rei's Minimap cave
	msg(colorize('&0&0&2&3&4&5&6&7&e&f')); # Rei's Minimap radar
	msg(colorize('&0&1&0&1&2&f&f')); # Smart-moving climb
	msg(colorize('&0&1&3&4&f&f')); # Smart-moving swim
	msg(colorize('&0&1&5&f&f')); # Smart-moving crawl
	msg(colorize('&0&1&6&f&f')); # Smart-moving slide
	msg(colorize('&0&1&7&f&f')); # Smart-moving fly
	msg(colorize('&0&1&8&9&a&b&f&f')); # Smart-moving jump
	msg(colorize('&3 &6 &3 &6 &3 &6 &e ')); # Voxelmap radar
	msg(colorize('&3 &6 &3 &6 &3 &6 &d ')); # Voxelmap cave
	*/

	set_timeout(50, closure(){
		@pdata = _pdata(player());

		if(array_index_exists(@pdata, 'world') && pworld() != @pdata['world']) {
			@thisGroup = _world_group(pworld());
			@previousGroup = _world_group(@pdata['world']);
			if(@thisGroup != @previousGroup) {
				console("Wrong world group! Expected @previousGroup but got @thisGroup");
			}
		}

		@title = colorize('&6&l\u1260 &d&l\u1260 &b&l\u1260 &4&l\u1260 &6&lFINALSCORE&e&lMC \u00AB &r\u25AA \u25AA \u25AA');
		set_display_name(_colorname().player());

		// Join message
		queue_push(closure(){
			if(!(has_permission('group.admin') && get_value('silentjoin'))) {
				@pre = '&8'.simple_date('h:mm').' &2\u00bb ';
				@name = _colorname().color('italic').player();
				@msg = '&e&o ';
				if(array_index_exists(@pdata, 'enter')) {
					@msg .= @pdata['enter'];
				} else {
					@msg .= 'joined the game';
				}
				@hover = 'New Player!';
				if(@lastPlayed) {
					@hover = 'Last played: '.simple_date('MMM d, yyyy', @lastPlayed);
				}
				if(array_index_exists(@pdata, 'names')) {
					@hover .= '\\n&7'.array_implode(@pdata['names']);
				}
				_tellraw(all_players(), array(array('colorize', @pre), array('hover', @name, @hover), @msg));
				if(function_exists('discord_broadcast')) {
					@msg = reg_replace('[&§][0-9a-fk-o]', '', @msg);
					try(discord_broadcast('minecraft_chat', '**\u00bb '.player().@msg.'**'));
				}
			}

		}, 'join');

		// Tab list
		queue_push(closure(){
			foreach(@p in all_players()) {
				set_list_name(@p, display_name(@p));
			}
			@title = colorize('&6&lFINALSCORE&e&lMC');
			@activities = import('activities');
			if(@activities) {
				@currently = array_implode(array_normalize(@activities), '\n');
				psend_list_header_footer(@title, color('gray').'Activities:\n'.color('reset').@currently);
			} else {
				psend_list_header_footer(@title, null);
			}
		}, 'join');

		// Welcome messages
		queue_push(closure(){
			#Welcome messages
			@line = string_multiply('-', 53);
			msg(color('1').color('m').'\u2575'.@line.color('1').'\u2575');
			msg(string_multiply(' ', 18).colorize('&6&l\u1260 &d&l\u1260 &b&l\u1260 &4&l\u1260 &6&lFINALSCORE&e&lMC \u00AB &r\u25AA \u25AA \u25AA'));
			msg(color('1').color('m').'\u2577'.@line.color('1').'\u2577');
			if(@motd = get_value('motd')) {
				msg('\n '.@motd);
				msg(color('1').color('m').'\n\u2575'.@line.color('1').'\u2575');
			} else {
				@tips = import(_world_group(pworld()).'-tips');
				if(@tips) {
					@tip = @tips[rand(array_size(@tips))];
					msg('\n '.colorize(@tip));
					msg(color('1').color('m').'\n\u2575'.@line.color('1').'\u2575');
				}
			}
		}, 'join');

		// Mail
		queue_push(closure(){
			if(array_index_exists(@pdata, 'mail')) {
				foreach(@mail in @pdata['mail']) {
					msg(color('gray').@mail[0].' (From '.@mail[1].'): '.color('r').@mail[2]);
				}
				array_remove(@pdata, 'mail');
				_store_pdata(player(), @pdata);
			}
		}, 'join');

		// Teleport misplaced players
		queue_push(closure(){
			if(array_index_exists(@pdata, 'homeless')) {
				# homeless players are players left on deleted worlds
				@loc = get_spawn('omega');
				set_ploc(@loc);
				array_remove(@pdata, 'homeless');
				_store_pdata(player(), @pdata);
			} else if(!has_permission('group.member')) {
				@warp = get_value('warp.intro');
				set_ploc(@warp);
			}
		}, 'join');

		// Populate session
		queue_push(closure(){
			if(!entity_exists(puuid())) {
				console('Warning, '.player().' does not have an entity in this world.');
			}

			if(@lastPlayed) {
				@session = _psession(player());
				@session['lastplayed'] = simple_date('MMM d, yyyy', @lastPlayed);
			}

			if(array_index_exists(@pdata, 'names')) {
				@players = import('players', associative_array());
				foreach(@name in @pdata['names']) {
					@players[to_lower(@name)] = @event['player'];
				}
				export('players', @players);
			}
		}, 'join');

		// Park inventory
		queue_push(closure(){
			if(pworld() === 'custom') {
				_equip_kit();
			}
		}, 'join');

		// Discord topic
		queue_push(closure(){
			_update_discord_topic();
		}, 'join');

		_bm_request('set_user_uuid', 'a1634f37480a4bb9a0b2200266597ac0', array('username': player(), 'user_uuid': puuid()));
	});
}

bind('player_quit', null, null, @event) {
	modify_event('message', null);
	@pdata = _pdata(@event['player']);
	@msg = _colorname().'&o'.player().'&e&o ';
	if(array_index_exists(@pdata, 'exit')) {
		@msg .= @pdata['exit'];
	} else {
		@msg .= 'left the game';
	}
	broadcast(colorize('&8'.simple_date('h:mm').' &4\u00ab &o'.@msg));
	if(extension_exists('CHDiscord')) {
		@msg = reg_replace('[&§][0-9a-fk-o]', '', @msg);
		try(discord_broadcast('minecraft_chat', '**\u00ab '.@msg.'**'));
	}
	try {
		@pdata['world'] = pworld();
		_store_pdata(@event['player'], @pdata);
	} catch(PlayerOfflineException @e) {
		msg('Cannot fetch player world while quitting.');
	}
	export('pdata.'.to_lower(@event['player']), null); // clear player data cache
	export('session.'.player(), null); // clear player state data
	if(array_index_exists(@pdata, 'names')) {
		@players = import('players', associative_array());
		foreach(@name in @pdata['names']) {
			array_remove(@players, to_lower(@name));
		}
		export('players', @players);
	}
	set_timeout(50, closure(){
		_update_discord_topic();
	});
}
