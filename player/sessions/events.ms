# Player join messages and tab list colors
bind('player_join', null, null, @event) {
	modify_event('join_message', null);
	@lastPlayed = if(!@event['first_login'], plast_played(), null);

	set_timeout(1, closure(){
		if(!ponline(player())) {
			die();
		}

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
			if(!ponline(player())) {
				queue_clear(player().'join');
				die();
			}

			if(!string_starts_with(pinfo(player(), 12), 'silent')) {
				@pre = _timestamp().color('dark_green').'\u00bb ';
				@name = _colorname().color('italic').player();
				@msg = '&e&o ';
				if(array_index_exists(@pdata, 'enter')) {
					@msg .= @pdata['enter'];
				} else {
					@msg .= 'joined the game';
				}
				@hover = 'New Player!';
				if(@lastPlayed) {
					@hover = 'Last played: '.simple_date('MMM d, yyyy', @lastPlayed, 'US/Central');
				}
				if(array_index_exists(@pdata, 'names')) {
					@hover .= '\\n&7'.array_implode(@pdata['names']);
				}
				_tellraw(all_players(), array(array('plain', @pre), array('hover', @name, @hover), @msg));
				if(function_exists('discord_broadcast')) {
					@test = if(get_os() === 'WINDOWS', '[TEST SERVER]', '');
					@count = array_size(all_players());
					@msg = reg_replace('[&§][0-9a-fk-o]', '', @name.@msg);
					@embed = array(
						color: array(r: 58, g: 106, b: 39),
						author: array(
							name: "\u00bb@test @msg (@count)",
							icon_url: 'http://liam.fragify.net:30027/tiles/faces/32x32/'.player().'.png'));
					if(is_null(@lastPlayed)) {
						@embed['footer'] = array(text: 'New player!');
					} else if(@lastPlayed && time() - @lastPlayed > 1000 * 60 * 60 * 24 * 7) {
						@embed['footer'] = array(text: 'Last played');
						@embed['timestamp'] = @lastPlayed;
					}
					try(discord_broadcast('minecraft_chat', array(embed: @embed)));
				}
			}

		}, player().'join');

		// Tab list
		queue_push(closure(){
			if(!ponline(player())) {
				queue_clear(player().'join');
				die();
			}

			foreach(@p in all_players()) {
				set_list_name(@p, display_name(@p));
			}
			set_plist_header(colorize('&6&lFINALSCORE&e&lMC'));
		}, player().'join');

		// Welcome messages
		queue_push(closure(){
			if(!ponline(player())) {
				queue_clear(player().'join');
				die();
			}

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
					@tip = array_get_rand(@tips);
					msg('\n '.colorize('&e \u2139 &f'.@tip));
					msg(color('1').color('m').'\n\u2575'.@line.color('1').'\u2575');
				}
			}
		}, player().'join');

		// Mail
		queue_push(closure(){
			if(!ponline(player())) {
				queue_clear(player().'join');
				die();
			}

			if(array_index_exists(@pdata, 'mail')) {
				foreach(@mail in @pdata['mail']) {
					msg(color('gray').@mail[0].' (From '.@mail[1].'): '.color('r').@mail[2]);
				}
				array_remove(@pdata, 'mail');
				_store_pdata(player(), @pdata);
			}
		}, player().'join');

		// Teleport misplaced players
		queue_push(closure(){
			if(!ponline(player())) {
				queue_clear(player().'join');
				die();
			}

			if(array_index_exists(@pdata, 'homeless')) {
				# homeless players are players left on deleted worlds
				@loc = get_spawn('psi');
				set_ploc(@loc);
				array_remove(@pdata, 'homeless');
				_store_pdata(player(), @pdata);
			} else if(!has_permission('group.member')) {
				@warp = get_value('warp.intro');
				set_ploc(@warp);
			}
		}, player().'join');

		// Populate session
		queue_push(closure(){
			if(!ponline(player())) {
				queue_clear(player().'join');
				die();
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
		}, player().'join');

		// Park inventory
		queue_push(closure(){
			if(!ponline(player())) {
				queue_clear(player().'join');
				die();
			}

			if(pworld() === 'custom') {
				_equip_kit();
			}
		}, player().'join');

		// Enter effect
		if(array_index_exists(@pdata, 'entereffect')) {
			queue_push(closure(){
				if(ponline(player())) {
					@loc = ploc();
					switch(@pdata['entereffect']) {
						case 'lightning':
							lightning(@loc, true);
						case 'kaboom':
							@ball = launch_firework(location_shift(@loc, 'up'), array(
								strength: 0,
								type: 'BALL_LARGE',
								colors: 'BLACK',
							));
							set_entity_spec(@ball, array(angled: true));
							set_entity_velocity(@ball, array(0, -1, 0));
							@burst = launch_firework(@loc, array(
								strength: 0,
								type: 'BURST',
								trail: true,
								colors: 'BLACK',
							));
						case 'resurrect':
							play_entity_effect(puuid(), 'TOTEM_RESURRECT');
					}
				}
			}, player().'join');
		}
	});
}

bind('player_quit', null, null, @event) {
	modify_event('message', null);
	@pdata = _pdata(@event['player']);
	if(!string_starts_with(pinfo(player(), 12), 'silent')) {
		@msg = _colorname().'&o'.player().'&e&o ';
		if(array_index_exists(@pdata, 'exit')) {
			@msg .= @pdata['exit'];
		} else {
			@msg .= 'left the game';
		}
		broadcast(_timestamp().colorize('&4\u00ab &o'.@msg));
		if(extension_exists('CHDiscord')) {
			set_timeout(1, closure(){
				@test = if(get_os() === 'WINDOWS', '[TEST SERVER]', '');
				@count = array_size(all_players());
				@msg = reg_replace('[&§][0-9a-fk-o]', '', @msg);
				discord_broadcast('minecraft_chat', array(embed: array(
					color: array(r: 126, g: 45, b: 35),
					author: array(
						name: "\u00ab@test @msg (@count)",
						icon_url: 'http://liam.fragify.net:30027/tiles/faces/32x32/'.player().'.png'))));
			});
		}
	}
	try {
		@pdata['world'] = pworld();
		_store_pdata(@event['player'], @pdata);
	} catch(PlayerOfflineException @e) {
		msg('Cannot fetch player world while quitting.');
	}
	export('pdata.'.to_lower(@event['player']), null); // clear player data cache
	export('session.'.player(), null); // clear player state data
	// clear aliases used for autocompletion
	if(array_index_exists(@pdata, 'names')) {
		@players = import('players', associative_array());
		foreach(@name in @pdata['names']) {
			array_remove(@players, to_lower(@name));
		}
		export('players', @players);
	}

	// Exit effect
	if(array_index_exists(@pdata, 'exiteffect')) {
		if(all_players(@pdata['world'])) {
			@loc = ploc();
			switch(@pdata['exiteffect']) {
				case 'lightning':
					lightning(@loc, true);
				case 'smoke':
					spawn_particle(location_shift(@loc, 'up', 2), array(
						particle: 'CAMPFIRE_COSY_SMOKE',
						count: 150,
						speed: 0.01,
						yoffset: 2.5,
						xoffset: 1.5,
						zoffset: 1.5));
			}
		}
	}
}
