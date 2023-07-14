proc _player_join(@id) {
	@arena = get_value('arena.'.@id);
	if(!@arena) {
		die('Can\'t find that arena.');
	}
	if(_is_survival_world(pworld()) && array_index_exists(@arena, 'lobby')) {
		set_ploc(@arena['lobby']);
	}
	if(_pbusy()) {
		die('You are already playing "'._psession()['activity'].'".');
	}

	@pvp = import('pvp'.@id);
	if(!@pvp) {
		@pvp = _pvp_create(@id);
	} else {
		if(array_index_exists(@pvp['players'], player())) {
			die('You already joined.');
		}
		// check if you can join this game in progress
		if(@pvp['running'] > 1 && (array_index_exists(@pvp['arena'], 'lives')
		|| (array_index_exists(@pvp['arena'], 'max') && array_size(@pvp['players']) >= @pvp['arena']['max']))) {
			msg('Match already in progress.');
			_click_tell(array(player()), array('&7[PVP] ', array('&b[Click to Spectate '.@pvp['title'].']', '/pvp spectate '.@id)));
			die();
		}
	}
	@pvp['players'][player()] = associative_array();

	import('pvp.joined')[] = @id;

	// ensure staff does not have flight
	if(phas_flight()) {
		set_pflight(false);
	}

	// remove offline players so we can update player count
	foreach(@player in array_keys(@pvp['players'])) {
		if(!ponline(@player)) {
			array_remove(@pvp['players'], @player);
		}
	}

	@title = _to_upper_camel_case(if(array_index_exists(@arena, 'parent'), @arena['parent'].': ').@id);
	@playerCount = array_size(@pvp['players']);
	@msg = array('&7[PVP] ', array('&b[JOIN] ', '/pvp join '.@id));
	if(@playerCount >= array_get(@arena, 'min', 2)) {
		@msg[] = array('&a[START] ', '/pvp start '.@id);
	}
	@msg[] = '&r'.player().' joined '. @title . ' ('.@playerCount.') ';
	_click_tell(all_players(pworld()), @msg);
	console(player().' joined '.@id, false);

	_menu_refresh('pvp');

	if(@pvp['running'] == 1 || @pvp['running'] == 2) {
		if(array_index_exists(@pvp['arena'], 'resourcepack')) {
			send_resourcepack(player(), 'http://mc.finalscoremc.com:27836/resourcepacks/'.@pvp['arena']['resourcepack'].'.zip');
		}
		if(array_contains(@pvp['spectators'], player())) {
			_spectator_remove(player(), @pvp);
		}
		if(array_index_exists(@pvp['arena'], 'team')) {
			_player_assign_team(player(), @pvp);
		}
	}

	if(@pvp['running'] == 0 && @playerCount == 1 && array_index_exists(@arena, 'options')) {
		if(!has_inventory(@id.'options')) {
			_create_options_menu(@id, @arena);
		}
		popen_inventory(@id.'options');

	} else if(@pvp['running'] == 0 && array_index_exists(@arena, 'arenaselect') && @arena['arenaselect']['type'] == 'vote') {
		// Display book with vote links
		@votes = array();
		foreach(@p in @pvp['players']) {
			if(array_index_exists(@p, 'arena')) {
				@votes[] = @p['arena'];
			}
		}
		@pages = array();
		@line = 1;
		@page = 0;
		foreach(@index: @arena in @arena['arenaselect']['arenas']) {
			if(@line == 1) {
				@pages[@page] = '["",{"color":"red","bold":true,"text":"Vote for an Arena:"}';
				@line++;
			}
			@color = 'reset';
			if(array_contains(@votes, @arena)) {
				@color = 'dark_green';
			}
			@pages[@page] .= ',{"color":"'.@color.'","text":"'.'\\n \u27a2 '.to_upper(@arena[0]).substr(@arena, 1)
					.'","clickEvent":{"action":"run_command","value":"/pvp vote '.@id.' arena '.@arena.'"}}';
			@line++;
			if(@line == 15) {
				@line = 1;
				@pages[@page] .= ']';
				@page++;
			}
		}
		if(array_index_exists(@pages, @page) && !string_ends_with(@pages[@page], ']')) {
			@pages[@page] .= ']';
			@page++;
		}
		@pages[@page] = '["",{"color":"red","bold":true,"text":"Vote for Teams:"}'
				.',{"text":"'.'\\n \u27a2 Solo","clickEvent":{"action":"run_command","value":"/pvp vote '.@id.' mode solo"}}'
				.',{"text":"'.'\\n \u27a2 Teams","clickEvent":{"action":"run_command","value":"/pvp vote '.@id.' mode teams"}}'
				.']';
		open_book(@pages);

	} else if(@pvp['running'] == 1) {
		if(array_index_exists(@pvp['arena'], 'classes')) {
			if(!array_index_exists(@pvp['players'][player()], 'team') || @pvp['players'][player()]['team'] == 0) {
				if(has_inventory(@id.'0')) {
					popen_inventory(player(), @id.'0');
				}
			} else {
				if(has_inventory(@id.'1')) {
					popen_inventory(player(), @id.'1');
				}
			}
		}

	} else if(@pvp['running'] == 2) {
		_pvp_initialize_players(@id, array(player()));

	} else if(array_index_exists(@arena, 'max') && @playerCount >= @arena['max']) {
		call_alias('/pvp start '.@id);
	} else if(array_get(@arena, 'min', 2) > array_size(all_players())) {
		msg('There are not enough players to play this game.\nTry another game.');
	}
}

proc _player_remove(@player, @id) {
	@pvp = import('pvp'.@id);
	if(@pvp['arena']['mode'] === 'ctf' && !is_null(@flag = _flag(pinv(@player, 103)))) {
		_pvp_flag_spawn(@id, @flag);
	} else if(@pvp['arena']['mode'] == 'bombingrun' && phas_item(@player, array(name: @pvp['arena']['bomb']))) {
		_pvp_bomb_spawn(@id);
	}
	if(array_index_exists(@pvp['players'][@player], 'class')) {
		_classes_unload(@player, @pvp['players'][@player]['class'], @pvp);
	}
	foreach(@entity in @pvp['players'][@player]['entities']) {
		try(entity_remove(@entity))
	}
	array_remove(@pvp['players'], @player);
	if(array_index_exists(@pvp['arena'], 'lives') && @pvp['arena']['lives'] > 1) {
		set_pscore('lives', @player, 0, @id);
	}
	if(ponline(@player)) {
		if(array_index_exists(@pvp['arena'], 'resourcepack')) {
			send_resourcepack(@player, 'http://mc.finalscoremc.com:27836/resourcepacks/default.zip');
		}
		preset_time(@player);
		set_pstorm(@player, null);
		if(function_exists('dm_set_pvisible')) {
			dm_set_pvisible(@player, true);
		}
		try {
			set_entity_fall_distance(puuid(@player), 0);
			set_entity_onfire(puuid(@player), 0);
		} catch(BadEntityException @ex) {
			// player quitting, so no entity
		}
		set_ploc(@player, @pvp['arena']['lobby']);
		clear_peffects(@player);
		_set_pactivity(@player, null);
		set_timeout(1, closure(){
			_equip_kit(@player); // helps clear maps after teleporting
		});
	}
	_pvp_check_objectives(@id);
}

proc _player_to_spectator(@player, @pvp) {
	if(array_index_exists(@pvp['players'][player()], 'class')) {
		_classes_unload(player(), @pvp['players'][player()]['class'], @pvp);
	}
	foreach(@entity in @pvp['players'][@player]['entities']) {
		try(entity_remove(@entity))
	}
	array_remove(@pvp['players'], player());
	if(function_exists('dm_set_pvisible')) {
		dm_set_pvisible(@player, true);
	}

	# Delay spectator mode so that health amount is updated.
	# Health can be above zero when pkill() or set_phealth() are used.
	set_timeout(1, closure(){
		_spectator_add(player(), @pvp);
	});
}

proc _pvp_initialize_players(@id, @players) {
	@pvp = import('pvp'.@id);
	@c = array(0, 0); # for selecting initial spawn locations
	@loc = array();
	foreach(@player in @players) {
		if(!ponline(@player) || _is_survival_world(pworld(@player)) ||
		!_set_pactivity(@player, _to_upper_camel_case(@id))) {
			array_remove(@pvp['players'], @player);
			continue();
		}

		if(phealth(@player) == 0) {
			respawn(@player);
		}

		@pArray = @pvp['players'][@player];

		@pArray['blocks'] = array(); // used for cleaning up placed blocks
		@pArray['entities'] = associative_array(); // used for cleaning up player-specific entities

		if(array_contains(@pvp['arena']['flags'], 'build')) {
			set_pmode(@player, 'SURVIVAL');
		} else {
			set_pmode(@player, 'ADVENTURE');
		}
		set_pscoreboard(@player, @id);
		if(array_index_exists(@pArray, 'team')) {
			@team = @pArray['team'];
			team_add_player(@pvp['arena']['team'][@team]['name'], @player, @id);
			@pArray['color'] = @pvp['arena']['team'][@team]['color'];
		} else {
			@pArray['color'] = color('f');
		}
		switch(@pvp['arena']['mode']) {
			case 'koth':
				if(!array_index_exists(@pvp, 'team')) {
					@score = get_pscore('seconds', @player, @id);
					if(@score == 0) {
						set_pscore('seconds', @player, neg(@pvp['arena']['score']), @id);
					}
				}
			case 'dm':
				if(array_index_exists(@pvp['arena'], 'lives') && @pvp['arena']['lives'] > 1) {
					set_pscore('lives', @player, @pvp['arena']['lives'], @id);
				}
				if(array_index_exists(@pvp['arena'], 'score') && @pvp['arena']['mode'] == 'dm') {
					set_pscore('score', @player, 0, @id);
				}
		}

		if(array_contains(@pvp['arena']['flags'], 'hideplayers')) {
			if(function_exists('dm_set_pvisible')) {
				dm_set_pvisible(@player, false);
			}
		}

		if(array_index_exists(@pvp['arena'], 'lives')) {
			@pArray['lives'] = integer(@pvp['arena']['lives']);
		}

		if(array_index_exists(@pvp['arena'], 'respawntime')) {
			@pArray['respawn'] = 0;
		}

		if(array_index_exists(@pvp, 'stats')) {
			_stats_add_player(@player, @pvp);
		}

		set_pbed_location(@player, @pvp['arena']['lobby']);

		_player_reset(@player, @pvp);
		if(array_index_exists(@pvp['arena'], 'classes')) {
		 	if(!array_index_exists(@pArray, 'class')) {
				_classes_select_random(@player, @pvp);
			}
			if(array_index_exists(@pArray, 'class')) {
				_classes_load(@player, @pArray['class'], @pvp);
			}
			if(array_index_exists(@pvp['arena'], 'class_picks') && !array_index_exists(@pArray, 'picks')) {
				@pArray['picks'] = @pvp['arena']['class_picks'];
			}
		}

		_player_equip(@id, @player);

		# Select spawn location
		if(array_index_exists(@pvp, 'team')) {
			@team = @pArray['team'];
			@teamCount = @c[@team];
			@loc = @pvp['arena']['spawn'][@team][@teamCount];
			if(@teamCount == array_size(@pvp['arena']['spawn'][@team]) - 1) {
				@c[@team] = 0;
			} else {
				@c[@team]++;
			}
		} else {
			@count = @c[0];
			@loc = @pvp['arena']['spawn'][0][@count];
			if(@count == array_size(@pvp['arena']['spawn'][0]) - 1) {
				@c[0] = 0;
			} else {
				@c[0]++;
			}
		}

		# Teleport to spawn location
		# Teleporting players one at a time helps prevent client-side invisible players
		queue_push(closure(){
			try {
				set_entity_fall_distance(puuid(@player), 0);
				set_ploc(@player, @loc);
				play_sound(@loc, array(sound: 'ENTITY_FIREWORK_ROCKET_BLAST'), @player);
			} catch(Exception @ex) {
				// Something went wrong.
				// They should die next pvp interval for being outside of the arena and then get respawned.
			}
		}, @id);
	}
}

/*
	Resets player as if they had died and respawned.
	Does not teleport player.
	Unlike vanilla, does not give any saturation.
*/
proc _player_reset(@player, @pvp) {
	_clear_pinv(@player);
	set_phunger(@player, 20);
	set_psaturation(@player, 0);
	set_pexp(@player, 0);
	clear_peffects(@player);
	try {
		set_entity_onfire(puuid(@player), 0);
		set_entity_rider(puuid(@player), null);
		set_entity_rider(null, puuid(@player));
		set_entity_fall_distance(puuid(@player), 0);
	} catch(BadEntityException @ex) {
		// ignore
	}
	try {
		set_phealth(@player, 20);
	} catch(RangeException @ex) {
		console(@player.'\'s max health is lower than 20!', false);
		set_max_health(puuid(@player), 20.0);
		set_phealth(@player, 20);
	}
}

proc _player_equip(@id, @player) {
	if(_is_survival_world(pworld(@player))) {
		return();
	}
	@pvp = import('pvp'.@id);
	if(!array_index_exists(@pvp['players'], @player)) {
		return();
	}
	if(array_index_exists(@pvp['arena'], 'hunger')) {
		set_phunger(@player, @pvp['arena']['hunger']);
	}
	if(array_index_exists(@pvp['arena'], 'saturation')) {
		set_psaturation(@player, @pvp['arena']['saturation']);
	}
	if(array_index_exists(@pvp['players'][@player], 'inv')) {
		set_pinv(@player, @pvp['players'][@player]['inv']);
	} else {
		if(array_index_exists(@pvp['arena'], 'kit')) {
			if(array_index_exists(@pvp, 'team')) {
				@team = @pvp['players'][@player]['team'];
				set_pinv(@player, @pvp['arena']['kit'][@team]);
			} else {
				set_pinv(@player, @pvp['arena']['kit'][0]);
			}
		}
		if(array_index_exists(@pvp['players'][@player], 'class')) {
			_classes_equip(@player, @pvp['players'][@player]['class'], @pvp);
		}
	}
	if(array_index_exists(@pvp['arena'], 'effect')) {
		foreach(@effect: @data in @pvp['arena']['effect'][0]) {
			set_peffect(@player, @effect, @data['strength'], @data['length'], true);
		}
		if(array_index_exists(@pvp, 'team')) {
			foreach(@effect: @data in @pvp['arena']['effect'][@pvp['players'][@player]['team'] + 1]) {
				set_peffect(@player, @effect, @data['strength'], @data['length'], true);
			}
		}
	}
	if(array_contains(@pvp['arena']['flags'], 'heartdisplay')) {
		set_pscore('health', @player, integer(phealth()), @id);
	}
}

proc _player_assign_team(@player, @pvp) {
	@ratio = @pvp['arena']['teamratio'];
	if(array_size(@pvp['team'][0]['players']) * @ratio[1] <= array_size(@pvp['team'][1]['players']) * @ratio[0]) {
		@pvp['players'][@player]['team'] = 0;
		if(!array_contains(@pvp['team'][0]['players'], @player)) {
			@pvp['team'][0]['players'][] = @player;
		}
		array_remove_values(@pvp['team'][1]['players'], @player);
	} else {
		@pvp['players'][@player]['team'] = 1;
		if(!array_contains(@pvp['team'][1]['players'], @player)) {
			@pvp['team'][1]['players'][] = @player;
		}
		array_remove_values(@pvp['team'][0]['players'], @player);
	}
}
