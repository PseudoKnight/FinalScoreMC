include('../../../entities/custom.library/kart.ms');
include('player.ms');
include('items.ms');
include('events.ms');

proc _race_create_and_join(@id) {
	@race = import('race'.@id);
	if(!@race) {
		@race = _race_create(@id);
		_race_add_player(@id, player());
		@msg = player().' queued up a race on the '.to_upper(@id[0]).substr(@id, 1).' track.';
		_click_tell(all_players(pworld()), array('&7[Race] ', array('&b[JOIN] ', '/race join '.@id), @msg));
	} else if(!array_index_exists(@race['players'], player()) && @race['state'] !== 'ending') {
		_race_add_player(@id, player());
		if(@race['state'] === 'countdown' || @race['state'] === 'running') {
			_race_prepare_player(@race, player());
			_race_place_player(@race, player(), array_get_rand(@race['spawn']));
			if(@race['state'] === 'running') {
				set_timeout(500, closure(){
					_race_drop_player(@race, player());
				});
			}
		}
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
	if(!sk_region_exists(pworld(), @track['region'])) {
		die(color('red').'Race region does not exist in this world.');
	}

	@items = array();
	if(array_index_exists(@track, 'itemspawn') && array_index_exists(@track, 'item')) {
		@items = array_resize(array(), array_size(@track['itemspawn']));
	}

	// game object
	@race = array_merge(array(
		type: 'parkour', // default
		lobby: get_spawn(pworld()), // default
		laps: 1, // default
		id: @id,
		players: associative_array(),
		state: 'queued',
		binds: array(),
		place: 1,
		world: pworld(),
		times: associative_array(),
		items: @items,
	), @track);
	export('race'.@id, @race);

	// scoreboard
	create_scoreboard(@id);
	create_objective('time', 'DUMMY', @id);
	set_objective_display('time', array(displayname: to_upper(@id).' RACE', slot: 'SIDEBAR'), @id);
	create_team('collision', @id);
	set_team_options('collision', array(collisionrule: 'NEVER', friendlyinvisibles: false), @id);

	return(@race);
}

proc _race_countdown(@race) {
	if(@race['state'] !== 'queued') {
		return();
	}
	@race['state'] = 'countdown';

	_add_activity('race'.@race['id'], 'Race: '._to_upper_camel_case(@race['id']));

	create_bar('race'.@race['id'], array(style: 'SEGMENTED_6', percent: 0.0, color: 'WHITE'));
	foreach(@p: @v in @race['players']) {
		if(ponline(@p)) {
			bar_add_player('race'.@race['id'], @p);
		} else {
			array_remove(@race['players'], @p);
		}
	}

	_race_place_players(@race);
	_race_bind_events(@race);
	@startTime = 6;
	@timer = array(@startTime);
	set_interval(1000, closure(){
		@timer[0]--;
		if(@timer[0] < 0) {
			clear_task();
			remove_bar('race'.@race['id']);
			die();
		}
		foreach(@p: @v in @race['players']) {
			if(!ponline(@p) || !array_contains(sk_current_regions(@p), @race['region'])) {
				array_remove(@race['players'], @p);
			}
		}
		if(!@race['players']) {
			clear_task();
			_race_end(@race);
			remove_bar('race'.@race['id']);
		} else if(@timer[0] == 0) {
			_race_start(@race);
			update_bar('race'.@race['id'], array(percent: 1.0, color: 'GREEN'));
		} else if(@timer[0] < 4) {
			update_bar('race'.@race['id'], array(percent: 1 - @timer[0] / 6, color: 'YELLOW'));
			play_sound(ploc(), array(sound: 'BLOCK_NOTE_BLOCK_BIT'));
		} else {
			update_bar('race'.@race['id'], array(percent: 1 - @timer[0] / 6));
		}
	});
}

proc _race_on_move(@player, @to, @race) {
	@loc = location_shift(@to, 'up', 0.35);
	@p = @race['players'][@player];
	if(@p['state'] !== 'finished') {
		@checkpoint = @p['checkpoint'];
		@cuboid = @race['checkpoint'][@checkpoint];
		@p1 = @cuboid[0];
		@p2 = @cuboid[1];
		if(@loc['x'] < @p1[0] && @loc['x'] > @p2[0]
		&& @loc['y'] < @p1[1] && @loc['y'] > @p2[1]
		&& @loc['z'] < @p1[2] && @loc['z'] > @p2[2]) {
			// hit checkpoint
			@p['checkpointLoc'] = @loc[];
			if(@race['type'] === 'kart') {
				if(array_size(@cuboid) == 3) {
					@p['kart']['camdist'] = @cuboid[2];
				} else if(array_index_exists(@race, 'camdist')) {
					@p['kart']['camdist'] = @race['camdist'];
				}
			}

			@checkpoint++;
			if(@checkpoint != array_size(@race['checkpoint'])) {
				@p['checkpoint'] = @checkpoint;
				action_msg(@player, color('green').'Checkpoint!');
				play_sound(ploc(@player), array(sound: 'ENTITY_ARROW_HIT_PLAYER'), @player);
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
								_acc_add(@player, @award);
								tmsg(@player, color('gold').'+'.@award.' Coins');
							}
						case 2:
							@suffix = 'nd';
							@award = array_size(@race['players']) - 2;
							if(@award > 0) {
								_acc_add(@player, @award);
								tmsg(@player, color('gold').'+'.@award.' Coins');
							}
						case 3:
							@suffix = 'rd';
					}
					broadcast(color('gray').'[Race] '.@player.' finished '.color('green').color('bold').@p['place'].@suffix.'!', all_players(pworld(@player)));
					play_sound(ploc(@player), array(sound: 'UI_TOAST_CHALLENGE_COMPLETE', volume: 3), @player);
					_race_check_players(@race);
				} else {
					title(@player, '', color('green').'Lap '.(@p['lap'] + 1).' / '.@race['laps'], 0, 60, 20);
					play_sound(ploc(@player), array(sound: 'ENTITY_PLAYER_LEVELUP', pitch: 0.7), @player);
				}
			}
			// set pace time
			@lap = @p['lap'];
			if(!array_index_exists(@race['times'], @lap)
			|| !array_index_exists(@race['times'][@lap], @checkpoint)) {
				@race['times'][@lap][@checkpoint] = integer(time() / 1000);
				set_pscore('time', @player, 0, @race['id']);
			} else {
				set_pscore('time', @player, @race['times'][@lap][@checkpoint] - integer(time() / 1000), @race['id']);
			}
		} else if(sk_region_contains(@race['region'], @loc)) {
			// ensure they are still in a vehicle in vehicle races
			if(@race['type'] === 'kart' && !entity_exists(@p['kart']['engine'])
			|| !get_entity_vehicle(puuid(@player))
			&& @p['state'] !== 'waiting'
			&& array_contains(array('pig', 'boat', 'horse'), @race['type'])) {
				set_timeout(10, closure(){
					@success = _race_place_player(@race, @player, @p['checkpointLoc']);
					if(@success && @race['state'] === 'running') {
						set_timeout(500, closure(){
							_race_drop_player(@race, @player);
						});
					}
				});
			}
			if(array_index_exists(@race, 'itemspawn') && @p['itemCooldown'] <= 0) {
				for(@i = 0, @i < array_size(@race['itemspawn']), @i++) {
					if(distance(@loc, @race['itemspawn'][@i]) < 1.5) {
						@spec = entity_spec(@race['items'][@i]);
						if(@spec['item']) {
							for(@slot = 0, @slot < 8, @slot++) {
								if(!pinv(@player, @slot)) {
									set_pinv(@player, @slot, @spec['item']);
									play_sound(ploc(@player), array(sound: 'ENTITY_CHICKEN_EGG'), @player);
									if(@race['type'] === 'kart') {
										_kart_show_item(@player, @p['kart']);
									}
									@p['itemCooldown'] = 20;
									break();
								}
							}
							set_entity_spec(@race['items'][@i], array(item: null));
							set_entity_spec(get_entity_rider(@race['items'][@i]), array(item: null));
							set_display_entity(@race['items'][@i], array(brightness: 0));
						}
						break();
					}
				}
			} else {
				@p['itemCooldown']--;
			}
		} else {
			_race_remove_vehicle(@player, @race);
			if(!_psession()['activity']) {
				_race_place_player(@race, @player, @p['checkpointLoc']);
				set_timeout(500, closure(){
					_race_drop_player(@race, @player);
				});
			} else {
				// they probably joined some other game, prioritize the other game
				array_remove(@race['players'], @player);
				_race_check_players(@race);
			}
		}
	} else if(!sk_region_contains(@race['region'], @loc)) {
		_race_remove_player(@race, @player);
	}
}

proc _race_start(@race) {
	@race['state'] = 'running';
	foreach(@p: @v in @race['players']) {
		title(@p, color('green').'Go!', null, 0, 40, 20);
	}
	play_sound(ploc(), array(sound: 'BLOCK_NOTE_BLOCK_BIT', pitch: 2));
	_race_drop_players(@race);
	_race_spawn_items(@race);

	if(@race['type'] !== 'kart') {
		@race['binds'][] = bind('player_move', null, array(from: array(world: @race['world'])), @event, @race) {
			if(array_index_exists(@race['players'], player())) {
				_race_on_move(player(), @event['to'], @race);
			}
		}
	}
}

proc _race_remove_vehicle(@player, @race) {
	if(@race['type'] === 'kart') {
		try(_kart_remove(@player, @race['players'][@player]['kart']))
	} else {
		try {
			@vehicle = pvehicle(@player);
			if(@vehicle) {
				@stand = get_entity_vehicle(@vehicle);
				if(@stand) {
					entity_remove(@stand);
				}
				entity_remove(@vehicle);
			}
		} catch(BadEntityException @ex) {
			console('Failed to remove vehicle: '.@ex);
		}
	}
}

proc _race_check_players(@race) {
	@racing = 0;
	foreach(@p: @v in @race['players']) {
		if(@v['state'] !== 'finished') {
			@racing++;
		}
	}
	if(@racing <= 1) {
		_race_end(@race);
	}
}

proc _race_end(@race) {
	if(!@race) {
		die(color('gold').'That race isn\'t running.')
	} else if(@race['state'] === 'ending' || @race['state'] === 'countdown') {
		return();
	}
	@race['state'] = 'ending';
	set_timeout(5000, closure(){
		_remove_activity('race'.@race['id']);
		_race_unbind_events(@race);
		_race_remove_players(@race);
		remove_scoreboard(@race['id']);
		export('race'.@race['id'], null);
	});
}
