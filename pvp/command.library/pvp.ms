register_command('pvp', array(
	'description': 'Starting and managing active PVP games.',
	'usage': '/pvp <join|start|vote|debug|spectate|addtime|end> <game_id> [value]',
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		if(array_size(@args) == 1) {
			return(_strings_start_with_ic(array('join', 'start', 'vote', 'debug', 'spectate', 'addtime', 'end'), @args[-1]));
		}
		return(array());
	},
	'executor': closure(@alias, @sender, @args, @info) {
		if(array_size(@args) < 2) {
			return(false);
		}
		switch(@args[0]) {
			case 'join':
				include('../core.library/join.ms');
				_pvp_join(to_lower(@args[1]));

			case 'debug':
				@id = to_lower(@args[1]);
				@pvp = import('pvp'.@id);
				if(is_null(@pvp)) {
					die(color('gold').'That arena doesn\'t seem to be running.');
				}
				foreach(@key: @value in @pvp) {
					msg(@key.': '.color('gray').@value);
				}

			case 'vote':
				@id = to_lower(@args[1]);
				@pvp = import('pvp'.@id);
				if(!@pvp) {
					die(color('yellow').'Game is not queued.');
				}
				if(!array_index_exists(@pvp['players'], player())) {
					die(color('yellow').'You haven\'t joined.');
				}
				if(array_size(@args) < 3) {
					die(color('gold').'You need to specify an arena.');
				}
				@pvp['players'][player()]['arena'] = @args[2];
				msg(color('green').'You voted for '.to_upper(@args[2]).'.');

			case 'spectate':
				if(_is_survival_world(pworld())) {
					die(color('gold').'You are not in Frog Park.');
				}
				@id = to_lower(@args[1]);
				@pvp = import('pvp'.@id);
				if(!@pvp || !@pvp['running']) {
					die(color('gold').'Game is not running.');
				}
				if(array_index_exists(@pvp['players'], player())) {
					die(color('gold').'You\'re already in the game.');
				}
				if(!array_contains(get_scoreboards(), @id)) {
					die(color('gold').'The arena isn\'t running.');
				}
				if(!_set_pstate_activity(player(), to_upper(@id))) {
					die(color('gold').'You\'re in another game.');
				}
				include('../core.library/spectator.ms');
				set_pscoreboard(player(), @id);
				@pvp = import('pvp'.@id);
				if(array_index_exists(@pvp['arena'], 'resourcepack')) {
					send_resourcepack(player(), 'http://mc.finalscoremc.com:25966/resourcepacks/'.@pvp['arena']['resourcepack'].'.zip');
				}
				_set_spectator(player(), @pvp);

			case 'addtime':
				if(!get_command_block() && !has_permission('group.moderator')) {
					die();
				}
				@id = to_lower(@args[1]);
				@pvp = import('pvp'.@id);
				if(!@pvp) {
					die();
				}
				if(array_size(@args) < 3) {
					die();
				}
				@pvp['arena']['timer'][1] += @args[2];
				if(extension_exists('CHNaughty')) {
					foreach(@p in array_merge(array_keys(@pvp['players']), @pvp['spectators'])) {
						try {
							title_msg(@p, 'Added '.@arg.' minutes', null, 20, 20, 20);
						} catch(PlayerOfflineException @ex) {
							// we'll remove them elsewhere
						}
					}
				}

			case 'start':
				@id = to_lower(@args[1]);
				@pvp = import('pvp'.@id);
				if(!@pvp) {
					die(color('gold').'There is no match to start.');
				}
				if(@pvp['running']) {
					die(color('gold').'Match already in progress.');
				}
				if(!array_index_exists(@pvp['players'], player())) {
					die(color('yellow').'You have not joined.');
				}
				# Get arena settings
				@pvp['arena'] = get_value('arena', @id);
				if(is_null(@pvp['arena'])) {
					die(color('gold').'Can\'t find that arena.');
				}
				include('../core.library/start.ms');
				_pvp_start(@pvp, @id);

			case 'end':
				if(!get_command_block() && !has_permission('group.builder')) {
					die(color('gold').'You do not have permission.');
				}
				@id = to_lower(@args[1]);
				@pvp = import('pvp'.@id);
				if(!@pvp || @pvp['running'] < 2) {
					die(color('gold').'Not running.');
				}
				include('../core.library/game.ms');
				if(array_size(@args) > 2 && is_numeric(@args[2])) {
					_pvp_end_match(@id, @pvp['team'][@args[2] - 1]['players']);
				} else {
					_pvp_end_match(@id, array());
				}

			default:
				return(false);
		}
	}
));
