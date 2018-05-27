include('player.ms');
include('events.ms');

proc _race_create_and_join(@id) {
	@race = import('race'.@id);
	if(!@race) {
		@race = _race_create(@id);
		_race_add_player(@id, player());
		@msg = player().' queued up a race on the '.to_upper(@id[0]).substr(@id, 1).' track.';
		_click_tell(all_players(pworld()), array('&7[Race] ', array('&b[JOIN] ', '/race join '.@id), @msg));
	} else if(!array_index_exists(@race['players'], player()) && @race['state'] != 'ending') {
		if(@race['state'] == 'countdown' || @race['state'] == 'running') {
			_race_prepare_player(@race, player());
			_race_place_player(@race, player(), array_rand(@race['spawn'], 1, false)[0]);
			if(@race['state'] == 'running') {
				set_timeout(1000, closure(){
					_race_drop_player(@race, player());
				});
			}
		}
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
	
	// check track requirements
	if(!array_index_exists(@track, 'spawn')) {
		die(color('red').'Race spawn locations for '.@id.' are missing.');
	}
	if(!array_index_exists(@track, 'checkpoint')) {
		die(color('red').'Race checkpoints for '.@id.' are missing.');
	}
	if(!array_index_exists(@track, 'region')) {
		die(color('red').'Race region for '.@id.' is missing.');
	}
	
	// game object
	@race = array_merge(array(
		'type': 'parkour', // default
		'lobby': get_spawn(pworld()), // default
		'laps': 1, // default
		'id': @id,
		'players': associative_array(),
		'state': 'queued',
		'binds': array(),
		'place': 1,
		'world': pworld(),
		'times': associative_array(),
	), @track);
	export('race'.@id, @race);
	
	// scoreboard
	create_scoreboard(@id);
	create_objective('time', 'DUMMY', @id);
	set_objective_display('time', array('displayname': to_upper(@id).' RACE', 'slot': 'SIDEBAR'), @id);
	create_team('collision', @id);
	set_team_options('collision', array('collisionrule': 'NEVER'), @id);
	
	return(@race);
}

proc _race_countdown(@race) {
	if(@race['state'] != 'queued') {
		return();
	}
	@race['state'] = 'countdown';
	set_timeout(1000, closure(){ // delay to load chunks first
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
					_worldmsg(pworld(), color('gray').'[Race]'.color('green').' Starting in '.@startTime.' seconds...');
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
	});
}

proc _race_start(@race) {
	@race['state'] = 'running';
	foreach(@p: @v in @race['players']) {
		title_msg(@p, color('green')'Go!', '', 0, 40, 20);
	}
	play_sound(ploc(), array('sound': 'NOTE_PLING', 'pitch': 2));
	_race_drop_players(@race);
	
	@race['binds'][] = bind(player_move, null, null, @event, @race) {
		if(array_index_exists(@race['players'], player())) {
			@loc = location_shift(@event['to'], 'up', 0.35);
			play_effect(@loc, 'FIREWORKS_SPARK', array('speed': 0));
			@p = @race['players'][player()];
			if(@p['state'] != 'finished') {
				@checkpoint = @p['checkpoint'];
				@cuboid = @race['checkpoint'][@checkpoint];
				@p1 = @cuboid[0];
				@p2 = @cuboid[1];
				if(@loc['x'] < @p1[0] && @loc['x'] > @p2[0]
				&& @loc['y'] < @p1[1] && @loc['y'] > @p2[1]
				&& @loc['z'] < @p1[2] && @loc['z'] > @p2[2]) {
					// hit checkpoint
					@checkpoint++;
					@p['loc'] = @loc;
					if(@checkpoint != array_size(@race['checkpoint'])) {
						@p['checkpoint'] = @checkpoint;
						action_msg(color('green').'Checkpoint!');
						play_sound(@loc, array('sound': 'SUCCESSFUL_HIT'), player());
					} else {
						// hit lap
						@p['checkpoint'] = 0;
						@p['lap']++;
						if(@p['lap'] == @race['laps']) {
							// finished race
							@p['state'] = 'finished';
							@p['place'] = (@race['place']++);
							@suffix = 'th';
							switch(@p['place']) {
								case 1:
									@suffix = 'st';
									@award = (array_size(@race['players']) - 1) * @race['laps'];
									if(@award) {
										_acc_add(player(), @award);
										msg(color('gold').'+'.@award.' Coins');
									}
								case 2:
									@suffix = 'nd';
									@award = array_size(@race['players']) - 2;
									if(@award > 0) {
										_acc_add(player(), @award);
										msg(color('gold').'+'.@award.' Coins');
									}
								case 3:
									@suffix = 'rd';
							}
							_worldmsg(pworld(), color('gray').'[Race] '.player().' finished '.color('green').color('bold').@p['place'].@suffix.'!');
							play_sound(@loc, array('sound': 'UI_TOAST_CHALLENGE_COMPLETE', 'volume': 3), player());
							_race_check_players(@race);
						} else {
							title('', color('green').'Lap '.(@race['players'][player()]['lap'] + 1).' / '.@race['laps'], 0, 60, 20);
							play_sound(@loc, array('sound': 'ENTITY_PLAYER_LEVELUP', 'pitch': 0.7), player());
						}
					}
					// set pace time
					@lap = @p['lap'];
					if(!array_index_exists(@race['times'], @lap)
					|| !array_index_exists(@race['times'][@lap], @checkpoint)) {
						@race['times'][@lap][@checkpoint] = integer(time() / 1000);
						set_pscore('time', player(), 0, @race['id']);
					} else {
						set_pscore('time', player(), @race['times'][@lap][@checkpoint] - integer(time() / 1000), @race['id']);
					}
				} else if(!array_contains(sk_regions_at(@loc), @race['region'])) {
					@vehicle = get_entity_vehicle(puuid());
					if(@vehicle) {
						@bind = bind(entity_dismount, array('priority': 'HIGH'), null, @event) {
							consume();
						}
						set_entity_rider(null, puuid());
						entity_remove(@vehicle);
						unbind(@bind);
					}
					_race_place_player(@race, player(), @p['loc']);
					set_timeout(1000, closure(){
						_race_drop_player(@race, player());
					});
				}
			} else if(!array_contains(sk_regions_at(@loc), @race['region'])) {
				_race_remove_player(@race, player());
			}
		}
	}
}

proc _race_check_players(@race) {
	@racing = 0;
	foreach(@p: @v in @race['players']) {
		if(@v['state'] != 'finished') {
			@racing++;
		}
	}
	if(@racing == 1) {
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
