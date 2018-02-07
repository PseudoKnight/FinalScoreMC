proc _race_bind_events(@race) {
	@race['binds'][] = bind(entity_dismount, null, array('type': 'PLAYER'), @event, @race) {
		if(array_index_exists(@race['players'], player(@event['id']))) {
			cancel();
			set_timeout(50, closure(){
				if(entity_exists(@event['mountid'])) {
					play_sound(entity_loc(@event['id']), array('sound': 'ENTITY_VILLAGER_YES'));
				}
			});
		}
	}
	@race['binds'][] = bind(entity_damage, null, array('type': 'PLAYER', 'cause': 'FALL'), @event, @race) {
		if(array_index_exists(@race['players'], player())) {
			cancel();
		}
	}
	@race['binds'][] = bind(player_move, null, array('threshold': 2), @event, @race) {
		if(array_index_exists(@race['players'], player())) {
			play_effect(_relative(@event['to'], 'up', 0.2), 'FIREWORKS_SPARK', array('speed': 0));
			@p = @race['players'][player()];
			if(!@p['finished']) {
				@checkpoint = @p['checkpoint'];
				@cuboid = @race['checkpoint'][@checkpoint];
				@p1 = @cuboid[0];
				@p2 = @cuboid[1];
				@loc = @event['to'];
				if(@loc['x'] < @p1[0] && @loc['x'] > @p2[0]
				&& @loc['y'] < @p1[1] && @loc['y'] > @p2[1]
				&& @loc['z'] < @p1[2] && @loc['z'] > @p2[2]) {
					// hit checkpoint
					@checkpoint++;
					play_sound(@event['to'], array('sound': 'SUCCESSFUL_HIT'), player());
					@p['loc'] = _relative(@event['to'], 'up', 0.5);
					if(@checkpoint != array_size(@race['checkpoint'])) {
						@p['checkpoint'] = @checkpoint;
						title('', color('green').'Checkpoint!', 0, 40, 20);
					} else {
						// hit lap
						@p['checkpoint'] = 0;
						@p['lap']++;
						if(@p['lap'] == @race['laps']) {
							// finished race
							@p['finished'] = true;
							@p['place'] = (@race['place']++);
							@suffix = 'th';
							switch(@p['place']) {
								case 1:
									@suffix = 'st';
								case 2:
									@suffix = 'nd';
								case 3:
									@suffix = 'rd';
							}
							_worldmsg(pworld(), color('gray').'[Race] '.player().' finished '.color('green').color('bold').@p['place'].@suffix.'!');
							_race_check_players(@race);
						} else {
							title('', color('green').'Lap '.(@race['players'][player()]['lap'] + 1), 0, 60, 20);
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
				} else if(!array_contains(sk_current_regions(), @race['region'])) {
					@vehicle = get_entity_vehicle(puuid());
					if(@vehicle) {
						entity_remove(@vehicle);
					}
					_race_place_player(@race, player(), @p['loc']);
					set_timeout(1000, closure(){
						_race_drop_player(@race, player());
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
