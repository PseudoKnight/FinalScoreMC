proc _hazard_create() {
	if(!sk_region_exists('hazard')) {
		throw('NotFoundException', 'hazard region does not exist!');
	}
	@game = array(
		'state': 'STARTING',
		'world': pworld(),
		'players': associative_array(),
		'inactivePlayers': associative_array(),
		'round': 0,
		'targetScore': 50,
		'maxRounds': 15,
		'timer': 50,
		'buildTimer': 15,
		'entities': array(),
	);

	if(array_contains(get_scoreboards(), 'hazard')) {
		remove_scoreboard('hazard');
	}
	create_scoreboard('hazard');
	create_objective('score', 'DUMMY', 'hazard');
	set_objective_display('score', array('slot': 'SIDEBAR', 'displayname': color('bold').'Score (target: 100)'), 'hazard');

	if(array_contains(get_bars(), 'hazard')) {
		remove_bar('hazard');
	}
	create_bar('hazard', array('style': 'SEGMENTED_12', 'visible': false));

	export('hazard', @game);
	return(@game);
}

proc _hazard_start(@game) {
	include('events.ms');
	include('entities.ms');

	_add_activity('hazard', 'Hazard', 'hazard', @game['world']);
	_hazard_clean_region(@game);
	_hazard_define_regions(@game);
	_hazard_bind(@game);
	@timer = mutable_primitive(neg(@game['timer']));
	set_interval(1000, closure() {
		if(@game['round'] > 0) {
			foreach(@player: @data in @game['players']) {
				if(!ponline(@player)) {
					_hazard_remove_player(@player, @game);
					continue();
				}
				@regions = sk_current_regions(@player);
				if(pmode(@player) == 'ADVENTURE' && array_contains(@regions, 'hazard_end')) {
					@data['score'] += 10;
					set_pscore('score', @player, @data['score'], 'hazard');
					set_pmode(@player, 'SPECTATOR');
					play_sound(ploc(@player), array('sound': 'ENTITY_VINDICATOR_CELEBRATE', 'pitch': 1.5));
				} else if(!array_contains(@regions, 'hazard')) {
					_hazard_remove_player(@player, @game);
				}
			}
			foreach(@player in all_players(@game['world'])) {
				if(!array_index_exists(@game['players'], @player) && array_contains(sk_current_regions(@player), 'hazard')) {
					_hazard_add_player(@player, @game);
				}
			}
			if(array_size(@game['players']) == 0) {
				clear_task();
				_hazard_end(@game);
				die();
			}
		}

		@timer--;
		if(@timer > 0) {
			if(@game['countdown']) {
				_hazard_msg(@game, color('bold').@timer);
				if(@timer < 12) {
					update_bar('hazard', double(@timer / 12));
				}
			} else {
				@timer++; // keep waiting for the first block placement
			}
		} else if(@timer == 0) {
			@game['state'] = 'RUN';
			_hazard_set_mode(@game, 'ADVENTURE');
			_hazard_spawn_players(@game);
			_hazard_activate_entities(@game);
			update_bar('hazard', array('visible': false));
		} else if(@timer > neg(@game['timer'])) {
			if(!_hazard_are_players_alive(@game)) {
				@timer[] = neg(@game['timer']);
			}
			_hazard_msg(@game, color('bold').(@timer + @game['timer']));
		} else {
			if(@game['round'] == @game['maxRounds'] || _hazard_did_player_win(@game)) {
				_hazard_end(@game);
				clear_task();
			} else {
				@game['state'] = 'BUILD';
				@game['round']++;
				_hazard_set_mode(@game, 'CREATIVE');
				_hazard_spawn_players(@game);
				_hazard_respawn_entities(@game);
				@timer[] = @game['buildTimer'];
				@game['countdown'] = false;
				update_bar('hazard', array('visible': true, 'percent': 1.0));
			}
		}
	});
}

proc _hazard_end(@game) {
	_remove_activity('hazard');
	_hazard_unbind(@game);
	@winner = _hazard_get_winner(@game);
	if(@winner) {
		if(array_size(@winner) > 1) {
			_broadcast(color('bold').array_implode(@winner, ' and ').' won Hazard!');
		} else {
			_broadcast(color('bold').display_name(@winner[0]).color('reset').' won Hazard!');
		}
	}
	foreach(@player in array_keys(@game['players'])) {
		_hazard_remove_player(@player, @game);
	}
	_hazard_remove_entities(@game);
	export('hazard', null);
	remove_scoreboard('hazard');
}

proc _hazard_clean_region(@game) {
	@coords = sk_region_info('hazard', @game['world'], 0);
	sk_pos1('~console', @coords[0]);
	sk_pos2('~console', @coords[1]);
	sk_setblock('~console', 'air');
	sk_pos1('~console', null);
	sk_pos2('~console', null);
}

proc _hazard_define_regions(@game) {
	@coords = sk_region_info('hazard', @game['world'], 0);
	@size = array_size(@game['players']) + 1;

	// define start region
	@startX = rand(@coords[1][0] + 1, @coords[1][0] + integer((@coords[0][0] - @coords[1][0]) / 3) - @size);
	@startY = rand(@coords[1][1] + 1, @coords[0][1] - 2);
	@startZ = rand(@coords[1][2] + 1, @coords[0][2] - @size);
	@start = array(
		array(@startX + @size, @startY + 3, @startZ + @size),
		array(@startX, @startY, @startZ);
	);
	if(!sk_region_exists('hazard_start')) {
		sk_region_create(@game['world'], 'hazard_start', @start);
	} else {
		sk_region_update(@game['world'], 'hazard_start', @start);
	}

	//set start platform
	@start[0][1] -= 3; // floor only
	@start[0][3] = @game['world']; // add worlds for console selection
	@start[1][3] = @game['world'];
	sk_pos1('~console', @start[0]);
	sk_pos2('~console', @start[1]);
	sk_setblock('~console', 'iron_block');

	// define end region
	@size = 3;
	@endX = rand(@coords[1][0] + integer((@coords[0][0] - @coords[1][0]) * 2 / 3), @coords[0][0] - @size);
	@endY = rand(@coords[1][1] + 1, @coords[0][1] - 2);
	@endZ = rand(@coords[1][2] + 1, @coords[0][2] - @size);
	@end = array(
		array(@endX + @size, @endY + 3, @endZ + @size),
		array(@endX, @endY, @endZ);
	);
	if(!sk_region_exists('hazard_end')) {
		sk_region_create(@game['world'], 'hazard_end', @end);
	} else {
		sk_region_update(@game['world'], 'hazard_end', @end);
	}

	//set end platform
	@end[0][1] -= 3; // floor only
	@end[0][3] = @game['world']; // add worlds for console selection
	@end[1][3] = @game['world'];
	sk_pos1('~console', @end[0]);
	sk_pos2('~console', @end[1]);
	sk_setblock('~console', 'emerald_block');

	// clear selection
	sk_pos1('~console', null);
	sk_pos2('~console', null);
}
