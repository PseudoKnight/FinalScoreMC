@arenaList = array_keys(get_values('arena'));
foreach(@i: @key in @arenaList) {
	@arenaList[@i] = split('.', @key)[1];
}
register_command('pvp', array(
	description: 'Starting and managing active PVP games.',
	usage: '/pvp <join|start|vote|spectate> <arena>',
	tabcompleter: _create_tabcompleter(
		array(
			'group.builder': array('join', 'start', 'vote', 'spectate', 'debug', 'addtime', 'end', 'stats', 'reload'),
			null: array('join', 'start', 'vote', 'spectate')),
		@arenaList
	),
	executor: closure(@alias, @sender, @args, @info) {
		if(array_size(@args) < 2) {
			return(false);
		}
		@action = @args[0];
		@id = to_lower(@args[1]);
		include_dir('core.library');
		switch(@action) {
			case 'join':
				_player_join(@id);

			case 'debug':
				@pvp = import('pvp'.@id);
				if(is_null(@pvp)) {
					die(color('gold').'That arena doesn\'t seem to be running.');
				}
				msg(map_implode(@pvp, ': '.color('gray'), '\n'));

			case 'vote':
				@pvp = import('pvp'.@id);
				if(!@pvp) {
					die(color('yellow').'Game is not queued.');
				}
				if(!array_index_exists(@pvp['players'], player())) {
					die(color('yellow').'You haven\'t joined.');
				}
				if(array_size(@args) < 4) {
					die(color('gold').'You need to specify a vote type and value.');
				}
				@type = @args[2];
				@vote = @args[3];
				@pvp['players'][player()][@type] = @vote;
				msg(color('green').'You voted for '._to_upper_camel_case(@vote).'.');

			case 'spectate':
				if(_is_survival_world(pworld())) {
					die(color('gold').'You are not in Frog Park.');
				}
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
				if(!_set_pactivity(player(), _to_upper_camel_case(@id))) {
					die(color('gold').'You\'re in another game.');
				}
				@pvp = import('pvp'.@id);
				if(array_index_exists(@pvp['arena'], 'resourcepack')) {
					@url = 'http://mc.finalscoremc.com:27836/resourcepacks/';
					send_resourcepack(player(), @url.@pvp['arena']['resourcepack'].'.zip');
				}
				_spectator_add(player(), @pvp);

			case 'addtime':
				if(!get_command_block() && !has_permission('group.builder')) {
					die();
				}
				@pvp = import('pvp'.@id);
				if(!@pvp) {
					die();
				}
				if(array_size(@args) < 3) {
					die();
				}
				@minutes = @args[2];
				@pvp['arena']['timer'][1] += @minutes;
				foreach(@p in array_merge(array_keys(@pvp['players']), @pvp['spectators'])) {
					try {
						title(@p, 'Added '.@minutes.' minutes', null, 20, 20, 20);
					} catch(PlayerOfflineException @ex) {
						// we'll remove them elsewhere
					}
				}

			case 'start':
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
				_pvp_start(@pvp);

			case 'end':
				if(!get_command_block() && !has_permission('group.builder')) {
					die(color('gold').'You do not have permission.');
				}
				@pvp = import('pvp'.@id);
				if(!@pvp || @pvp['running'] < 2) {
					die(color('gold').'Not running.');
				}
				if(array_size(@args) > 2 && is_numeric(@args[2])) {
					@team = @args[2] - 1;
					_pvp_end_match(@id, @pvp['team'][@team]['players']);
				} else {
					_pvp_end_match(@id, array());
				}
				
			case 'stats':
				@player = player();
				if(@id != 'me') {
					@player = @id;
				}
				@uuid = _get_uuid(@player);
				@pstats = get_value('pvp', @uuid);
				if(@pstats) {
					msg(color('bold').'KD Ratio: '.color('r').@pstats['kills'] / @pstats['deaths']);
					msg(color('bold').'Win/Loss: '.color('r').@pstats['wins'].':'.@pstats['losses']);
				} else {
					msg(color('gold').'No stats for '.@player);
				}
				
			case 'reload':
				if(!has_permission('group.moderator')) {
					die(color('gold').'No permission.');
				}
				foreach(@activity: @title in import('activities', array())) {
					if(string_starts_with(@activity, 'pvp')) {
						die(color('gold').'PVP is running.');
					}
				}
				@count = 0;
				if(@id == 'all') {
					@count = x_recompile_includes('');
				} else if(@id == 'core') {
					@count = x_recompile_includes('core.library');
				} else {
					@count = x_recompile_includes('core.library/../'.@id.'.library');
				}
				msg(color('green').'Done recompiling '.@id.'! ('.@count.')');

			default:
				return(false);
		}
	}
));
