proc _arena_prepare(@pvp) {
	_generator_create('dungeon', 'static', 'static', @pvp['arena']['lobby'][3], 0, closure(@start, @end, @spawns) {
		@pvp['arena']['spawn'] = array(array(@end), array(@start));
	});
}

proc _arena_bind_events(@id) {
	@pvp = import('pvp'.@id);
	@pvp['binds'][] = bind('player_death', array(priority: 'HIGHEST'), null, @event, @pvp) {
		if(array_index_exists(@pvp['players'], player())) {
			if(@pvp['players'][player()]['team'] == 1) {
				play_sound(ploc(), array(sound: 'ENTITY_WOLF_HOWL', pitch: 1.7, volume: 3));
				@stand = spawn_entity('ARMOR_STAND', 1, @event['location'])[0];
				add_scoreboard_tag(@stand, 'remove');
				set_entity_spec(@stand, array(
					arms: true,
					baseplate: false,
					poses: array(
							poseArmLeft: array(rand() - 0.5, rand() - 0.5, rand() - 0.5),
							poseArmRight: array(rand() - 0.5, rand() - 0.5, rand() - 0.5),
							poseHead: array(rand() - 0.5, rand() - 0.5, rand() - 0.5),
							poseLegLeft: array(rand() - 0.5, rand() - 0.5, rand() - 0.5),
							poseLegRight: array(rand() - 0.5, rand() - 0.5, rand() - 0.5),
						)
				));
			} else {
				play_sound(ploc(), array(sound: 'ENTITY_VEX_DEATH', pitch: 0.5, volume: 3));
			}
		}
	}
	
	@heartsound = array(sound: 'BLOCK_NOTE_BLOCK_BASEDRUM', pitch: 0.5);
	@static = @pvp['team'][0]['players'][0];
	set_interval(50, closure(){
		try {
			if(@pvp['running'] == 2) {
				foreach(@player: @p in @pvp['players']) {
					if(@player != @static && ponline(@player)) {
						@time = time();
						if(!array_index_exists(@p, 'heartrate')) {
							@p['heartrate'] = 1100; // ms between beats
							@p['heartbeat'] = @time + @p['heartrate']; // time at which next beat will occur
							@p['lastscare'] = @time;
						} else if(@time > @p['heartbeat']) {
							@p['heartbeat'] = @time + @p['heartrate'];
							@heartsound['volume'] = 400 / @p['heartrate'] - 0.26;
							play_sound(ploc(@player), @heartsound, array(@player, @static));
							set_timeout(integer(max(50, @p['heartrate'] / 8)), closure() {
								play_sound(ploc(@player), @heartsound, array(@player, @static));
							});
						} else if(@time > @p['lastscare'] + 10000 && @p['heartrate'] < 1100) {
							@p['heartrate'] += 200;
							@p['lastscare'] = @time;
						}
					}
				}
			} else if(@pvp['running'] != 1) {
				clear_task();
			}
		} catch(Exception @ex) {
			// not sure what can go wrong here, but if I have learned anything, something will
			console(@ex);
			clear_task();
		}
	});
}
