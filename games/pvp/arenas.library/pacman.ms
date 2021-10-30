proc _arena_prepare(@pvp) {
	@id = @pvp['id'];
	create_objective('dots', 'DUMMY', @id);
	set_objective_display('dots', array(displayname: colorize(array_get(@pvp['arena'], 'goalname', '&aDots Left')), slot: 'SIDEBAR'), @id);
	team_add_player(@pvp['arena']['team'][0]['name'], @pvp['arena']['team'][0]['name'], @id);
	set_pscore('dots', @pvp['arena']['team'][0]['name'], @pvp['arena']['score'], @id);
}

proc _arena_bind_events(@id) {
	@pvp = import('pvp'.@id);
	@pvp['binds'][] = bind('pressure_plate_activated', null, null, @event, @pvp, @id) {
		if(!array_index_exists(@pvp['players'], player())) {
			die();
		}
		@block = get_block(@event['location']);
		if(@block == 'TRIPWIRE') {
			die();
		}
		cancel();
		if(get_pteam(player(), @id)['name'] == 'PAC-MAN') {
			if(@block == 'LIGHT_WEIGHTED_PRESSURE_PLATE') {
				@dots = get_pscore('dots', 'PAC-MAN', @id) - 1;
				set_pscore('dots', 'PAC-MAN', @dots, @id);
				@pvp['stats'][player()]['pickups']++;
				play_sound(@event['location'], array(sound: 'ENTITY_CHICKEN_EGG', pitch: 2), player());
				if(@dots == 0) {
					_pvp_end_match(@id, @pvp['team'][0]['players']);
				}
			} else if(@block == 'HEAVY_WEIGHTED_PRESSURE_PLATE') {
				play_sound(@event['location'], array(sound: 'ENTITY_ILLUSIONER_PREPARE_BLINDNESS', pitch: 1.4, volume: 3));
				set_peffect(player(), 'NIGHT_VISION', 1, 15);
				set_block(location_shift(@event['location'], 'up', 27), 'AIR');
				@scaredyghost = array(
					103: array(name: 'BLUE_CONCRETE'),
					102: array(name: 'LEATHER_CHESTPLATE', meta: array(color: array(r: 60, g: 68, b: 170))),
				);
				foreach(@p: @player in @pvp['players']) {
					if(@p != player()) {
						@hat = pinv(@p, 103);
						if(@hat) {
							set_pinv(@p, @scaredyghost);
							set_peffect(@p, 'SPEED', -3, 15);
						}
					}
				}
				set_timeout(15000, closure(){
					foreach(@p: @player in @pvp['players']) {
						if(@p != player()) {
							@hat = pinv(@p, 103);
							if(@hat) {
								_player_equip(@id, @p);
							}
						}
					}
				});
			}
			set_block(@event['location'], 'AIR');
		}
	}
	
	@pvp['binds'][] = bind('entity_damage_player', null, null, @event, @pvp, @id) {
		if(!array_index_exists(@pvp['players'], player())) {
			die();
		}
		cancel();
		@team = get_pteam(player(), @id)['name'];
		@damagerTeam = get_pteam(player(@event['id']), @id)['name'];
		if(@damagerTeam == 'PAC-MAN') {
			@hat = pinv(player(), 103);
			if(@hat && @hat['name'] == 'BLUE_CONCRETE') {
				play_sound(ploc(), array(sound: 'ENTITY_WOLF_HOWL', pitch: 1.7, volume: 3));
				@pvp['stats'][player(@event['id'])]['kills']++;
				@pvp['stats'][player()]['deaths']++;
				@newInv = array(null: array(name: 'ENDER_EYE'), -106: array(name: 'ENDER_EYE'), 102: null, 103: null);
				set_pinv(@newInv);
				set_interval(1000, closure(){
					try {
						@regions = sk_current_regions();
						if(array_contains(@regions, 'ghostspawn')) {
							clear_task();
							_player_equip(@id, player());
							set_peffect(player(), 'SPEED', 0, 0, false, false);
							play_sound(ploc(), array(sound: 'ENTITY_FIREWORK_ROCKET_LAUNCH', pitch: 1.3), player());
						} else if(!array_contains(@regions, 'pacman')) {
							clear_task();
						} else {
							action_msg(player(), colorize('&kX&r Return to Spawn &k&X'));
						}
					} catch(PlayerOfflineException @ex) {
						clear_task();
					}
				});
			}
		} else if(@damagerTeam == 'GHOSTS' && @team != 'GHOSTS') {
			@hat = pinv(player(@event['id']), 103);
			if(@hat && @hat['name'] != 'BLUE_CONCRETE') {
				@hat = pinv(player(), 103);
				if(@hat) {
					_clear_pinv(player());
					play_sound(ploc(), array(sound: 'ENTITY_ZOMBIE_VILLAGER_CONVERTED', pitch: 2, volume: 3));
					@pvp['players'][player()]['lives']--;
					@pvp['stats'][player()]['deaths']++;
					@pvp['stats'][player(@event['id'])]['kills']++;
					if(@pvp['players'][player()]['lives'] == 0) {
						_pvp_end_match(@id, @pvp['team'][1]['players']);
					} else {
						foreach(@p: @player in @pvp['players']) {
							_player_equip(@id, @p);
							@team = @player['team'];
							@loc = array_get_rand(@pvp['arena']['spawn'][@team]);
							set_ploc(@p, @loc);
							set_peffect(@p, 'SLOWNESS', 10, 3);
						}
					}
				}
			}
		}
	}
	
	@pvp['binds'][] = bind('player_interact', null, array(itemname: 'ENDER_EYE', button: 'right'), @event, @pvp) {
		if(array_index_exists(@pvp['players'], player())) {
			cancel();
		}
	}
}

// Override
proc _stats_table(){
	return(array(
		array('kills', 2, '-------', 'K'),
		array('deaths', 2, '--------', 'D'),
		array('pickups', 3, '-------', 'PKS'),
		array('damage', 2, '----', 'DMG'),
	));
}
