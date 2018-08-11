include('words.ms');
include('rounds.ms');
include('utils.ms');
include('events.ms');

proc _prepare_game(@category) {
	@categories = _get_categories();
	if(@category) {
		if(!array_contains(@categories, @category)) {
			die(color('yellow').'Available categories: '.array_implode(@categories, ', ').'.');
		}
	} else {
		@category = array_rand(@categories, 1, false)[0];
	}
	
	@players = array();
	foreach(@p in all_players('custom')) {
		if(array_contains(sk_current_regions(@p), 'charades')) {
			@players[] = @p;
		}
	}
	if(array_size(@players) < 3) {
		die(color('gold').'Requires at least 3 players.');
	}
	
	export('charades', array(
		'category': @category,
		'players': @players,
		'playersLeft': @players[],
		'interval': 0,
		'votes': associative_array(),
		'seconds': 150.0,
		'build': '',
		'hint': '',
	));
	
	create_scoreboard('charades');
	create_objective('score', 'DUMMY', 'charades');
	set_objective_display('score', array('displayname': 'Scores', 'slot': 'SIDEBAR'), 'charades');
	create_team('guessers', 'charades');
	create_team('builder', 'charades');
	set_team_display('builder', array('prefix': color('green')), 'charades');
	
	@spawn = sk_region_info('charades-beacon', 'custom', 0)[0];
	foreach(@p in @players) {
		set_pscore('score', @p, 0, 'charades');
		team_add_player('guessers', @p, 'charades');
		title(@p, 'Charades', to_upper(@category), 20, 60, 40);
		set_ploc(@p, @spawn);
		set_pmode(@p, 'SPECTATOR');
		set_pscoreboard(@p, 'charades');
		_set_pactivity(@p, 'charades');
	}
	
	set_block(@spawn, 'SEA_LANTERN');
	
	_bind_charade_events();
	try {
		_queue_next_builder();
	} catch(Exception @ex) {
		console('Exception encountered in Charades.', false);
		console(@ex['classType'].': '.@ex['message'], false);
		foreach(@trace in @ex['stackTrace']) {
			console(split('LocalPackages', @trace['file'])[-1].':'.@trace['line'].' '.@trace['id'], false);
		}
		_end_game();
	}
}

proc _end_game() {
	@charades = import('charades');
	if(@charades['interval']) {
		clear_task(@charades['interval']);
	}
	
	@center = sk_region_info('charades-beacon', 'custom', 0)[0];
	set_block(@center, 'LIGHT_BLUE_STAINED_GLASS');
	play_sound(@center, array('sound': 'UI_TOAST_CHALLENGE_COMPLETE', 'volume': 5));
	
	@top = 0;
	@topPlayers = array();
	@warp = get_value('warp.charades');
	foreach(@t in get_teams('charades')) {
		foreach(@p in @t['players']) {
			@s = get_pscore('score', @p, 'charades');
			if(@s > @top) {
				@top = @s;
				foreach(@index: @player in @topPlayers) {
					array_remove(@topPlayers, @index);
				}
				@topPlayers[] = @p;
			} else if(@s == @top) {
				@topPlayers[] = @p;
			}
			if(ponline(@p)) {
				set_ploc(@p, @warp);
				_equip_kit(@p);
				_set_pactivity(@p, null);
			}
		}
	}
	
	if(array_size(@topPlayers) == 1) {
		_regionmsg('charades', color('green').@topPlayers[0].' wins!');
	} else if(array_size(@topPlayers) > 1) {
		_regionmsg('charades', color('green').array_implode(@topPlayers, ' and ').' tied for the win!');
	} else {
		_regionmsg('charades', color('yellow').'Nobody wins! I\'M NOT SURE HOW THIS IS POSSIBLE. IS ANYONE THERE? WHY AM I YELLING?!');
	}
	_unbind_charade_events();
	export('charades', null);
	remove_scoreboard('charades');
}
