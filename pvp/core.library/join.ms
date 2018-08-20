proc _pvp_join(@id){
	@pvp = import('pvp'.@id);
	@arena = get_value('arena.'.@id);
	if(!@arena) {
		die('Can\'t find that arena.');
	}
	if(_is_survival_world(pworld()) && array_index_exists(@arena, 'lobby')) {
		set_ploc(@arena['lobby']);
	}
	if(_psession(player())['activity']) {
		die('You are already playing "'._psession(player())['activity'].'".');
	}
	if(!@pvp) {
		@pvp = array('players': associative_array(), 'running': 0, 'id': @id);
		@pvp['players'][player()] = associative_array();
		export('pvp'.@id, @pvp);
	} else {
		if(array_index_exists(@pvp['players'], player())) {
			die('You already joined.');
		}
		if(@pvp['running'] > 1 && (array_index_exists(@pvp['arena'], 'lives')
		|| (array_index_exists(@pvp['arena'], 'max') && array_size(@pvp['players']) >= @pvp['arena']['max']))) {
			die('Match already in progress.');
		}
		@pvp['players'][player()] = associative_array();
	}
	if(phas_flight()) {
		set_pflight(false);
	}
	foreach(@player in array_keys(@pvp['players'])) {
		if(!ponline(@player)) {
			array_remove(@pvp['players'], @player);
		}
	}
	@msg = array('&7[PVP] ', array('&b[JOIN] ', '/pvp join '.@id));
	if(array_size(@pvp['players']) >= array_get(@arena, 'min', 2)) {
		@msg[] = array('&a[START] ', '/pvp start '.@id);
	}
	@msg[] = '&r'.player().' joined '. to_upper(if(array_index_exists(@arena, 'parent'), @arena['parent'].': ').@id)
			. ' ('.array_size(@pvp['players']).') ';
	_click_tell(all_players(pworld()), @msg);
	console(player().' joined '.@id, false);
	_menu_refresh_pvp();

	include('player.ms');
	if(@pvp['running'] == 1 || @pvp['running'] == 2) {
		if(array_index_exists(@pvp['arena'], 'resourcepack')) {
			send_resourcepack(player(), 'http://mc.finalscoremc.com:25966/resourcepacks/'.@pvp['arena']['resourcepack'].'.zip');
		}
		if(array_contains(@pvp['spectators'], player())) {
			include('spectator.ms');
			_spectator_remove(player(), @pvp);
		}
		if(array_index_exists(@pvp['arena'], 'team')) {
			_player_assign_team(player(), @pvp);
		}
	}

	if(@pvp['running'] == 0 && array_size(@pvp['players']) == 1 && array_index_exists(@arena, 'options')) {
		if(!array_contains(get_virtual_inventories(), @id.'options')) {
			include('options.ms');
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
				if(array_contains(get_virtual_inventories(), @id.'0')) {
					popen_inventory(player(), @id.'0');
				}
			} else {
				if(array_contains(get_virtual_inventories(), @id.'1')) {
					popen_inventory(player(), @id.'1');
				}
			}
		}

	} else if(@pvp['running'] == 2) {
		include('class.ms');
		_pvp_initialize_players(@id, array(player()));

	} else if(array_index_exists(@arena, 'max') && array_size(@pvp['players']) >= @arena['max']) {
		call_alias('/pvp start '.@id);
	} else if(array_get(@arena, 'min', 2) > array_size(all_players())) {
		msg('There are not enough players to play this game.\nTry another game.');
	}
}
