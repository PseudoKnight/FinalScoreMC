proc _hazard_create() {
	if(!sk_region_exists('hazard')) {
		throw('NotFoundException', 'hazard region does not exist!');
	}
	@game = array(
		state: 'STARTING',
		world: pworld(),
		players: associative_array(),
		inactivePlayers: associative_array(),
		round: 0,
		targetScore: 50,
		maxRounds: 20,
		timer: 60,
		buildTimer: 60,
		buildCount: 12, // can be 6, 10, 12, or 20
		entities: array(),
		blocks: array(),
		binds: array(),
		randomStart: true,
	);

	if(array_contains(get_scoreboards(), 'hazard')) {
		remove_scoreboard('hazard');
	}
	create_scoreboard('hazard');
	create_objective('score', 'DUMMY', 'hazard');
	set_objective_display('score', array(slot: 'SIDEBAR', displayname: color('bold').'Score (target: '.@game['targetScore'].')'), 'hazard');

	if(array_contains(get_bars(), 'hazard')) {
		remove_bar('hazard');
	}
	create_bar('hazard');

	export('hazard', @game);
	return(@game);
}

proc _hazard_start(@game) {
	_add_activity('hazard', 'Hazard', 'hazard', @game['world']);
	_hazard_clean_region(@game);
	_hazard_define_regions(@game);
	_hazard_bind(@game);

	foreach(@player in all_players(@game['world'])) {
		if(array_contains(sk_current_regions(@player), 'hazard')) {
			_hazard_add_player(@player, @game);
		}
	}

	@timer = mutable_primitive(neg(@game['timer']));
	set_interval(1000, 0, closure() {
		@timer--;
		if(@timer > 0) { // BUILD PHASE
			if(@timer == 10) {
				update_bar('hazard', array(color: 'RED'));
			} else {
				update_bar('hazard', double(@timer / @game['buildTimer']));
			}
			if(@timer <= 10) {
				update_bar('hazard', string(@timer));
			}
			if(_hazard_players_finished_building(@game)) {
				@timer[] = 1; // go to run phase
			}
		} else if(@timer == 0) { // START RUN PHASE
			@game['state'] = 'RUN';
			_hazard_spawn_players(@game);
			_hazard_activate_entities(@game);
			update_bar('hazard', array(
				percent: 1.0,
				title: color('bold').'RUN PHASE '.@game['round'].':'.color('reset').' Get to the target alive!',
				color: 'WHITE'
			));
		} else if(@timer > neg(@game['timer'])) { // RUN PHASE
			if(!_hazard_are_players_alive(@game)) {
				@timer[] = neg(@game['timer']); // end run phase
			}
			@timeLeft = @timer + @game['timer'];
			if(@timeLeft == 10) {
				update_bar('hazard', array(color: 'RED'));
			} else {
				update_bar('hazard', double(@timeLeft / @game['timer']));
			}
			if(@timeLeft <= 10) {
				update_bar('hazard', string(@timeLeft));
			}
		} else {
			if(@game['round'] == @game['maxRounds'] || _hazard_did_player_win(@game)) {
				_hazard_end(@game);
				clear_task();
				die();
			} else { // START BUILD PHASE
				@game['state'] = 'BUILD';
				@game['round']++;
				_hazard_spawn_players(@game);
				_hazard_respawn_entities(@game);
				_hazard_respawn_blocks(@game);
				@timer[] = @game['buildTimer'];
				update_bar('hazard', array(
					percent: 1.0,
					title: color('bold').'BUILD PHASE '.@game['round'].':'.color('reset').' Build to the target!',
					color: 'WHITE'
				));
			}
		}
		if(array_size(@game['players']) == 0) {
			clear_task();
			_hazard_end(@game);
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

	// clean up noisy pistons
	@noisyEvents = array();
	@noisyEvents[] = bind('piston_extend', null, null, @event, @game) {
		if(@game['world'] == @event['location']['world'] && array_contains(sk_regions_at(@event['location']), 'hazard')) {
			cancel();
			set_block(@event['location'], 'AIR');
		}
	}
	@noisyEvents[] = bind('block_dispense', null, null, @event, @game) {
		if(@game['world'] == @event['location']['world'] && array_contains(sk_regions_at(@event['location']), 'hazard')) {
			cancel();
			@inv = array_resize(array(), 27);
			set_inventory(@event['location'], @inv);
			set_block(@event['location'], 'AIR');
		}
	}
	set_timeout(3000, closure(){
		foreach(@bind in @noisyEvents) {
			unbind(@bind);
		}
	});
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
	@size = array_size(@game['players']) + 2;

	// define start region
	@start = null;
	if(@game['randomStart'] || !sk_region_exists('hazard_start')) {
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
	} else {
		@start = sk_region_info('hazard_start', @game['world'], 0);
	}

	//set start platform
	@start[0][1] -= 3; // floor only
	@start[0][3] = @game['world']; // add worlds for console selection
	@start[1][3] = @game['world'];
	sk_pos1('~console', @start[0]);
	sk_pos2('~console', @start[1]);
	sk_setblock('~console', 'smooth_stone');

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
