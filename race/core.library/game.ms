include('player.ms');
include('events.ms');

proc _race_create_and_join(@id) {
	@race = import('race'.@id);
	if(!@race) {
		@race = _race_create(@id);
		_race_add_player(@id, player());
		_click_tell(all_players(pworld()), array('&7[Race] ', array('&b[JOIN] ', '/race join '.@id), player().' queued up a race.'));
	} else if(!array_index_exists(@race['players'], player())) {
		_race_add_player(@id, player());
		_click_tell(all_players(pworld()), array('&7[Race] ', array('&b[JOIN] ', '/race join '.@id), player().' joined the race.'));
	}
	return(@race);
}

proc _race_create(@id) {
	@track = get_value('track', @id);
	if(!@track) {
		throw('NotFoundException', 'That track does not exist.');
	}
	
	// game object
	@race = array_merge(@track, array(
		'id': @id,
		'players': associative_array(),
		'state': 'queued',
		'binds': array(),
		'place': 1,
		'world': pworld(),
		'times': associative_array();
	));
	export('race'.@id, @race);
	
	// scoreboard
	create_scoreboard(@id);
	create_objective('time', 'DUMMY', @id);
	set_objective_display('time', array('displayname': to_upper(@id).' RACE', 'slot': 'SIDEBAR'), @id);
	
	return(@race);
}

proc _race_countdown(@race) {
	@race['state'] = 'countdown';
	_race_place_players(@race);
	_race_bind_events(@race);
	@startTime = 15;
	@timer = array(@startTime);
	set_interval(1000, closure(){
		foreach(@p: @v in @race['players']) {
			if(!ponline(@p) || !array_contains(sk_current_regions(@p), @race['region'])) {
				array_remove(@race['players'], @p);
			}
		}
		if(!@race['players']) {
			clear_task();
			_race_end(@race);
		} else if(@timer[0] == @startTime) {
			if(array_size(@race['players']) > 0) {
				_worldmsg(pworld(), color('green').'Race starting in '.@startTime.' seconds...');
				@timer[0]--;
			}
		} else if(@timer[0] == 1) {
			clear_task();
			_race_start(@race);
		} else {
			@timer[0]--;
			foreach(@p: @v in @race['players']) {
				title_msg(@p, '', @timer[0], 0, 30, 0);
			}
			if(@timer[0] < 4) {
				play_sound(ploc(), array('sound': 'NOTE_PLING'));
			}
		}
	});
}

proc _race_start(@race) {
	@race['state'] = 'running';
	foreach(@p: @v in @race['players']) {
		title_msg(@p, color('green')'Go!', '', 0, 40, 20);
	}
	play_sound(ploc(), array('sound': 'NOTE_PLING', 'pitch': 2));
	_race_drop_players(@race);
}

proc _race_check_players(@race) {
	@racing = 0;
	foreach(@p: @v in @race['players']) {
		if(!@v['finished']) {
			@racing++;
		}
	}
	if(@racing == 0) {
		_race_end(@race);
	}
}

proc _race_end(@race) {
	if(!@race) {
		die(color('gold').'That race isn\'t running.')
	} else if(@race['state'] == 'ending') {
		return();
	}
	@race['state'] = 'ending';
	set_timeout(7000, closure(){
		_race_unbind_events(@race);
		_race_remove_players(@race);
		remove_scoreboard(@race['id']);
		export('race'.@race['id'], null);
	});
}
