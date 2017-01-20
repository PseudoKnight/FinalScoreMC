proc _pvp_join(@id, @force){
	@pvp = import('pvp'.@id);
	@arena = get_value('arena.'.@id);
	if(!@arena) {
		die('Can\'t find that arena.');
	}
	if(_is_survival_world(pworld()) && array_index_exists(@arena, 'lobby')) {
		set_ploc(@arena['lobby']);
	}
	if(_pstate(player())['activity']) {
		if(@force) {
			_set_pstate_activity(player(), null);
		} else {
			@msg = array(
				'You are already playing \\"'._pstate(player())['activity'].'\\". ',
				array('&b[FORCE JOIN]', '/pvp join '.@id.' force')
			);
			_click_tell(array(player()), @msg);
			die();
		}
	}
	if(!@pvp) {
		@pvp = array('players': associative_array(), 'running': 0);
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
	@msg = array(
		'&7[PVP] &r'.player().' joined '
		. to_upper(if(array_index_exists(@arena, 'parent'), @arena['parent'].': ').@id)
		. '. ('.array_size(@pvp['players']).') ',
		array('&b[JOIN]', '/pvp join '.@id)
	);
	if(array_size(@pvp['players']) >= array_get(@arena, 'min', 2)) {
		@msg[] = ' ';
		@msg[] = array('&a[START]', '/pvp start '.@id);
	}
	_click_tell(all_players(pworld()), @msg);
	console(player().' joined '.@id, false);

	include('player.ms');
	if(@pvp['running'] == 1 || @pvp['running'] == 2) {
		if(array_index_exists(@pvp['arena'], 'resourcepack')) {
			send_resourcepack(player(), 'http://mc.finalscoremc.com:25966/resourcepacks/'.@pvp['arena']['resourcepack'].'.zip');
		}
		if(array_contains(@pvp['spectators'], player())) {
			include('spectator.ms');
			_remove_spectator(player(), @pvp);
		}
		if(array_index_exists(@pvp['arena'], 'team')) {
			_assign_team(player(), @pvp);
		}
	}

	if(@pvp['running'] == 0 && array_size(@pvp['players']) == 1 && array_index_exists(@arena, 'options')) {
		if(!array_contains(all_virtualchests(), @id.'options')) {
			include('options.ms');
			_create_options_menu(@id, @arena);
		}
		popen_virtualchest(@id.'options');

	} else if(@pvp['running'] == 0 && array_index_exists(@arena, 'arenaselect') && @arena['arenaselect']['type'] == 'vote') {
		@msg = '["'.color(6).'Vote for arena:'.color('r').'\n"';
		foreach(@arena in @arena['arenaselect']['arenas']) {
			@msg .= ',{"text":"'.to_upper(@arena).' ","clickEvent":{"action":"run_command","value":"/pvp vote '.@id.' '.@arena.'"}}';
		}
		runas('~console', '/tellraw '.player().' '.@msg.']');

	} else if(@pvp['running'] == 1) {
		if(array_index_exists(@pvp['arena'], 'classes')) {
			if(!array_index_exists(@pvp['players'][player()], 'team') || @pvp['players'][player()]['team'] == 0) {
				if(array_contains(all_virtualchests(), @id.'0')) {
					popen_virtualchest(player(), @id.'0');
				}
			} else {
				if(array_contains(all_virtualchests(), @id.'1')) {
					popen_virtualchest(player(), @id.'1');
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
