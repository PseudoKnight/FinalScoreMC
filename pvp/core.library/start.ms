proc _pvp_start(@pvp, @id){
	if(array_index_exists(@pvp['arena'], 'options')) {
		del_virtualchest(@id.'options');
		unbind(@id.'options');
	}

	@childid = '';
	@picked = '';
	if(array_index_exists(@pvp['arena'], 'arenaselect') && @pvp['arena']['arenaselect']['type'] == 'vote') {
		@voted = array_filter(@pvp['players'], closure(@key, @value){
			return(array_index_exists(@value, 'arena'));
		});
		@picked = array_get(array_rand(@voted), 0, '');
		if(@picked) {
			@childid = @pvp['players'][@picked]['arena'];
		}

		// Store total votes
		if(!array_index_exists(@pvp['arena'], 'arenavotes')) {
			@pvp['arena']['arenavotes'] = associative_array();
		}
		foreach(@vote in @voted) {
			if(!array_index_exists(@pvp['arena']['arenavotes'], @vote['arena'])) {
				@pvp['arena']['arenavotes'][@vote['arena']] = 1;
			} else {
				@pvp['arena']['arenavotes'][@vote['arena']] += 1;
			}
		}
		store_value('arena', @id, @pvp['arena']);
	}

	# Set defaults
	@defaults = associative_array(
		'mode': 'dm',
		'ff': 'true',
		'flags': array(),
		'respawnmode': 'normal',
		'delay': 10,
	);
	@pvp['arena'] = array_merge(@defaults, @pvp['arena']);

	# Get child or parent arena settings
	if(array_index_exists(@pvp['arena'], 'parent')) {
		@parent = get_value('arena.'.@pvp['arena']['parent']);
		if(!@parent) {
			die('Can\'t find parent arena.');
		}
		@primaryName = to_upper(@pvp['arena']['parent']);
		@secondaryName = to_upper(@id);
		@pvp['arena'] = array_merge(@parent, @pvp['arena']);
	} else if(array_index_exists(@pvp['arena'], 'arenaselect')) {
		if(!@childid) {
			@childid = array_rand(@pvp['arena']['arenaselect']['arenas'], 1, false)[0];
		}
		@child = get_value('arena', @childid);
		if(!@child) {
			die('Can\'t find child arena.');
		}
		@primaryName = to_upper(@id);
		@secondaryName = to_upper(@childid);
		@pvp['arena'] = array_merge(@pvp['arena'], @child);
	} else {
		@primaryName = to_upper(@id);
		@secondaryName = null;
	}

	@arena = @pvp['arena'];

	if(array_index_exists(@arena, 'sharedarenas')) {
		foreach(@arenaid in @arena['sharedarenas']) {
			@otherpvp = import('pvp'.@arenaid);
			if(@otherpvp && @otherpvp['running']) {
				die('Another PVP match is running in that region.');
			}
		}
	}

	# Check if arena is in testing
	if(array_contains(@arena['flags'], 'debug')
	&& !has_permission('group.builder')) {
		die('This arena is still in testing and can only be started by Builders.');
	}

	# Check if enough players and teleport them to lobby
	foreach(@p in array_keys(@pvp['players'])) {
		if(!ponline(@p) || _is_survival_world(pworld(@p)) || _psession(@p)['activity']) {
			array_remove(@pvp['players'], @p);
		}
	}
	if(array_size(@pvp['players']) < if(array_index_exists(@arena, 'min'), @arena['min'], 2)) {
		die('There aren\'t enough players. ('.array_size(@pvp['players']).')');
	}

	# Check arena settings
	if(!array_index_exists(@arena, 'lobby'), die('No lobby defined for arena.'));
	if(!array_index_exists(@arena, 'region'), die('No region defined for arena.'));

	@pvp['binds'] = array();

	# Configure remaining arena settings
	if(array_contains(@arena['flags'], 'keepinventory'), @arena['denydrop'] = 'all');
	if(array_index_exists(@arena, 'classes')) {
		if(array_size(@arena['classes']) > 1){
			@arena['delay'] = 45;
		}
		if(!array_index_exists(@arena, 'class_picking'), @arena['class_picking'] = 'player');
	}

	# Dynamically determine if it should be a team game
	if(@arena['mode'] === 'ddm' || @arena['mode'] === 'koth') {
		if(@arena['mode'] == 'ddm') {
			@arena['mode'] = 'dm';
		}
		@size = array_size(@pvp['players']);
		if(@size > 3 && @size % 2 == 0) {
			if(!array_index_exists(@arena, 'team')) {
				@arena['team'] = array(
					array('name': 'Red', 'color': 'c'),
					array('name': 'Blue', 'color': '3')
				);
			}
			
			if(array_index_exists(@arena, 'kit')) {
				@arena['kit'][1] = @arena['kit'][0];
			}

		} else if(array_index_exists(@arena, 'team')) {
			array_remove(@arena, 'team');
		}
	}

	if(array_index_exists(@arena, 'team')) {
		@arena['team'][0]['color'] = color(@arena['team'][0]['color']);
		@arena['team'][1]['color'] = color(@arena['team'][1]['color']);
		
		// Alternate spawns
		if(array_size(@arena['spawn']) == 1 || !@arena['spawn'][1]) {
			@oldspawns = @arena['spawn'][0][];
			@arena['spawn'] = array(array(), array());
			@team = 0;
			foreach(@spawn in @oldspawns) {
				@arena['spawn'][@team][] = @spawn;
				@team = if(@team == 0, 1, 0);
			}
		// or remove excess spawn groups
		} else {
			while(array_size(@arena['spawn']) > 2) {
				array_remove(@arena['spawn'], rand(array_size(@arena['spawn'])));
			}
			@arena['spawn'] = array_normalize(@arena['spawn']);
		}
	} else {
		// Merge spawns, if needed
		if(array_size(@arena['spawn']) > 1 && @arena['spawn'][1]) {
			@size = array_size(@arena['spawn'][0]);
			@newSpawns = array();
			for(@i = 0, @i < @size, @i++) {
				foreach(@spawns in @arena['spawn']) {
					@newSpawns[] = @spawns[@i];
				}
			}
			@arena['spawn'][0] = @newSpawns;
		}
	}
	
	if(!array_index_exists(@arena, 'score')) {
		switch(@arena['mode']) {
			case 'ctf':
				@arena['score'] = 5;
			case 'koth':
				@arena['score'] = 60;
		}
	}
	
	if(@arena['mode'] == 'koth') {
		if(!array_index_exists(@pvp, 'team') && array_size(@pvp['players']) > 4) {
			@arena['score'] = integer(@arena['score'] / 2);
		}
	}
	
	if(array_index_exists(@arena, 'rounds')) {
		@pvp['round'] = 1;
	}

	if(array_contains(get_scoreboards(), @id)) {
		remove_scoreboard(@id);
	}
	create_scoreboard(@id);

	if(array_contains(@arena['flags'], 'heartsdisplay')) {
		create_objective('health', 'HEALTH', @id);
		set_objective_display('health', associative_array('displayname': color(4).'\u2764', 'slot': 'BELOW_NAME'), @id);
	}

	# PREPARE TEAMS
	if(array_index_exists(@arena, 'team')) {
		if(array_index_exists(@arena, 'score')) {
			@pvp['team'][1]['score'] = 0;
			@pvp['team'][0]['score'] = 0;
		}
		if(@arena['mode'] === 'ctf') {
			@pvp['team'][0]['flag'] = 0;
			@pvp['team'][1]['flag'] = 0;
		}
		if(array_index_exists(@arena, 'captain')) {
			@pvp['team'][0]['hatentity'] = 0;
			@pvp['team'][1]['hatentity'] = 0;
			@pvp['team'][0]['captain'] = '';
			@pvp['team'][1]['captain'] = '';
		}
		create_team(@arena['team'][0]['name'], @id);
		create_team(@arena['team'][1]['name'], @id);
		set_team_display(@arena['team'][0]['name'], array('prefix': @arena['team'][0]['color']), @id);
		set_team_display(@arena['team'][1]['name'], array('prefix': @arena['team'][1]['color']), @id);
		set_team_options(@arena['team'][0]['name'], array(
			'friendlyinvisibles': true,
			'nametagvisibility': if(array_index_exists(@arena, 'nametags'), @arena['nametags'][0], 'ALWAYS')
		), @id);
		set_team_options(@arena['team'][1]['name'], array(
			'friendlyinvisibles': true,
			'nametagvisibility': if(array_index_exists(@arena, 'nametags'), @arena['nametags'][1], 'ALWAYS')
		), @id);
	}

	switch(@arena['mode']) {
		case 'koth':
			create_objective('seconds', 'DUMMY', @id);
			set_objective_display('seconds', array('displayname': colorize(array_get(@arena, 'goalname', '&aSeconds Left')), 'slot': 'SIDEBAR'), @id);
			if(array_index_exists(@arena, 'team')) {
				team_add_player(@arena['team'][0]['name'], @arena['team'][0]['name'], @id);
				set_pscore('seconds', @arena['team'][0]['name'], neg(@arena['score']), @id);
				team_add_player(@arena['team'][1]['name'], @arena['team'][1]['name'], @id);
				set_pscore('seconds', @arena['team'][1]['name'], neg(@arena['score']), @id);
			} else {
				create_team('king', @id);
				set_team_display('king', array('prefix': color('green')), @id);
			}
		case 'dm':
			if(array_index_exists(@arena, 'lives') && @arena['lives'] > 1) {
				create_objective('lives', 'DUMMY', @id);
				set_objective_display('lives', array('displayname': colorize(array_get(@arena, 'goalname', '&aLives Left')), 'slot': 'SIDEBAR'), @id);
			}
			if(@arena['respawnmode'] == 'mob') {
				create_objective('respawns', 'DUMMY', @id);
				set_objective_display('respawns', array('displayname': colorize(array_get(@arena, 'goalname', '&aRespawns Left')), 'slot': 'SIDEBAR'), @id);
			}
			if(array_index_exists(@arena, 'mobprotect')) {
				create_objective('mobhealth', 'DUMMY', @id);
				set_objective_display('mobhealth', array('displayname': colorize(array_get(@arena, 'goalname', '&aMob Health')), 'slot': 'SIDEBAR'), @id);
				team_add_player(@arena['team'][0]['name'], @arena['team'][0]['name'], @id);
				team_add_player(@arena['team'][1]['name'], @arena['team'][1]['name'], @id);
			}
			if(array_index_exists(@arena, 'score')) {
				create_objective('score', 'DUMMY', @id);
				set_objective_display('score', array('displayname': colorize(array_get(@arena, 'goalname', '&aScore')), 'slot': 'SIDEBAR'), @id);
				if(array_index_exists(@pvp, 'team')) {
					team_add_player(@arena['team'][0]['name'], @arena['team'][0]['name'], @id);
					set_pscore('score', @arena['team'][0]['name'], 0, @id);
					team_add_player(@arena['team'][1]['name'], @arena['team'][1]['name'], @id);
					set_pscore('score', @arena['team'][1]['name'], 0, @id);
				}
			}
			if(array_index_exists(@arena, 'blockbreak')) {
				create_objective('blocks', 'DUMMY', @id);
				set_objective_display('blocks', array('displayname': colorize(array_get(@arena, 'goalname', '&aBlocks')), 'slot': 'SIDEBAR'), @id);
				team_add_player(@arena['team'][0]['name'], @arena['team'][0]['name'], @id);
				set_pscore('blocks', @arena['team'][0]['name'], array_size(@arena['blockbreak'][0]), @id);
				team_add_player(@arena['team'][1]['name'], @arena['team'][1]['name'], @id);
				set_pscore('blocks', @arena['team'][1]['name'], array_size(@arena['blockbreak'][1]), @id);
			}
		case 'ctf':
			create_objective('captures', 'DUMMY', @id);
			set_objective_display('captures', array('displayname': colorize(array_get(@arena, 'goalname', '&aCaptures ('.@arena['score'].')')), 'slot': 'SIDEBAR'), @id);
			team_add_player(@arena['team'][0]['name'], @arena['team'][0]['name'], @id);
			set_pscore('captures', @arena['team'][0]['name'], 0, @id);
			team_add_player(@arena['team'][1]['name'], @arena['team'][1]['name'], @id);
			set_pscore('captures', @arena['team'][1]['name'], 0, @id);
	}

	include('game.ms');

	if(array_index_exists(@arena, 'team')) {
		if(!array_index_exists(@pvp, 'team')) {
			@pvp['team'] = array(associative_array(), associative_array());
		}
		if(!array_index_exists(@pvp['team'][0], 'players')) {
			@pvp['team'][0]['players'] = array();
			@pvp['team'][1]['players'] = array();
		}
		if(!array_index_exists(@arena, 'teamratio')) {
			@arena['teamratio'] = array(1, 1);
		}
		@players = array_keys(@pvp['players']);
		// first make sure solo player doesn't end up on the same team as last game
		if(array_index_exists(@pvp, 'lastsolo') && array_contains(@players, @pvp['lastsolo'])) {
			@player = @pvp['lastsolo'];
			@team = abs(array_index(@pvp['arena']['teamratio'], 1) - 1);
			@pvp['players'][@player]['team'] = @team;
			@pvp['team'][@team]['players'][] = @player;
			array_remove_values(@players, @player);
		}
		@size = array_size(@players);
		for(@i = 0, @i < @size, @i++) {
			@index = rand(0, array_size(@players));
			@player = @players[@index];
			_player_assign_team(@player, @pvp);
			array_remove(@players, @index);
		}
	}

	if(array_index_exists(@arena, 'captain')) {
		@pvp['team'][0]['captainhat'] = @arena['classes'][@arena['captain'][0]]['kit'][103];
		@pvp['team'][1]['captainhat'] = @arena['classes'][@arena['captain'][1]]['kit'][103];
	}

	if(array_index_exists(@arena, 'resourcepack')) {
		set_timeout(50, closure(){
			foreach(@p in array_keys(@pvp['players'])) {
				send_resourcepack(@p, 'http://mc.finalscoremc.com:25966/resourcepacks/'.@arena['resourcepack'].'.zip');
			}
		});
	}

	@pvp['coins'] = if(array_size(@pvp['players']) > 2, 1, 0);
	if(!array_index_exists(@arena, 'stats')) {
		@pvp['stats'] = associative_array();
	}

	@pvp['spectators'] = array();
	@pvp['running'] = 1;

	# CLASSES
	if(array_index_exists(@arena, 'classes')) {
		_class_select(@id, @pvp);
	}
	
	# ARENA
	if(array_contains(@pvp['arena']['flags'], 'script')){
		_prepare_arena(@pvp);
	}

	# ANNOUNCE
	@title = @primaryName.if(@secondaryName, ': '.@secondaryName);
	@world = @arena['lobby'][3];
	_worldmsg(@world, _fill_string('*', '-', colorize('&7&m|--&7&l[ &r&l'.@title.' &7&l]&7&m*|')));

	if(array_index_exists(@pvp, 'team')) {
		_worldmsg(@world,
			@arena['team'][0]['color'].'['.@arena['team'][0]['name'].'] '.
			array_implode(@pvp['team'][0]['players'], ' ').'\n'.color('r').
			@arena['team'][1]['color'].'['.@arena['team'][1]['name'].'] '.
			array_implode(@pvp['team'][1]['players'], ' ')
		);
	} else {
		_worldmsg(@world, color('gold').' '.array_implode(array_keys(@pvp['players']), colorize('&r vs &6')));
	}
	if(array_index_exists(@arena, 'lives')) {
		_pvp_msg(@pvp, colorize('* &e&l'.@arena['lives'].if(@arena['lives'] > 1, ' LIVES', ' LIFE')));
	}
	if(array_index_exists(@arena, 'class_picking') && @arena['class_picking'] === 'random') {
		_pvp_msg(@pvp, colorize('* &e&lALL RANDOM CLASSES'));
	}
	if(array_index_exists(@arena, 'class_picks') &&
	(!array_index_exists(@arena, 'lives') || @arena['class_picks'] < @arena['lives'])) {
		_pvp_msg(@pvp, colorize('* &e&l'.@arena['class_picks'].' CLASS PICKS'));
	}
	if(@picked) {
		_pvp_msg(@pvp, colorize('* &e&lArena picked by '.@picked));
	}
	_worldmsg(@world, colorize('&7&m|----------------------------------------------------|'));

	play_sound(@arena['lobby'], array('sound': 'WITHER_SPAWN', 'pitch': 1.5, 'volume': 3, 'category': 'VOICE'));

	_add_activity('pvp'.@id, @title);

	# COUNTDOWN TO START
	@timeleft = array(@arena['delay']);
	if(has_bind(@id.'classselector')) {
		create_bar(@id, array(
			'title': color('yellow').'Choosing classes...',
			'percent': 0.0,
			'style': 'SOLID',
			'color': 'YELLOW',
		));
	} else {
		create_bar(@id, array(
			'title': color('green').'Starting game...',
			'percent': 0.0,
			'style': 'SEGMENTED_6',
			'color': 'GREEN',
		));
	}
	foreach(@p in array_keys(@pvp['players'])) {
		bar_add_player(@id, @p);
	}
	set_interval(1000, closure(){
		@timeleft[0] -= 1;;
		if(@timeleft[0] > 0) {
			if(@timeleft[0] <= 5) {
				play_sound(@arena['lobby'], array('sound': 'NOTE_PLING', 'pitch': 1, 'volume': 3));
				update_bar(@id, array('percent': (6 - @timeleft[0]) / 6));
				foreach(@p in array_keys(@pvp['players'])) {
					try {
						title(@p, color('yellow').@timeleft[0], @title, 0, @timeleft[0] * 20, 20);
					} catch(PlayerOfflineException @ex) {
						// they quit during the countdown.
						// performance anxiety.
					}
				}
			} else if(@timeleft[0] > 6 && array_index_exists(@arena, 'classes') && array_size(@arena['classes']) > 1) {
				@choosing = false;
				foreach(@p in array_keys(@pvp['players'])) {
					if(ponline(@p) && !is_null(pget_virtualchest(@p))) {
						@choosing = true;
						break();
					}
				}
				if(!@choosing) {
					update_bar(@id, array('title': color('green').'Starting game...', 'style': 'SEGMENTED_6', 'percent': 0.0, 'color': 'GREEN'));
					@timeleft[0] = 6;
				} else {
					update_bar(@id, array('percent': (@arena['delay'] - @timeleft[0]) / @arena['delay']));
				}
			}
		} else {
			remove_bar(@id);
			foreach(@p in array_keys(@pvp['players'])) {
				try {
					title(@p, color('green').'GO!', null, 0, 0, 20);
				} catch(PlayerOfflineException @ex) {
					// tease.
				}
			}
			clear_task();
			@pvp['running'] = 2;
			_pvp_start_match(@id);
		}
	});
}
