proc _pvp_start(@pvp, @id){
	if(array_index_exists(@pvp['arena'], 'options')) {
		del_virtualchest(@id.'options');
		unbind(@id.'options');
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
		@childid = array_rand(@pvp['arena']['arenaselect']['arenas'], 1, false)[0];
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

	if(array_index_exists(@pvp['arena'], 'sharedarenas')) {
		foreach(@arenaid in @pvp['arena']['sharedarenas']) {
			@otherpvp = import('pvp'.@arenaid);
			if(@otherpvp && @otherpvp['running']) {
				die('Another PVP match is running in that region.');
			}
		}
	}

	# Check if arena is in testing
	if(array_contains(@pvp['arena']['flags'], 'debug')
	&& !has_permission('group.builder')) {
		die('This arena is still in testing and can only be started by Builders.');
	}

	# Check if enough players and teleport them to lobby
	foreach(@p in array_keys(@pvp['players'])) {
		if(!ponline(@p) || pworld(@p) !== 'custom') {
			array_remove(@pvp['players'], @p);
		} else {
			set_ploc(@p, @pvp['arena']['lobby']); # TODO: remove once players can't join multiple games
		}
	}
	if(array_size(@pvp['players']) < if(array_index_exists(@pvp['arena'], 'min'), @pvp['arena']['min'], 2)) {
		die('There aren\'t enough players. ('.array_size(@pvp['players']).')');
	}

	# Check arena settings
	if(!array_index_exists(@pvp['arena'], 'lobby'), die('No lobby defined for arena.'));
	if(!array_index_exists(@pvp['arena'], 'region'), die('No region defined for arena.'));
	if(!array_index_exists(@pvp['arena'], 'spawn'), die('No spawns defined for arena.'));

	# Configure remaining arena settings
	if(!array_index_exists(@pvp['arena'], 'broadcast'), @pvp['arena']['broadcast'] = @pvp['arena']['region']);
	if(array_contains(@pvp['arena']['flags'], 'keepinventory'), @pvp['arena']['denydrop'] = 'all');
	if(array_index_exists(@pvp['arena'], 'classes')) {
		@pvp['arena']['delay'] = 45;
		if(!array_index_exists(@pvp['arena'], 'class_picking'), @pvp['arena']['class_picking'] = 'player');
	}

	# Dynamically determine if it should be a team game
	if(@pvp['arena']['mode'] === 'ddm') {
		@size = array_size(@pvp['players']);
		if(@size > 5 && @size % 2 == 0) {
			@pvp['arena']['mode'] = 'tdm';
			@pvp['arena']['ff'] = false;
			if(array_index_exists(@pvp['arena'], 'kit')) {
				@pvp['arena']['kit'][1] = @pvp['arena']['kit'][0];
			}

			@spawns = @pvp['arena']['spawn'][0][];
			@pvp['arena']['spawn'] = array();
			@team = 0;
			foreach(@spawn in @spawns) {
				@pvp['arena']['spawn'][@team] = @spawn;
			}

		} else {
			@pvp['arena']['mode'] = 'dm';
		}
	}

	if(!array_index_exists(@pvp['arena'], 'team') && array_contains(array('ctf', 'tdm', 'infection'), @pvp['arena']['mode'])) {
		@pvp['arena']['team'] = array(
			array('name': 'Red', 'color': color('c')),
			array('name': 'Blue', 'color': color('3'))
		);
	} else if(array_index_exists(@pvp['arena'], 'team')) {
		@pvp['arena']['team'][0]['color'] = color(@pvp['arena']['team'][0]['color']);
		@pvp['arena']['team'][1]['color'] = color(@pvp['arena']['team'][1]['color']);
	}
	if(!array_index_exists(@pvp['arena'], 'score')) {
		switch(@pvp['arena']['mode']) {
			case 'ctf':
				@pvp['arena']['score'] = 5;
			case 'koth':
				@pvp['arena']['score'] = 60;
		}
	}

	if(array_contains(get_scoreboards(), @id)) {
		remove_scoreboard(@id);
	}
	create_scoreboard(@id);

	# PREPARE TEAMS
	if(array_index_exists(@pvp['arena'], 'team')) {
		if(@pvp['arena']['mode'] === 'ctf') {
			@pvp['team'][0]['score'] = 0;
			@pvp['team'][0]['flag'] = 0;
			@pvp['team'][1]['score'] = 0;
			@pvp['team'][1]['flag'] = 0;
		}
		if(array_index_exists(@pvp['arena'], 'captain')) {
			@pvp['team'][0]['hatentity'] = 0;
			@pvp['team'][1]['hatentity'] = 0;
			@pvp['team'][0]['captain'] = '';
			@pvp['team'][1]['captain'] = '';
		}
		create_team(@pvp['arena']['team'][0]['name'], @id);
		create_team(@pvp['arena']['team'][1]['name'], @id);
		set_team_display(@pvp['arena']['team'][0]['name'], array('prefix': @pvp['arena']['team'][0]['color']), @id);
		set_team_display(@pvp['arena']['team'][1]['name'], array('prefix': @pvp['arena']['team'][1]['color']), @id);
		set_team_options(@pvp['arena']['team'][0]['name'], array(
			'friendlyinvisibles': true,
			'nametagvisibility': if(array_index_exists(@pvp['arena'], 'nametags'), @pvp['arena']['nametags'][0], 'ALWAYS')
		), @id);
		set_team_options(@pvp['arena']['team'][1]['name'], array(
			'friendlyinvisibles': true,
			'nametagvisibility': if(array_index_exists(@pvp['arena'], 'nametags'), @pvp['arena']['nametags'][1], 'ALWAYS')
		), @id);
	}

	switch(@pvp['arena']['mode']) {
		case 'koth':
			create_objective('seconds', 'DUMMY', @id);
			set_objective_display('seconds', array('displayname': color('a').'Seconds Left', 'slot': 'SIDEBAR'), @id);
		case 'tdm':
		case 'dm':
			if(array_index_exists(@pvp['arena'], 'lives') && @pvp['arena']['lives'] > 1) {
				create_objective('lives', 'DUMMY', @id);
				set_objective_display('lives', array('displayname': color('a').'Lives Left', 'slot': 'SIDEBAR'), @id);
			}
			if(@pvp['arena']['respawnmode'] == 'mob') {
				create_objective('respawns', 'DUMMY', @id);
				set_objective_display('respawns', array('displayname': color('a').'Respawns Left', 'slot': 'SIDEBAR'), @id);
			}
			if(array_index_exists(@pvp['arena'], 'mobprotect')) {
				create_objective('mobhealth', 'DUMMY', @id);
				set_objective_display('mobhealth', array('displayname': color('a').'Mob Health', 'slot': 'SIDEBAR'), @id);
				team_add_player(@pvp['arena']['team'][0]['name'], @pvp['arena']['team'][0]['name'], @id);
				team_add_player(@pvp['arena']['team'][1]['name'], @pvp['arena']['team'][1]['name'], @id);
			}
		case 'ctf':
			create_objective('captures', 'DUMMY', @id);
			set_objective_display('captures', array('displayname': color('a').'Captures ('.@pvp['arena']['score'].')', 'slot': 'SIDEBAR'), @id);
			team_add_player(@pvp['arena']['team'][0]['name'], @pvp['arena']['team'][0]['name'], @id);
			set_pscore('captures', @pvp['arena']['team'][0]['name'], 0, @id);
			team_add_player(@pvp['arena']['team'][1]['name'], @pvp['arena']['team'][1]['name'], @id);
			set_pscore('captures', @pvp['arena']['team'][1]['name'], 0, @id);
	}

	@pvp['binds'] = array();
	include('game.ms');

	if(array_index_exists(@pvp['arena'], 'team')) {
		if(!array_index_exists(@pvp, 'team')) {
			@pvp['team'] = array(associative_array(), associative_array());
		}
		if(!array_index_exists(@pvp['team'][0], 'players')) {
			@pvp['team'][0]['players'] = array();
			@pvp['team'][1]['players'] = array();
		}
		if(!array_index_exists(@pvp['arena'], 'teamratio')) {
			@pvp['arena']['teamratio'] = array(1, 1);
		}
		@players = array_keys(@pvp['players'])
		for(@i = 0, @i < array_size(@pvp['players']), @i++) {
			@index = rand(0, array_size(@players));
			@player = @players[@index];
			_assign_team(@player, @pvp);
			array_remove(@players, @index);
		}
	}

	if(array_index_exists(@pvp['arena'], 'captain')) {
		@pvp['team'][0]['captainhat'] = @pvp['arena']['classes'][@pvp['arena']['captain'][0]]['kit'][103];
		@pvp['team'][1]['captainhat'] = @pvp['arena']['classes'][@pvp['arena']['captain'][1]]['kit'][103];
	}

	foreach(@p in array_keys(@pvp['players'])) {
		if(array_index_exists(@pvp['arena'], 'resourcepack')) {
			send_resourcepack(@p, 'http://mc.finalscoremc.com:25966/resourcepacks/'.@pvp['arena']['resourcepack'].'.zip');
		}
	}

	@pvp['coins'] = if(array_size(@pvp['players']) > 2, 1, 0);
	if(!array_index_exists(@pvp, 'stats') || @pvp['arena']['stats']) {
		@pvp['stats'] = associative_array();
	}

	@pvp['spectators'] = array();
	@pvp['running'] = 1;

	# CLASSES
	if(array_index_exists(@pvp['arena'], 'classes')) {
		_class_select(@id, @pvp);
	}

	# ANNOUNCE
	@title = @primaryName.if(@secondaryName, ': '.@secondaryName);
	_worldmsg('custom', _fill_string('*', '-', colorize('&7&m|--&7&l[ &r&l'.@title.' &7&l]&7&m*|')));

	if(array_index_exists(@pvp, 'team')) {
		_worldmsg('custom',
			@pvp['arena']['team'][0]['color'].'['.@pvp['arena']['team'][0]['name'].'] '.
			array_implode(@pvp['team'][0]['players'], ' ').'\n'.color('r').
			@pvp['arena']['team'][1]['color'].'['.@pvp['arena']['team'][1]['name'].'] '.
			array_implode(@pvp['team'][1]['players'], ' ')
		);
	} else {
		_worldmsg('custom', color('gold').' '.array_implode(array_keys(@pvp['players']), colorize('&r vs &6')));
	}
	if(array_index_exists(@pvp['arena'], 'lives')) {
		_regionmsg(@pvp['arena']['broadcast'], colorize('- &e&l'.@pvp['arena']['lives'].' LIVES'));
	}
	if(array_index_exists(@pvp['arena'], 'class_picking') && @pvp['arena']['class_picking'] === 'random') {
		_regionmsg(@pvp['arena']['broadcast'], colorize('- &e&lALL RANDOM CLASSES'));
	}
	if(array_index_exists(@pvp['arena'], 'class_picks') &&
	(!array_index_exists(@pvp['arena'], 'lives') || @pvp['arena']['class_picks'] < @pvp['arena']['lives'])) {
		_regionmsg(@pvp['arena']['broadcast'], colorize('- &e&l'.@pvp['arena']['class_picks'].' CLASS PICKS'));
	}
	_worldmsg('custom', colorize('&7&m|----------------------------------------------------|'));

	play_sound(@pvp['arena']['lobby'], array('sound': 'WITHER_SPAWN', 'pitch': 1.5, 'volume': 3));

	_add_activity('pvp'.@id, @title);

	# COUNTDOWN TO START
	@timeleft = array(@pvp['arena']['delay']);
	set_interval(1000, closure(){
		@timeleft[0] -= 1;;
		if(@timeleft[0] > 0) {
			if(@timeleft[0] <= 4) {
				play_sound(@pvp['arena']['lobby'], array('sound': 'NOTE_PLING', 'pitch': 1, 'volume': 3));
				if(extension_exists('CHNaughty')) {
					foreach(@p in array_keys(@pvp['players'])) {
						try {
							title_msg(@p, color('yellow').@timeleft[0], null, 0, @timeleft[0] * 20, 20);
						} catch(PlayerOfflineException @ex) {
							// they quit during the countdown.
							// performance anxiety.
						}
					}
				}
			} else if(@timeleft[0] > 5 && array_index_exists(@pvp['arena'], 'classes')) {
				@choosing = false;
				foreach(@p in array_keys(@pvp['players'])) {
					if(ponline(@p) && !is_null(pget_virtualchest(@p))) {
						@choosing = true;
						break();
					}
				}
				if(!@choosing) {
					@timeleft[0] = 5;
				}
			} else if(@timeleft[0] > 4) {
				if(extension_exists('CHNaughty')) {
					foreach(@p in array_keys(@pvp['players'])) {
						try {
							action_msg(@p, 'Starting in '.@timeleft[0]).'...');
						} catch(PlayerOfflineException @ex) {
							// they quickly left after someone started the game.
							// forgot their dentist appointment.
						}
					}
				}
			}
			if(@timeleft[0] == 4) {
				if(extension_exists('CHNaughty')) {
					foreach(@p in array_keys(@pvp['players'])) {
						try {
							title_msg(@p, null, @title, 20, 60, 20);
						} catch(PlayerOfflineException @ex) {
							// ignore them until later
						}
					}
				}
			}
		} else {
			if(extension_exists('CHNaughty')) {
				foreach(@p in array_keys(@pvp['players'])) {
					try {
						title_msg(@p, color('green').'GO!', null, 0, 0, 20);
					} catch(PlayerOfflineException @ex) {
						// tease.
					}
				}
			}
			clear_task();
			@pvp['running'] = 2;
			_pvp_start_match(@id);
		}
	});
}
