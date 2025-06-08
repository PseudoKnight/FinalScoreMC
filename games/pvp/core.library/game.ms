proc _pvp_create(@id) {
	@pvp = array(
		players: associative_array(),
		spectators: array(),
		running: 0,
		id: @id,
		binds: array(),
		coins: 0,
		arenascripts: array(),
	);
	export('pvp'.@id, @pvp);
	return(@pvp);
}

proc _pvp_start(@pvp){
	@id = @pvp['id'];

	foreach(@p in array_keys(@pvp['players'])) {
		if(!ponline(@p) || _is_survival_world(pworld(@p)) || _pbusy(@p)) {
			array_remove(@pvp['players'], @p);
		}
	}

	@arena = _arena_load(@pvp);

	if(array_index_exists(@arena, 'rounds')) {
		@pvp['round'] = 1;
	}

	if(array_contains(get_scoreboards(), @id)) {
		remove_scoreboard(@id);
	}
	create_scoreboard(@id);

	if(array_contains(@arena['flags'], 'heartsdisplay')) {
		create_objective('health', 'HEALTH', @id);
		set_objective_display('health', array(displayname: color(4).'\u2764', slot: 'BELOW_NAME'), @id);
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
		try {
			set_team_display(@arena['team'][0]['name'], array(color: @arena['team'][0]['color']), @id);
			set_team_display(@arena['team'][1]['name'], array(color: @arena['team'][1]['color']), @id);
		} catch(IllegalArgumentException @ex) {
			console('Invalid colors stored in arena: '.@id);
		}
		set_team_options(@arena['team'][0]['name'], array(
			friendlyinvisibles: true,
			nametagvisibility: if(array_index_exists(@arena, 'nametags'), @arena['nametags'][0], 'ALWAYS')
		), @id);
		set_team_options(@arena['team'][1]['name'], array(
			friendlyinvisibles: true,
			nametagvisibility: if(array_index_exists(@arena, 'nametags'), @arena['nametags'][1], 'ALWAYS')
		), @id);
	}

	switch(@arena['mode']) {
		case 'koth':
			create_objective('seconds', 'DUMMY', @id);
			set_objective_display('seconds', array(
				displayname: colorize(array_get(@arena, 'goalname', '&aSeconds Left')),
				slot: 'SIDEBAR'
			), @id);
			if(array_index_exists(@arena, 'team')) {
				team_add_player(@arena['team'][0]['name'], @arena['team'][0]['name'], @id);
				set_pscore('seconds', @arena['team'][0]['name'], neg(@arena['score']), @id);
				team_add_player(@arena['team'][1]['name'], @arena['team'][1]['name'], @id);
				set_pscore('seconds', @arena['team'][1]['name'], neg(@arena['score']), @id);
			} else {
				create_team('king', @id);
				set_team_display('king', array(color: 'GREEN'), @id);
			}
		case 'dm':
			if(array_index_exists(@arena, 'lives') && @arena['lives'] > 1) {
				create_objective('lives', 'DUMMY', @id);
				set_objective_display('lives', array(
					displayname: colorize(array_get(@arena, 'goalname', '&aLives Left')),
					slot: 'SIDEBAR'
				), @id);
			}
			if(@arena['respawnmode'] == 'mob') {
				create_objective('respawns', 'DUMMY', @id);
				set_objective_display('respawns', array(
					displayname: colorize(array_get(@arena, 'goalname', '&aRespawns Left')),
					slot: 'SIDEBAR'
				), @id);
			}
			if(array_index_exists(@arena, 'mobprotect')) {
				create_objective('mobhealth', 'DUMMY', @id);
				set_objective_display('mobhealth', array(
					displayname: colorize(array_get(@arena, 'goalname', '&aMob Health')),
					slot: 'SIDEBAR'
				), @id);
				team_add_player(@arena['team'][0]['name'], @arena['team'][0]['name'], @id);
				team_add_player(@arena['team'][1]['name'], @arena['team'][1]['name'], @id);
			}
			if(array_index_exists(@arena, 'score')) {
				create_objective('score', 'DUMMY', @id);
				set_objective_display('score', array(
					displayname: colorize(array_get(@arena, 'goalname', '&aScore')),
					slot: 'SIDEBAR'
				), @id);
				if(array_index_exists(@pvp, 'team')) {
					team_add_player(@arena['team'][0]['name'], @arena['team'][0]['name'], @id);
					set_pscore('score', @arena['team'][0]['name'], 0, @id);
					team_add_player(@arena['team'][1]['name'], @arena['team'][1]['name'], @id);
					set_pscore('score', @arena['team'][1]['name'], 0, @id);
				}
			}
			if(array_index_exists(@arena, 'blockbreak')) {
				create_objective('blocks', 'DUMMY', @id);
				set_objective_display('blocks', array(
					displayname: colorize(array_get(@arena, 'goalname', '&aBlocks')),
					slot: 'SIDEBAR'
				), @id);
				team_add_player(@arena['team'][0]['name'], @arena['team'][0]['name'], @id);
				set_pscore('blocks', @arena['team'][0]['name'], array_size(@arena['blockbreak'][0]), @id);
				team_add_player(@arena['team'][1]['name'], @arena['team'][1]['name'], @id);
				set_pscore('blocks', @arena['team'][1]['name'], array_size(@arena['blockbreak'][1]), @id);
			}
		case 'ctf':
			create_objective('captures', 'DUMMY', @id);
			set_objective_display('captures', array(
				displayname: colorize(array_get(@arena, 'goalname', '&aCaptures ('.@arena['score'].')')),
				slot: 'SIDEBAR'
			), @id);
			team_add_player(@arena['team'][0]['name'], @arena['team'][0]['name'], @id);
			set_pscore('captures', @arena['team'][0]['name'], 0, @id);
			team_add_player(@arena['team'][1]['name'], @arena['team'][1]['name'], @id);
			set_pscore('captures', @arena['team'][1]['name'], 0, @id);
		case 'bombingrun':
			create_objective('bombs', 'DUMMY', @id);
			set_objective_display('bombs', array(
				displayname: colorize(array_get(@arena, 'goalname', '&aBombs ('.@arena['score'].')')),
				slot: 'SIDEBAR'
			), @id);
			team_add_player(@arena['team'][0]['name'], @arena['team'][0]['name'], @id);
			set_pscore('bombs', @arena['team'][0]['name'], 0, @id);
			team_add_player(@arena['team'][1]['name'], @arena['team'][1]['name'], @id);
			set_pscore('bombs', @arena['team'][1]['name'], 0, @id);
	}

	if(array_index_exists(@arena, 'team')) {
		@arena['team'][0]['color'] = color(@arena['team'][0]['color']);
		@arena['team'][1]['color'] = color(@arena['team'][1]['color']);

		if(!array_index_exists(@pvp, 'team')) {
			@pvp['team'] = array(associative_array(), associative_array());
		}
		if(!array_index_exists(@pvp['team'][0], 'players')) {
			@pvp['team'][0]['players'] = array();
			@pvp['team'][1]['players'] = array();
		}

		// Team assignment
		@players = array_keys(@pvp['players']);
		if(array_index_exists(@arena, 'teamratio')) {
			// Uneven team ratios require assigning players randomly

			// First make sure solo player does not end up on the same team as last game
			if(array_index_exists(@pvp, 'lastsolo') && array_contains(@players, @pvp['lastsolo'])) {
				@player = @pvp['lastsolo'];
				@team = abs(array_index(@pvp['arena']['teamratio'], 1) - 1);
				@pvp['players'][@player]['team'] = @team;
				@pvp['team'][@team]['players'][] = @player;
				array_remove_values(@players, @player);
			}

			// Now assign team randomly
			while(@players) {
				@index = rand(0, array_size(@players));
				@player = @players[@index];
				_player_assign_team(@player, @pvp);
				array_remove(@players, @index);
			}
		} else if(array_index_exists(@pvp, 'teamsMode') && @pvp['teamsMode'] === 'random') {
			console('Randomizing teams');
			@team = 1;
			foreach(@player in array_rand(@players, array_size(@players), false)) {
				@team = if(@team, 0, 1);
				@pvp['players'][@player]['team'] = @team;
				@pvp['team'][@team]['players'][] = @player;
			}
		} else {
			// Even team ratios, so sort players based on win/loss or kill/death ratios
			// Use different sorting methods for slight variations in teams
			@balanceType = array_get_rand(array('wins', 'kills'));
			console('Balancing teams by '.@balanceType);
			@arena['teamratio'] = array(1, 1);
			@ratios = associative_array();
			foreach(@player in @players) {
				@pstats = get_value('pvp', puuid(@player, true));
				try {
					if(@balanceType == 'wins') {
						@ratios[@player] = @pstats['wins'] / @pstats['games'];
					} else if(@balanceType == 'kills') {
						@ratios[@player] = @pstats['kills'] / @pstats['deaths'];
					} else {
						@ratios[@player] = rand();
					}
				} catch (Exception @ex) {
					@ratios[@player] = 0.0;
				}
			}
			// Sort highest to lowest win ratios
			array_sort(@players, closure(@left, @right) {
				return(@ratios[@left] < @ratios[@right]);
			});
			// Players will be assigned based on average team win ratio,
			// if there is an even number of players on each team.
			// Should always assign best player first to team 0.
			// The next two players will be on team 1. 4th player on team 0.
			// After that, it might alternate either way, with the higher win ratio players
			// being placed on teams with lower average team win ratios.
			@teamValues = array(0.0, 0.0);
			foreach(@player in @players) {
				@team = 1;
				if(array_size(@pvp['team'][0]['players']) == array_size(@pvp['team'][1]['players'])
				&& @teamValues[0] <= @teamValues[1] 
				|| array_size(@pvp['team'][0]['players']) < array_size(@pvp['team'][1]['players'])) {
					@team = 0;
				}
				@teamValues[@team] += @ratios[@player];
				@pvp['players'][@player]['team'] = @team;
				@pvp['team'][@team]['players'][] = @player;
			}
		}
	}

	if(array_index_exists(@arena, 'captain')) {
		@captainClass1 = @arena['captain'][0];
		@captainClass2 = @arena['captain'][1];
		@pvp['team'][0]['captainhat'] = @arena['classes'][@captainClass1]['kit'][103];
		@pvp['team'][1]['captainhat'] = @arena['classes'][@captainClass2]['kit'][103];
	}

	if(array_index_exists(@arena, 'resourcepack')) {
		set_timeout(50, closure(){
			foreach(@p in array_keys(@pvp['players'])) {
				send_resourcepack(@p, 'http://mc.finalscoremc.com:27836/resourcepacks/'.@arena['resourcepack'].'.zip');
			}
		});
	}

	if(array_size(@pvp['players']) > 2) {
		@pvp['coins'] = 1;
	}
	if(!array_index_exists(@arena, 'stats')) {
		@pvp['stats'] = associative_array();
	}

	@pvp['running'] = 1;

	# CLASSES
	if(array_index_exists(@arena, 'classes')) {
		_classes_select(@id, @pvp);
	}

	# ARENA
	foreach(@arenaId in @pvp['arenascripts']) {
		@arenaScript = "../arenas.library/@arenaId.ms";
		if(file_exists(@arenaScript)){
			include(@arenaScript);
			_arena_prepare(@pvp);
		}
	}

	# ANNOUNCE
	@world = @arena['world'];
	broadcast(_fill_string('*', '-', colorize('&7&m|--&7&l[ &r&l'.@pvp['title'].' &7&l]&7&m*|')), all_players(@world));

	if(array_index_exists(@pvp, 'team')) {
		broadcast(@arena['team'][0]['color'].'['.@arena['team'][0]['name'].'] '.
			array_implode(@pvp['team'][0]['players']).'\n'.color('r').
			@arena['team'][1]['color'].'['.@arena['team'][1]['name'].'] '.
			array_implode(@pvp['team'][1]['players']), all_players(@world)
		);
	} else {
		broadcast(color('gold').' '.array_implode(array_keys(@pvp['players']), colorize('&r vs &6')), all_players(@world));
	}
	if(array_index_exists(@arena, 'lives')) {
		_pvp_msg(@pvp, colorize('* &e&lLIVES: '.@arena['lives']));
	}
	if(array_index_exists(@pvp, 'classPicking')) {
		if(@pvp['classPicking'] === 'random') {
			_pvp_msg(@pvp, colorize('* &e&lRandom Classes'.if(array_index_exists(@pvp, 'classesPickedBy'), ' picked by '.@pvp['classesPickedBy'])));
		} else if(array_index_exists(@pvp, 'classesPickedBy')) {
			_pvp_msg(@pvp, colorize('* &e&lAny Classes picked by '.@pvp['classesPickedBy']));
		}
	}
	if(array_index_exists(@arena, 'class_picks') &&
	(!array_index_exists(@arena, 'lives') || @arena['class_picks'] < @arena['lives'])) {
		_pvp_msg(@pvp, colorize('* &e&lCLASS PICKS: '.@arena['class_picks']));
	}
	if(array_index_exists(@pvp, 'arenaPicked')) {
		@picked = @pvp['arenaPicked'];
		if(@pvp['players'][@picked]['votes']['arena'] === 'random') {
			_pvp_msg(@pvp, colorize('* &e&lArena randomly picked by '.@pvp['arenaPicked']));
		} else {
			_pvp_msg(@pvp, colorize('* &e&lArena picked by '.@pvp['arenaPicked']));
		}
	}
	if(array_index_exists(@pvp, 'teamsMode')) {
		_pvp_msg(@pvp, colorize('* &e&l'.to_upper(@pvp['teamsMode']).' teams picked by '.@pvp['teamsPickedBy']));
	}
	broadcast(colorize('&7&m|----------------------------------------------------|'), all_players(@world));

	@nonplayers = array_filter(all_players(@world), closure(@key, @value) {
		return(!array_index_exists(@pvp['players'], @value));
	});
	_click_tell(@nonplayers, array('&7[PVP] ', array('&b[Click to Spectate '.@pvp['title'].']', '/pvp spectate '.@id)));

	play_sound(@arena['lobby'], array(sound: 'ENTITY_WITHER_SPAWN', pitch: 1.5, volume: 3, category: 'VOICE'));

	if(array_size(@pvp['players']) > 1) {
		_add_activity('pvp'.@id, @pvp['title'], @arena['region'], @world);
	}

	# COUNTDOWN TO START
	@timeleft = array(@pvp['arena']['delay']);
	if(has_bind(@id.'classselector')) {
		create_bar(@id, array(
			title: color('yellow').array_size(@pvp['players']).' players choosing classes...',
			percent: 0.0,
			style: 'SOLID',
			color: 'YELLOW',
		));
	} else {
		create_bar(@id, array(
			title: color('green').'Starting game...',
			percent: 0.0,
			style: 'SEGMENTED_6',
			color: 'GREEN',
		));
	}
	foreach(@p in array_keys(@pvp['players'])) {
		bar_add_player(@id, @p);
	}
	if(array_index_exists(@arena, 'time')) {
		_world_time_travel(@arena['world'], @arena['time'], @pvp['arena']['delay'] * 20);
	}
	set_interval(1000, closure(){
		@timeleft[0] -= 1;
		if(@timeleft[0] > 0) {
			if(@timeleft[0] <= 5) {
				play_sound(@arena['lobby'], array(sound: 'BLOCK_NOTE_BLOCK_PLING', pitch: 1, volume: 3));
				update_bar(@id, array(percent: (6 - @timeleft[0]) / 6));
				foreach(@p: @pd in @pvp['players']) {
					try {
						if(array_index_exists(@pvp, 'team')) {
							@team = @pd['team'];
							title(@p, color('yellow').@timeleft[0], @arena['team'][@team]['color']
									.'Team '.@arena['team'][@team]['name'], 0, @timeleft[0] * 20, 20);
						} else {
							title(@p, color('yellow').@timeleft[0], @pvp['title'], 0, @timeleft[0] * 20, 20);
						}
						if(phealth(@p) == 0) {
							pforce_respawn(@p);
						}
					} catch(PlayerOfflineException @ex) {
						// they quit during the countdown.
						// performance anxiety.
					}
				}
			} else if(@timeleft[0] > 6 && array_index_exists(@arena, 'classes') && array_size(@arena['classes']) > 1) {
				@choosing = if(has_inventory(@id.'0'), array_size(get_inventory_viewers(@id.'0')), 0);
				@choosing += if(has_inventory(@id.'1'), array_size(get_inventory_viewers(@id.'1')), 0);
				if(!@choosing) {
					update_bar(@id, array(title: color('green').'Starting game...', style: 'SEGMENTED_6', percent: 0.0, color: 'GREEN'));
					@timeleft[0] = 6;
				} else {
					update_bar(@id, array(
						percent: (@arena['delay'] - @timeleft[0]) / @arena['delay'],
						title: color('yellow').if(@choosing > 1, @choosing.' players choosing classes...', '1 player choosing a class...'),
					));
				}
			}
		} else {
			remove_bar(@id);
			foreach(@p: @pd in @pvp['players']) {
				try {
					if(array_index_exists(@pvp, 'team')) {
						@team = @pd['team'];
						title(@p, @arena['team'][@team]['color'].'GO!', null, 0, 0, 20);
					} else {
						title(@p, color('green').'GO!', null, 0, 0, 20);
					}
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

proc _pvp_start_match(@id) {
	@pvp = import('pvp'.@id);
	@arena = @pvp['arena'];
	if(array_index_exists(@arena, 'rsoutput')) {
		if(is_associative(@arena['rsoutput']) || !is_array(@arena['rsoutput'][0])) {
			set_block(@arena['rsoutput'], 'REDSTONE_TORCH');
		} else {
			foreach(@torchLoc in @arena['rsoutput']) {
				set_block(@torchLoc, 'REDSTONE_TORCH');
			}
		}
	}

	if(array_index_exists(@arena, 'chestspawn')) {
		@pvp['chestspawn'] = array();
		for(@i = 0, @i < array_size(@arena['chestspawn']), @i++) {
			if(array_index_exists(@arena['chestspawn'][@i], 'cooldown')) {
				if(@arena['chestspawn'][@i]['start'] === 'true') {
					@pvp['chestspawn'][@i] = 0;
				} else {
					@pvp['chestspawn'][@i] = time();
					set_block(@arena['chestspawn'][@i]['loc'], 'AIR');
				}
			} else if(array_index_exists(@arena, 'chestgroup')) {
				if(get_block(@arena['chestspawn'][@i]['loc']) != 'CHEST') {
					set_block(@arena['chestspawn'][@i]['loc'], 'CHEST');
				}
				@group = @arena['chestspawn'][@i]['group'];
				@r = rand(array_size(@arena['chestgroup'][@group]));
				for(@y = 0, @y < 27, @y++) {
					@item = get_inventory_item(@arena['chestgroup'][@group][@r], @y);
					set_inventory_item(@arena['chestspawn'][@i]['loc'], @y, @item);
				}
			}
		}
	}

	if(array_index_exists(@arena, 'itemspawn')) {
		@pvp['itemspawn'] = array();
		for(@i = 0, @i < array_size(@arena['itemspawn']), @i++) {
			@time = time();
			if(@arena['itemspawn'][@i]['start']) {
				@time = 0;
			}
			@pvp['itemspawn'][@i] = array('', @time);
		}
	}

	if(array_index_exists(@arena, 'powerup')) {
		@pvp['powerups'] = array();
	}

	if(array_index_exists(@arena, 'mobspawn')) {
		@pvp['mobspawn'] = array();
		for(@i = 0, @i < array_size(@arena['mobspawn']), @i++) {
			@time = time();
			if(@arena['mobspawn'][@i]['start']) {
				@time = 0;
			}
			@pvp['mobspawn'][@i] = @time;
		}
	}

	if(@arena['respawnmode'] == 'mob') {
		foreach(@team: @locations in @arena['respawn']) {
			@pvp['team'][@team]['respawns'] = array();
			@type = null;
			if(@team == 0) {
				@type = array(type: 'VILLAGER', tags: array(profession: 'FARMER'));
			} else {
				@type = array(type: 'VILLAGER', tags: array(profession: 'BUTCHER'));
			 }
			foreach(@loc in @locations) {
				@loc[1] += 1;
				if(!get_block_info(@loc, 'solid')) {
					@uuid = _spawn_entity(@type, @loc);
					@pvp['team'][@team]['respawns'][] = @uuid;
				}
			}
		}
	}

	if(array_index_exists(@arena, 'timer')) {
		@pvp['starttime'] = time() / 1000;
	}

	_remove_region_entities(@arena['region'], @arena['world'], array('DROPPED_ITEM', 'EXPERIENCE_ORB'));
	_pvp_initialize_players(@id, array_keys(@pvp['players']));

	if(array_index_exists(@arena, 'captain')) {
		_pvp_msg(@pvp, color('gray').'[PVP] '.@arena['team'][0]['color']
			.@pvp['team'][0]['captain']. ' is the captain of '.@arena['team'][0]['name'].'.');
		_pvp_msg(@pvp, color('gray').'[PVP] '.@arena['team'][1]['color']
			.@pvp['team'][1]['captain']. ' is the captain of '.@arena['team'][1]['name'].'.');
	}

	if(array_index_exists(@arena, 'mobprotect')) {
		queue_push(closure(){
			foreach(@team: @mob in @arena['mobprotect']) {
				get_block(@mob['loc']); // loads chunk
				@entityid = _spawn_entity(@mob['type'], @mob['loc']);
				set_mob_name(@entityid, @arena['team'][@team]['color'].@arena['team'][@team]['name']);
				@pvp['team'][@team]['mobprotect'] = @entityid;
			}
		}, @id);
	}

	# MODES
	@modeScript = '../modes.library/'.@arena['mode'].'.ms';
	if(file_exists(@modeScript)) {
		// Since this is after some default procs are loaded, do not use include_dir
		// This proc stub is the only one modes must override.
		proc _load_mode(@pvp) {}
		include(@modeScript);
		_load_mode(@pvp);
	}

	# WEAPONS
	if(array_index_exists(@arena, 'weapons')) {
		foreach(@weapon in @arena['weapons']) {
			include('../weapons.library/'.@weapon.'.ms');
			_weapon_bind_events(@pvp);
		}
	}

	_bind_events(@pvp);

	@pvp['interval'] = set_interval(1000, closure(){
		@check = false;

		if(array_index_exists(@arena, 'timer')) {
			@totalsecsleft = ceil((@arena['timer'][1] * 60) - ((time() / 1000) - @pvp['starttime']));
			if(@totalsecsleft < 0) {
				@team = @arena['timer'][0];
				_pvp_end_match(@id, @pvp['team'][@team]['players']);
				die();
			}
			@minleft = floor(@totalsecsleft / 60);
			@secsleft = @totalsecsleft % 60;
			@timeleft = @minleft.':'.if(@secsleft < 10, '0').@secsleft;
			// @percentage = round((@totalsecsleft / (@arena['timer'][1] * 60)) * 100);
			if(extension_exists('CHNaughty')) {
				foreach(@p in array_merge(array_keys(@pvp['players']), @pvp['spectators'])) {
					action_msg(@p, @timeleft);
				}
			}
		}

		foreach(@player: @p in @pvp['players']) {
			if(array_index_exists(@arena, 'respawntime') && @p['respawn'] != 0) {
				@time = time();
				if(@p['respawn'] < @time + 100) { // couple ticks of leeway
					@loc = array();
					if(array_index_exists(@arena, 'captain')) {
						@team = @p['team'];
						if(@pvp['team'][@team]['captain'] === '') {
							continue();
						}
						@loc = ploc(@pvp['team'][@team]['captain']);
						play_sound(ploc(@player), array(sound: 'ENTITY_GHAST_SHOOT'));
						make_effect(location_shift(ploc(@player), 'up'), 'MOBSPAWNER_FLAMES');
					} else {
						if(array_index_exists(@pvp, 'team')) {
							@team = @p['team'];
							@r = rand(0, array_size(@arena['spawn'][@team]));
							@loc = @arena['spawn'][@team][@r];
						} else {
							@r = rand(0, array_size(@arena['spawn'][0]));
							@loc = @arena['spawn'][0][@r];
						}
					}
					try {
						set_entity_fall_distance(puuid(@player), 0);
					} catch(BadEntityException @ex) {
						// this happened once... wat
					}
					set_ploc(@player, @loc);

					if(array_contains(@arena['flags'], 'build')) {
						set_pmode(@player, 'SURVIVAL');
					} else {
						set_pmode(@player, 'ADVENTURE');
					}
					if(array_index_exists(@pvp['players'][@player], 'class')) {
						_classes_load(@player, @pvp['players'][@player]['class'], @pvp);
					}
					preset_time(@player);
					_player_equip(@id, @player);
					@p['respawn'] = 0;
					close_pinv(@player);
				} else if(!array_contains(sk_current_regions(@player), @arena['region'])) {
					if(pmode(@player) != 'SPECTATOR') {
						_pvp_msg(@pvp, colorize('&7[PVP] '.@p['color'].@player.'&r left the arena.'));
						_player_remove(@player, @id);
					} else {
						set_ploc(@player, @arena['spawn'][0][0]);
					}
				} else {
					@timeleft = integer(round((@p['respawn'] - @time) / 1000));
					title(@player, @timeleft, null, 0, 20, 0);
					if(@timeleft == 3) {
						set_pstorm(@player, false);
					}
				}
			} else if(!array_contains(sk_current_regions(@player), @arena['region'])) {
				if(array_contains(@arena['flags'], 'exitrespawn')) {
					set_entity_fall_distance(puuid(@player), 0);
					if(array_index_exists(@pvp, 'team')) {
						@team = @pvp['players'][@player]['team'];
						set_ploc(@player, @arena['spawn'][@team][0]);
					} else {
						set_ploc(@player, @arena['spawn'][0][0]);
					}
				} else {
					tmsg(@player, color('gray').'[PVP] '.color('r').'You exited the combat region.');
					if(!_is_survival_world(pworld(@player))) {
						pkill(@player);
					}
				}
			}

		} else {
			@check = true;
		}

		foreach(@i: @p in @pvp['spectators']) {
			try {
				if(!array_contains(sk_current_regions(@p), @arena['region'])) {
					_spectator_remove(@p, @pvp);
				}
			} catch(PlayerOfflineException @ex) {
				array_remove(@pvp['spectators'], @i);
			}
		}

		if(array_index_exists(@arena, 'itemspawn')) {
			@viewers = array_merge(@pvp['spectators'], array_keys(@pvp['players']));
			foreach(@i: @item in @arena['itemspawn']) {
				@itemspawn = @pvp['itemspawn'][@i];
				if(@itemspawn[0]) {
					try {
						@loc = location_shift(entity_loc(@itemspawn[0]), 'up', 0.4);
						@itemspawn[1] = time();
						spawn_particle(@loc, array(
							particle: 'FIREWORKS_SPARK',
							count: 1,
							xoffset: 0.3, 
							yoffset: 0.3,
							zoffset: 0.3,
							force: true
						), @viewers);
						set_entity_glowing(@itemspawn[0], false);
						continue();
					} catch(BadEntityException @ex) {
						// item drop was picked up or is unloaded
					}
				}
				if(@itemspawn[1] + (@item['cooldown'] * 1000) < time()) {
					@itemId = drop_item(@item['loc'], @item['item'], false);
					try {
						set_entity_velocity(@itemId, array(0, 0, 0));
						set_entity_glowing(@itemId, true);
						play_sound(@item['loc'], array(sound: 'ENTITY_ENDERMAN_TELEPORT', pitch: 1.5));
						make_effect(@item['loc'], 'ENDER_SIGNAL');
						@itemspawn[0] = @itemId;
						@itemspawn[1] = time();
					} catch(BadEntityException @ex) {
						// chunk might not be loaded, so try again next tick
						@itemspawn[0] = '';
					}
				}
			}
		}

		if(array_index_exists(@pvp, 'powerups')) {
			foreach(@index: @entity in @pvp['powerups']) {
				if(entity_exists(@entity)) {
					spawn_particle(location_shift(entity_loc(@entity), 'up', 0.4), array(
						particle: 'FIREWORKS_SPARK',
						count: 1,
						xoffset: 0.3, 
						yoffset: 0.3,
						zoffset: 0.3,
						force: true
					));
				} else {
					array_remove(@pvp['powerups'], @index);
				}
			}
		}

		if(array_index_exists(@arena, 'mobspawn')) {
			foreach(@i: @mob in @arena['mobspawn']) {
				if((@pvp['mobspawn'][@i] + (@mob['respawn'] * 1000)) < time()) {
					_spawn_entity(@mob['type'], @mob['loc']);
					@pvp['mobspawn'][@i] = time();
				}
			}
		}

		if(array_index_exists(@arena, 'chestspawn')) {
			foreach(@i: @chest in @arena['chestspawn']) {
				if(array_index_exists(@pvp['chestspawn'], @i)
				&& (@pvp['chestspawn'][@i] + (@chest['cooldown'] * 1000)) < time()) {
					@block = get_block(@chest['loc']);
					if(@block === 'AIR' || @block == 'WATER') {
						set_block(@chest['loc'], 'CHEST');
						for(@y = 0, @y < array_size(@chest['items']), @y++) {
							set_inventory_item(@chest['loc'], @y, @chest['items'][@y]);
						}
						@pvp['chestspawn'][@i] = time();
					}
				}
			}
		}

		if(array_index_exists(@arena, 'blockbreak') && @pvp['blockcheck']) {
			foreach(@team in array(0, 1)) {
				foreach(@index: @loc in @arena['blockbreak'][@team]) {
					if(get_block(@loc) == 'AIR') {
						array_remove(@arena['blockbreak'][@team], @index);
						@count = array_size(@arena['blockbreak'][@team]);
						set_pscore('blocks', @arena['team'][@team]['name'], @count, @id);
						if(@count < 1) {
							_pvp_end_match(@id, @pvp['team'][if(@team, 0, 1)]['players']);
							die();
						}
						play_sound(@loc, array(sound: 'ENTITY_ZOMBIE_VILLAGER_CONVERTED', volume: 5), @pvp['team'][@team]['players']);
						play_sound(@loc, array(sound: 'ENTITY_ARROW_HIT_PLAYER', pitch: 1.5));
					}
				}
			}
			@pvp['blockcheck'] = false;
		}

		// Mode specific code
		_interval(@pvp, @id);

		if(@check) {
			_pvp_check_objectives(@id);
		}
	});

}

proc _pvp_check_objectives(@id) {
	@pvp = import('pvp'.@id);

	if(!@pvp || @pvp['running'] != 2) {
		return();
	}

	@arena = @pvp['arena'];

	#check player counts
	if(array_index_exists(@pvp, 'team')) {
		@teamcount = array(0, 0);
		@winner = -1;
		foreach(@player in @pvp['players']) {
			if(!array_index_exists(@arena, 'captain')
			|| !array_index_exists(@arena, 'respawntime')
			|| @player['respawn'] == 0) {
				@team = @player['team'];
				@teamcount[@team]++;
				@winner = @team;
			}
		}
		if(@teamcount[0] == 0 || @teamcount[1] == 0) {
			if(@winner > -1) {
				_pvp_end_match(@id, @pvp['team'][@winner]['players']);
			} else {
				_pvp_end_match(@id, array());
			}
			die();
		}
	} else if(array_size(@pvp['players']) <= 1) {
		_pvp_end_match(@id, array_keys(@pvp['players']));
		die();
	}

	#check scores
	if(@arena['mode'] == 'dm' && array_index_exists(@arena, 'score')) {
		@scoreTarget = @arena['score'];
		if(!array_index_exists(@pvp, 'team')) {
			foreach(@player: @data in @pvp['players']) {
				if(get_pscore('score', @player, @id) >= @scoreTarget) {
					_pvp_end_match(@id, array(@player));
					die();
				}
			}
		} else {
			if(get_pscore('score', @arena['team'][0]['name'], @id) >= @scoreTarget) {
				_pvp_end_match(@id, @pvp['team'][0]['players']);
			} else if(get_pscore('score', @arena['team'][1]['name'], @id) >= @scoreTarget) {
				_pvp_end_match(@id, @pvp['team'][1]['players']);
			}
		}
	}

	#check team scores
	if(@arena['mode'] === 'ctf' || @arena['mode'] === 'bombingrun'
	&& (@pvp['team'][0]['score'] >= @arena['score'] || @pvp['team'][1]['score'] >= @arena['score'])) {
		@topteam = 1;
		if(@pvp['team'][0]['score'] >= @arena['score']) {
			@topteam = 0;
		}
		_pvp_end_match(@id, @pvp['team'][@topteam]['players']);
		die();
	}

}

proc _pvp_end_round(@id, @winners) {
	@pvp = import('pvp'.@id);
	if(array_index_exists(@pvp, 'round') && @pvp['arena']['rounds'] < @pvp['round']) {
		@pvp['round']++;
	} else {
		_pvp_end_match(@id, @winners);
	}
}

proc _pvp_end_match(@id, @winners) {
	@pvp = import('pvp'.@id);
	@arena = @pvp['arena'];
	@world = @arena['world'];

	if(@pvp['running'] != 2) {
		return();
	}

	foreach(array_keys(@pvp['players']), @player) {
		if(array_contains(@winners, @player)) {
			if(ponline(@player) && @pvp['coins'] >= 1) {
				_acc_add(@player, @pvp['coins']);
			}
		}
	}

	// Make sure we do not assign them to the same solo team twice in a row
	@lastSolo = '';
	if(array_index_exists(@arena, 'teamratio')) {
		@teams = array_indexes(@arena['teamratio'], 1);
		if(array_size(@teams) == 1) {
			@team = @teams[0];
			@lastSolo = array_implode(@pvp['team'][@team]['players']);
		}
	}

	queue_delay(100, @id); // timing ensures players are alive or in spec
	queue_push(closure(){
		if(array_index_exists(@pvp, 'stats')) {
			_stats_print(@winners, @pvp);
		} else if(array_index_exists(@pvp, 'team') && array_size(@winners) > 0) {
			@leader = '';
			foreach(@leader in @winners) {
				if(array_index_exists(@pvp['players'], @leader)) {
					break();
				}
			}
			@title = '';
			@subtitle = '';
			if(@leader) {
				@team = @pvp['players'][@leader]['team'];
				@title = @pvp['players'][@leader]['color'].color('bold')
					.@arena['team'][@team]['name'].' win '.@pvp['title'].'!';
				@subtitle = @pvp['players'][@leader]['color'].array_implode(@winners);
			} else {
				console('Winners left the game as it ended? '.@winners.' not in '.array_keys(@pvp['players']));
				@title = array_implode(@winners).' won '.@pvp['title'].'!';
			}
			broadcast(color('gray').'[PVP] '.@title.'\n'.@subtitle, all_players(@world));
			foreach(@p in array_keys(@pvp['players'])) {
				title(@p, @title, @subtitle, 20, 60, 20);
			}
			discord_broadcast('minecraft_chat', array(embed: array(title: strip_colors(@title).' ('.strip_colors(@subtitle).')')));
		} else if(array_size(@winners) > 0) {
			@winnersString = array_implode(@winners, ' and ').' win'.if(array_size(@winners) == 1, 's ', ' ').@pvp['title'].'!';
			broadcast(color('gray').'[PVP] '.color('r').@winnersString, all_players(@world));
			foreach(@p in array_keys(@pvp['players'])) {
				title(@p, '', @winnersString, 20, 60, 20);
			}
			discord_broadcast('minecraft_chat', array(embed: array(title: @winnersString)));
		} else {
			broadcast(color('gray').'[PVP] '.color('r').'Nobody wins! Wait.. what?!', all_players(@world));
			discord_broadcast('minecraft_chat', array(embed: array(title: @pvp['title'].' is a draw')));
		}
	}, @id);

	queue_push(closure(){
		if(array_index_exists(@pvp, 'stats')) {
			_stats_store(@winners, @pvp);
		}
	}, @id);

	if(array_index_exists(@arena, 'chestspawn')) {
		for(@i = 0, @i < array_size(@arena['chestspawn']), @i++) {
			if(get_block(@arena['chestspawn'][@i]['loc']) === 'CHEST') {
				set_block(@arena['chestspawn'][@i]['loc'], 'AIR');
			}
		}
	}

	try {

		if(array_index_exists(@arena, 'rsoutput')) {
			if(is_associative(@arena['rsoutput']) || !is_array(@arena['rsoutput'][0])) {
				set_block(@arena['rsoutput'], 'TORCH');
			} else {
				foreach(@torchLoc in @arena['rsoutput']) {
					set_block(@torchLoc, 'TORCH');
				}
			}
		}

		if(@arena['mode'] === 'ctf') {
			queue_clear(@id.'0flag');
			queue_clear(@id.'1flag');
		} else if(@arena['mode'] === 'bombingrun') {
			queue_clear(@id.'bomb');
		}

		if(array_index_exists(@arena, 'captain')) {
			queue_clear(@id.'0hat');
			queue_clear(@id.'1hat');
		}

		@chests = get_virtual_inventories();
		foreach(@chest in @chests) {
			if(@chest === @id.'0'
			|| @chest === @id.'1') {
				delete_virtual_inventory(@chest);
			} else if(@chest === @id.'options') {
				delete_virtual_inventory(@chest);
				unbind(@chest);
			}
		}

		if(array_index_exists(@pvp, 'interval')) {
			clear_task(@pvp['interval']);
		}

	} catch(Exception @ex) {
		console(@ex, false);
		return();
	}

	@pvp['running'] = 3

	queue_delay(4000, @id);
	queue_push(closure(){
		@pvp['running'] = 0;
		foreach(@player in array_keys(@pvp['players'])) {
			try {
				if(array_index_exists(@pvp['players'][@player], 'class')) {
					_classes_unload(@player, @pvp['players'][@player]['class'], @pvp);
					array_remove(@pvp['players'][@player], 'class');
				}
				if(ponline(@player)) {
					close_pinv(@player);
					_player_remove(@player, @id);
					if(array_index_exists(@arena, 'podium') && array_contains(@winners, @player)) {
						set_ploc(@player, @arena['podium']);
					}
				}
			} catch(Exception @ex) {
				console(@ex, false);
			}
		}
		foreach(@bind in @pvp['binds']) {
			unbind(@bind);
		}
		foreach(@p in @pvp['spectators']) {
			_spectator_remove(@p, @pvp);
		}
		_remove_region_entities(@arena['region'], @world, array());

		if(array_index_exists(@arena, 'restore')) {
			broadcast(color('YELLOW').'Restoring arena for '.@pvp['title'].' ...');
			foreach(@region in @arena['restore']) {
				queue_push(closure(){
					skcb_load(@region);
					skcb_paste(array(0, 0, 0, @world), array(origin: true));
				});
			}
		}
		queue_push(closure(){
			remove_scoreboard(@id);
			try(remove_bar(@id))

			# Reset
			@pvp = _pvp_create(@id);
			if(@lastSolo) {
				@pvp['lastsolo'] = @lastSolo;
			}
			_remove_activity('pvp'.@id);
			array_remove_values(import('pvp.joined'), @id);
			_menu_refresh('pvp');
		}, @id);

	}, @id);
}
