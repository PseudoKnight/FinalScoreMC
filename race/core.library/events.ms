proc _race_bind_events(@race) {
	if(@race['type'] == 'boat' || @race['type'] == 'horse' || @race['type'] == 'pig') {
		@race['binds'][] = bind(entity_dismount, null, array('type': 'PLAYER'), @event, @race) {
			try {
				@player = player(@event['id']);
				if(array_index_exists(@race['players'], @player) && @race['players'][@player]['state'] != 'respawning') {
					cancel();
					play_sound(entity_loc(@event['id']), array('sound': 'ENTITY_VILLAGER_YES'));
				}
			} catch(PlayerOfflineException @ex) {
				// entity was not a player
			}
		}
		
		@race['binds'][] = bind(vehicle_destroy, null, array('vehicletype': to_upper(@race['type'])), @event, @race) {
			@rider = get_entity_rider(@event['vehicle']);
			if(@rider) {
				try {
					@player = player(@rider);
					if(array_index_exists(@race['players'], @player)) {
						cancel();
					}
				} catch(PlayerOfflineException @ex) {
					// entity rider was not a player
				}
			}
		}
	}
	
	@race['binds'][] = bind(entity_damage, null, array('type': 'PLAYER', 'cause': 'FALL'), @event, @race) {
		if(array_index_exists(@race['players'], player())) {
			cancel();
		}
	}

	@race['binds'][] = bind(player_quit, null, null, @event, @race) {
		if(array_index_exists(@race['players'], player())) {
			@vehicle = get_entity_vehicle(puuid());
			if(@vehicle) {
				@stand = get_entity_vehicle(@vehicle);
				if(@stand) {
					entity_remove(@stand);
				}
				entity_remove(@vehicle);
			}
			set_ploc(@race['lobby']);
		}
	}
	
	@race['binds'][] = bind(player_move, null, array('threshold': 2), @event, @race) {
		if(array_index_exists(@race['players'], player())) {
			@loc = _relative(@event['to'], 'up', 0.35);
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
						set_pscore('time', player(), @race['times'][@lap][@checkpoint] - integer(time() / 1000), @id);
					}
				} else if(!array_contains(sk_regions_at(@loc), @race['region'])) {
					@p['state'] = 'respawning';
					@vehicle = get_entity_vehicle(puuid());
					if(@vehicle) {
						entity_remove(@vehicle);
					}
					_race_place_player(@race, player(), @p['loc']);
					set_timeout(1000, closure(){
						_race_drop_player(@race, player());
						@p['state'] = 'racing';
					});
				}
			}
		}
	}
}

proc _race_unbind_events(@race) {
	foreach(@bind in @race['binds']) {
		unbind(@bind);
	}
}
