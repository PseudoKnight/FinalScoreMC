@startworld = pworld()

proc('_cc_reward', @player,
	@cc = import('cubeclimber')
	@amount = array_size(@cc['players'])
	_acc_add(@player, @amount)
	tmsg(@player, color('gold').'+'.@amount.' coin'.if(@amount > 1, 's'))
	set_peffect(@player, 8, 9, 30)
)

proc('_cc_generate', @world = @startworld,

	@rg = sk_region_info('cubeclimber_blocks', @world, 0)
	@delay = integer(3000 / (@rg[0][1] - @rg[1][1]))
	@density = rand(4,7)
	
	for(@y = min(@rg[0][1], @rg[1][1]), @y <= max(@rg[0][1], @rg[1][1]), @y++,
		queue_push(closure(
			for(@x = min(@rg[0][0], @rg[1][0]), @x <= max(@rg[0][0], @rg[1][0]), @x++,
				for(@z = min(@rg[0][2], @rg[1][2]), @z <= max(@rg[0][2], @rg[1][2]), @z++,
					if(!rand(@density)) {
						set_block_at(@x, @y, @z, '159:'.rand(16), @world)
					} else {
						set_block_at(@x, @y, @z, '0:0', @world)
					}
				)
			)
		), 'cc_gen')
		queue_delay(@delay, 'cc_gen')
	)
	
)

proc('_cc_spawn', @player, @world = @startworld,
	@region = sk_region_info('cubeclimber_blocks', @world, 0)
	@rx = rand(2)
	@rz = rand(2)
	@y = @region[1][1] - 1
	
	set_ploc(@player, array(
		@region[@rx][0] + if(@rx, -1, 1) + 0.5, 
		@y, 
		@region[@rz][2] + if(@rz, -1, 1) + 0.5,
		@world
	))
	
	if(@rx && @rz) {
		pfacing(@player, -45, 0)
	} else if(@rx && !@rz) {
		pfacing(@player, -135, 0)		
	} else if(!@rx && @rz) {
		pfacing(@player, 45, 0)		
	} else {
		pfacing(@player, 135, 0)		
	}
	
	set_pscore('height', @player, 0, 'cc')
)

proc('_cc_add_player', @player, @world = @startworld,
	@cc = import('cubeclimber')
	@cc['players'][@player] = rand(16)
	set_pscoreboard(@player, 'cc')
	set_pscore('height', @player, -1, 'cc')
	export('cubeclimber', @cc)
)

proc('_cc_start', @world = @startworld,

	@region = sk_region_info('cubeclimber_blocks', @world, 0)

	foreach(all_players(@world), @p) {
		tmsg(@p, color(7).'['.color('gold').'Cube'.color('red').'Climber'.color(7).'] '
			.color('r').'Starting in 30 seconds...')
	}
	
	for(@i = 30, @i > 0, @i--, 
		queue_push(closure(
			@cc = import('cubeclimber')
		
			if(@i < 4) {
				set_objective_display('height', color('red').@i, 'cc')
				if(@i == 3) {
					_cc_generate()
				}
				play_sound(@region[1], array('sound': 'CLICK', 'volume': 2))
			} else {
				set_objective_display('height', color('green').@i, 'cc')
			}
			
			foreach(all_players(@world), @p) {
				if(array_contains(sk_current_regions(@p), 'cubeclimber')
				&& !array_index_exists(@cc['players'], @p)) {
					_cc_add_player(@p)
				}
			}
			
		), 'cc')
		queue_delay(1000, 'cc')
	)
	
	queue_push(closure(
	
		@cc = import('cubeclimber')

		play_sound(@region[1], array('sound': 'ORB_PICKUP', 'volume': 2))
		set_objective_display('height', color(7).'['.color('gold').'Cube'.color('red').'Climber'.color(7).']', 'cc')

		foreach(all_players(@world), @p) {
			if(array_contains(sk_current_regions(@p), 'cubeclimber')) {
				_cc_spawn(@p)
				_cc_add_player(@p)
			}
		}
		
		bind('player_interact', array('id': 'cube-interact'), array('button': 'left', 'block': 159), @e,
			if(@e['action'] == 'left_click_block') {
				@cc = import('cubeclimber')
				if(array_index_exists(@cc['players'], player())) {
					if((@e['block'] == '159:'.@cc['players'][player()]
					|| (@cc['players'][player()] == 0 && @e['block'] == 159))
					&& array_contains(sk_regions_at(@e['location']), 'cubeclimber_blocks')) {
					
						set_block_at(@e['location'], '0:0')
						play_sound(@e['location'], array('sound': 'CHICKEN_EGG_POP', 'pitch': 0.5))
						make_effect(@e['location'], 'smoke:4')
						
						for(@y = @e['location'][1] - 1, @y <= @e['location'][1] + 1, @y++,
							for(@x = @e['location'][0] - 1, @x <= @e['location'][0] + 1, @x++,
								for(@z = @e['location'][2] - 1, @z <= @e['location'][2] + 1, @z++,
									if(split(':', get_block_at(@x, @y, @z, @e['location'][3]))[0] == '159') {
										set_block_at(@x, @y, @z, '172', @e['location'][3])
									}
								)
							)
						)
						
					}
				}
			}
		)
		
		bind('player_teleport', array('id': 'cube-teleport'), null, @e,
			if(array_contains(sk_regions_at(@e['to']), 'cubeclimber')
			&& floor(sqrt(((@e['to'][0] - @e['from'][0]) ** 2) + ((@e['to'][1] - @e['from'][1]) ** 2) + ((@e['to'][2] - @e['from'][2]) ** 2))) > 2) {
				cancel()
			}
		)

				
		@basenote = @region[0][1] - @region[1][1] - 23
		@notes = array(0.5, 0.53, 0.56, 0.59, 0.62, 0.67, 0.7, 0.75, 0.8, 0.84, 0.9, 0.95, 1.0, 1.05, 1.12, 1.19, 1.26, 1.34, 1.42, 1.5, 1.6, 1.68, 1.78, 1.88, 2.0)
		@winners = array()
		@cc['interval'] = set_interval(250, closure(
			@cc = import('cubeclimber')
			@playercount = 0
			foreach(all_players(@world), @p) {
			
				if(ponline(@p)) {
					@ploc = ploc(@p)
					@pregions = sk_regions_at(@ploc)
					
					if(!array_contains(@pregions, 'cubeclimber')) {
						continue()
					}
					
					@playercount++
				
					if(!array_index_exists(@cc['players'], @p)) {
						_cc_add_player(@p)
						continue()
					}
					
					if(!entity_grounded(pinfo(@p, 13))) {
						continue()
					}

					@newheight = (@ploc[1] + 1) - @region[1][1]
					
					if(array_contains(@pregions, 'cubeclimber_blocks')) {
					
						if(split(':', get_block_at(@ploc))[0] == '159') {
							set_block_at(@ploc, '159:'.@cc['players'][@p])
						}
						
						@oldheight = get_pscore('height', @p, 'cc')
						if(@oldheight < @newheight) {
						
							@newheight = round(@newheight)
							set_pscore('height', @p, @newheight, 'cc')
							
							if(@newheight > @cc['highest']) {
							
								@cc['highest'] = @newheight
							
								play_sound(@ploc, array(
									'sound': 'note_piano',
									'pitch': if(@newheight >= @basenote, @notes[@newheight - @basenote], 0.5),
									'volume': 2,
								))
								
								if(@ploc[1] >= @region[0][1]) {
									array_push(@winners, @p)
								}
							}
						}
					}
				}
			}
			if(@playercount < 1 || array_size(@winners) > 0) {
				_cc_end(@winners)
			}
		))
		
		export('cubeclimber', @cc)
		
	), 'cc')
	
)

proc('_cc_end', @winners, @world = @startworld,
	@region = sk_region_info('cubeclimber_blocks', @world, 0)

	@cc = import('cubeclimber')

	foreach(array_keys(@cc['players']), @p1) {
	
		foreach(array_keys(@cc['players']), @p2) {
			tmsg(@p2, color('yellow').if(array_contains(@winners, @p1), color('red').color('bold')).'['.@p1.'] '
			.color('r').get_pscore('height', @p1, 'cc'))
		}
		
		set_pscoreboard(@p1)
		
	}
	
	foreach(@winners, @p) {
	
		_cc_reward(@p)
		
	}
	
	if(@winners) {
		foreach(0..1, @x) {
			foreach(0..1, @y) {
				foreach(0..1, @z) {
					queue_push(closure(
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
						)
					), 'cc_fireworks')
					queue_delay(500, 'cc_fireworks')
				}
			}
		}
	}
	
	clear_task(@cc['interval'])
	unbind('cube-interact')
	unbind('cube-teleport')
	export('cubeclimber', null)
	remove_scoreboard('cc')
	
)