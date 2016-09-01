proc _cc_reward(@player) {
	@cc = import('cubeclimber');
	@amount = array_size(@cc['players']);
	_acc_add(@player, @amount);
	tmsg(@player, color('gold').'+'.@amount.' coin'.if(@amount > 1, 's'));
	set_peffect(@player, 8, 5, 10);
}

proc _cc_generate(@world = 'custom') {

	@rg = sk_region_info('cubeclimber_blocks', @world, 0);
	@delay = integer(3000 / (@rg[0][1] - @rg[1][1]));
	@density = rand(4,7);

	for(@y = min(@rg[0][1], @rg[1][1]), @y <= max(@rg[0][1], @rg[1][1]), @y++) {
		queue_push(closure(){
			for(@x = min(@rg[0][0], @rg[1][0]), @x <= max(@rg[0][0], @rg[1][0]), @x++) {
				for(@z = min(@rg[0][2], @rg[1][2]), @z <= max(@rg[0][2], @rg[1][2]), @z++) {
					if(!rand(@density)) {
						set_block_at(@x, @y, @z, '159:'.rand(16), @world, false);
					} else {
						set_block_at(@x, @y, @z, '0:0', @world, false);
					}
				}
			}
		}, 'cc_gen');
		queue_delay(@delay, 'cc_gen');
	}

}

proc _cc_spawn(@player, @world = 'custom') {
	@region = sk_region_info('cubeclimber_blocks', @world, 0);
	@rx = rand(2);
	@rz = rand(2);
	@y = @region[1][1] - 1;
	@yaw = 135;

	if(@rx && @rz) {
		@yaw = -45;
	} else if(@rx && !@rz) {
		@yaw = -135;
	} else if(!@rx && @rz) {
		@yaw = 45;
	}

	set_ploc(@player, array(
		'x': @region[@rx][0] + if(@rx, -1, 1) + 0.5,
		'y': @y,
		'z': @region[@rz][2] + if(@rz, -1, 1) + 0.5,
		'world': @world,
		'yaw': @yaw,
	));

	set_pscore('height', @player, 0, 'cc');
}

proc _cc_add_player(@player, @world = 'custom') {
	@cc = import('cubeclimber');
	@cc['players'][@player] = rand(16);
	set_pscoreboard(@player, 'cc');
	set_pscore('height', @player, -1, 'cc');
	export('cubeclimber', @cc);
}

proc _cc_start(@world = 'custom') {

	@region = sk_region_info('cubeclimber_blocks', @world, 0);
	@secondToStart = 15;

	foreach(@p in all_players()) {
		if(pworld(@p) == @world) {
			tmsg(@p, colorize('&7[&6Cube&cClimber&7] &rStarting in '.@secondToStart.' seconds...'));
		}
	}

	for(@i = @secondToStart, @i > 0, @i--) {
		queue_push(closure(){
			@cc = import('cubeclimber');

			if(@i < 4) {
				set_objective_display('height', color('red').@i, 'cc');
				if(@i == 3) {
					_cc_generate();
				}
				play_sound(@region[1], array('sound': 'CLICK', 'volume': 2));
			} else {
				set_objective_display('height', color('green').@i, 'cc');
			}

			foreach(@p in all_players()) {
				if(array_contains(sk_current_regions(@p), 'cubeclimber')
				&& pworld(@p) == @world
				&& !array_index_exists(@cc['players'], @p)) {
					_cc_add_player(@p);
				}
			}

		}, 'cc');
		queue_delay(1000, 'cc');
	}

	queue_push(closure(){

		play_sound(@region[1], array('sound': 'ORB_PICKUP', 'volume': 2));
		set_objective_display('height', color(7).'['.color('gold').'Cube'.color('red').'Climber'.color(7).']', 'cc');

		foreach(@p in all_players()) {
			if(array_contains(sk_current_regions(@p), 'cubeclimber')
			&& pworld(@p) == @world) {
				_cc_spawn(@p);
				_cc_add_player(@p);
			}
		}

		@cc = import('cubeclimber');
		@cc['starttime'] = time();
		export('cubeclimber', @cc);

		bind(player_interact, array('id': 'cube-interact'), array('block': 159), @e) {
			@cc = import('cubeclimber');
			if(array_index_exists(@cc['players'], player())) {
				if((@e['block'] === '159:'.@cc['players'][player()]
				|| (@cc['players'][player()] == 0 && @e['block'] == 159))
				&& array_contains(sk_regions_at(@e['location']), 'cubeclimber_blocks')) {

					set_block_at(@e['location'], '0:0', false);
					play_sound(@e['location'], array('sound': 'CHICKEN_EGG_POP', 'pitch': 0.5));
					make_effect(@e['location'], 'smoke:4');

					for(@y = @e['location'][1] - 1, @y <= @e['location'][1] + 1, @y++) {
						for(@x = @e['location'][0] - 1, @x <= @e['location'][0] + 1, @x++) {
							for(@z = @e['location'][2] - 1, @z <= @e['location'][2] + 1, @z++) {
								if(split(':', get_block_at(@x, @y, @z, @e['location'][3]))[0] === '159') {
									set_block_at(@x, @y, @z, '172', @e['location'][3], false);
								}
							}
						}
					}

				}
			}
		}

		bind(player_teleport, array('id': 'cube-teleport'), null, @e) {
			@regions = sk_regions_at(array(@e['to'][0], @e['to'][1] - 1, @e['to'][2], @e['to'][3]));
			if(array_contains(@regions, 'cubeclimber_blocks')
			&& 2 < floor(sqrt(
			((@e['to'][0] - @e['from'][0]) ** 2) +
			((@e['to'][1] - @e['from'][1]) ** 2) +
			((@e['to'][2] - @e['from'][2]) ** 2)
			))) {
				cancel();
			}
		}

		@basenote = @region[0][1] - @region[1][1] - 23;
		@notes = array(0.5, 0.53, 0.56, 0.59, 0.62, 0.67, 0.7, 0.75, 0.8, 0.84, 0.9, 0.95, 1.0, 1.05, 1.12, 1.19, 1.26,
				1.34, 1.42, 1.5, 1.6, 1.68, 1.78, 1.88, 2.0);
		@winners = array();
		set_interval(200, closure(){
			@cc = import('cubeclimber');
			@playercount = 0;
			foreach(@p in all_players()) {

				if(pworld(@p) == @world) {
					@ploc = ploc(@p);
					@pregions = sk_regions_at(@ploc);

					if(!array_contains(@pregions, 'cubeclimber')) {
						continue();
					}

					@playercount++;

					if(!array_index_exists(@cc['players'], @p)) {
						_cc_add_player(@p);
						continue();
					}

					if(!entity_grounded(puuid(@p))) {
						if(phas_flight(@p)) {
							set_pflight(@p, false);
						}
						continue();
					}

					foreach(get_peffect(@p), @effect) {
						set_peffect(@p, @effect['id'], 0, 0);
					}

					@newheight = (@ploc[1] + 1) - @region[1][1];

					if(array_contains(@pregions, 'cubeclimber_blocks')) {

						if(split(':', get_block_at(@ploc))[0] === '159') {
							set_block_at(@ploc, '159:'.@cc['players'][@p], false);
						}

						@oldheight = get_pscore('height', @p, 'cc');
						if(@oldheight < @newheight) {

							if(@oldheight + 5 < @newheight) {
								_cc_spawn(@p);
								continue();
							}

							@newheight = integer(@newheight);
							set_pscore('height', @p, @newheight, 'cc');

							if(@newheight > @cc['highest']) {

								@cc['highest'] = @newheight;
							
								play_sound(@ploc, array(
									'sound': 'note_piano',
									'pitch': if(@newheight >= @basenote, @notes[@newheight - @basenote], 0.5),
									'volume': 2,
								));

								if(@ploc[1] >= @region[0][1]) {
									array_push(@winners, @p);
								}
							}
						}
					}
				}
			}
			if(@playercount < 1) {
				clear_task();
				_cc_reset();
			} else if(array_size(@winners) > 0) {
				clear_task();
				_cc_end(@winners);
			}
		});

	}, 'cc');

}

proc _cc_end(@winners, @world = 'custom') {
	@region = sk_region_info('cubeclimber_blocks', @world, 0);
	@height = @region[0][1] - @region[1][1] + 1;

	@cc = import('cubeclimber');
	@time = round((time() - @cc['starttime']) / 1000, 1);

	# REMOVE UNIMPORTANT PLAYERS
	foreach(@p in array_keys(@cc['players'])) {
		if(!ponline(@p)
		|| get_pscore('height', @p, 'cc') < 1) {
			array_remove(@cc['players'], @p);
		}
	}

	# PROCESS STATS
	@toptimes = get_value('cubeclimber', 'toptimes');
	if(!@toptimes) {
		@toptimes = array();
	}

	foreach(@p in array_keys(@cc['players'])) {
		@pstats = get_value('cubeclimber.player', @p);
		if(!@pstats) {
			@pstats = array(0, 0, 0, 0);
		}

		# games won
		if(get_pscore('height', @p, 'cc') == @height) {
			@pstats[0] += 1;
		}

		# games played
		@pstats[1] += 1;

		# blocks climbed
		@pstats[2] += get_pscore('height', @p, 'cc');

		# opponents played
		@pstats[3] += array_size(@cc['players']) - 1;

		# best time

		if(array_contains(@winners, @p)) {
			if(!array_index_exists(@pstats, 4) || @time < @pstats[4]) {
				if(array_index_exists(@pstats, 4)) {
					tmsg(@p, color('gold').'You beat your best time of '.@pstats[4].' with a time of '.color('bold').@time);
				}
				@pstats[4] = @time;

				@top = false;
				for(@i = 0, @i < 10, @i++) {
					if(!@top) {
						if(!array_index_exists(@toptimes, @i) || @time < @toptimes[@i][1]) {
							array_insert(@toptimes, array(@p, @time), @i);
							@top = true;
						}
					} else {
						if(array_index_exists(@toptimes, @i) && @toptimes[@i][0] == @p) {
							array_remove(@toptimes, @i);
						}
					}
				}

				if(@top) {
					tmsg(@p, color('yellow').color('bold').'TOP TEN TIME!');
					if(array_size(@toptimes) > 10) {
						array_remove(@toptimes, 10);
					}
				}
			}
		}

		store_value('cubeclimber.player', @p, @pstats);

	}

	store_value('cubeclimber', 'toptimes', @toptimes);

	# ORDER SCORES
	@scores = array();
	array_resize(@scores, @height + 1, '');
	foreach(@p in array_keys(@cc['players'])) {
		@scores[get_pscore('height', @p, 'cc')] .= ' '.@p;
	}

	# DISPLAY SCORES
	foreach(@p in array_keys(@cc['players'])) {
		@count = 0;
		for(@i = @height, @i > 0, @i--) {
			if(@scores[@i] !== '') {
				tmsg(@p, color('gold').if(@i == @height, color('red')).color('bold').'['.@i.']'.color('r').@scores[@i]);
				@count++;
				if(@count >= 16) {
					break();
				}
			}
		}
	}

	# REWARD WINNERS
	foreach(@p in @winners) {
		_cc_reward(@p);
	}

	foreach(@x in 0..1) {
		foreach(@y in 0..1) {
			foreach(@z in 0..1) {
				queue_push(closure(){
					launch_firework(
						array(
							@region[@x][0] + if(@y, if(@x, -1, 1), 0) + 0.5,
							@region[@y][1] + 1,
							@region[@z][2] + if(@y, if(@z, -1, 1), 0) + 0.5,
							@world
						),
						array(
							'strength': @y,
							'flicker': true,
							'trail': true,
							'colors': array(array(rand(256), rand(256), rand(256))),
							'fade': array(array(rand(256), rand(256), rand(256))),
							'type': 'BALL_LARGE',
						)
					);
				}, 'cc_fireworks');
				queue_delay(500, 'cc_fireworks');
			}
		}
	}

	_cc_reset();
}

proc _cc_reset(){
	unbind('cube-interact');
	unbind('cube-teleport');
	export('cubeclimber', null);
	export('currently', null);
	remove_scoreboard('cc');
	_remove_activity('cubeclimber');
}
