include('util.ms')
@pworld = pworld()

proc _spl_queue_start(@id, @world = @pworld) {
	@arena = get_value('spleef', @id)

	if(!sk_region_exists(@world, 'spl_'.@id.'_floor')) {
		die('Spleef floor region does not exist.')
	}
	
	if(!array_index_exists(@arena, 'lobby')) {
		die('Spleef lobby teleport point does not exist.')
	}

	@spl = import('spleef.'.@id)
	@spl['state'] = 1
	export('spleef.'.@id, @spl)
	
	if(!array_index_exists(@arena, 'countdown')) {
		@arena['countdown'] = 30
	}
	
	# ARENA GENERATION
	if(array_index_exists(@arena, 'floorblocks')) {
		@floorblock = @arena['floorblocks'][rand(array_size(@arena['floorblocks']))]
	} else {
		@floorblock = data_values('quartz_block')
	}
	
	@rg = sk_region_info('spl_'.@id.'_floor', @world, 0)
	@width = @rg[0][0] - @rg[1][0]
	@delay = ceil((((@arena['countdown'] - 5) / 2) * 1000) / @width)
	@y = @rg[1][1]
	
	for(@x = @rg[1][0], @x <= @rg[0][0], @x++) {
		queue_push(closure(){
			for(@z = @rg[1][2], @z <= @rg[0][2], @z++) {
				set_block_at(@x, @y, @z, @floorblock, @world)
			}
		}, 'spl_'.@id)
		if(@delay > 10) {
			queue_delay(@delay, 'spl_'.@id)
		}
	}
	
	# COUNTDOWN	
	for(@i = 5, @i > 0, @i--) {
		queue_push(closure(){
			play_sound(@arena['lobby'], array('sound': 'CLICK', 'volume': 3))
		}, 'spl_'.@id)
		queue_delay(1000, 'spl_'.@id)
	}

	# START
	queue_push(closure(
	
		@spl = import('spleef.'.@id)
		
		foreach(@i: @player in @spl['nextplayers']) {
			if(!ponline(@player) || !array_contains(sk_current_regions(@player), 'spl_'.@id)) {
				array_remove(@spl['nextplayers'], @i)
			}
		}
		
		if(array_size(@spl['nextplayers']) < 2) {
			play_sound(@arena['lobby'], array('sound': 'VILLAGER_NO', 'volume': 3))
			die()
		}
		
		@spl['players'] = @spl['nextplayers']
		@spl['nextplayers'] = array()
		@spl['state'] = 2
		@limit = 100
		@floorblock = split(':', @floorblock)
		if(array_size(@floorblock) == 1) {
			@floorblock[1] = 0
		}
		@tool = _spl_get_tool(@floorblock)
		
		foreach(@player in @spl['players']) {
			if(@limit == 0) {
				console('Spleef hit teleport attempt limit!')
				break()
			} else {
				@limit--
			}
			@loc = array(rand(@rg[1][0], @rg[0][0]) + 0.5, @y, rand(@rg[1][2], @rg[0][2]) + 0.5, @world)
			if(get_block_at(@loc)[0] == '0'
			|| get_block_at(@loc[0], @loc[1] + 1, @loc[2], @loc[3])[0] != '0') {
				continue(0)
			}
			set_ploc(@player, @loc)
			_spl_clear_pinv(@player)
			set_pinv(@player, array(0: @tool))
		}
		console('Debug: spleef checked '.@limit.' locations for '.array_size(@spl['players']).' players.')
		
		if(array_index_exists(@arena, 'drops')) {
			bind(block_break, array('id': 'block_break_spl_'.@id), array('type': @floorblock[0], 'data': @floorblock[1]), @e, @arenaid = @id) {
				if(array_contains(sk_regions_at(@e['location']), 'spl_'.@arenaid.'_floor')) {
					modify_event('drops', array())
					modify_event('xp', 0)
				}
			}
		}
		
		play_sound(@arena['lobby'], array('sound': 'FIREWORK_BLAST', 'volume': 3))
			
		set_interval(250, closure(){
			@spl = import('spleef.'.@id)
			
			foreach(@i: @player in @spl['players']) {
				if(!ponline(@player)) {
					array_remove(@spl['players'], @i)
				} else if(!array_contains(sk_current_regions(@player), 'spl_'.@id.'_arena')) {
					set_ploc(@player, @arena['lobby'])
					_spl_clear_pinv(@player)
					array_remove(@spl['players'], @i)
				}
			}
			
			export('spleef.'.@id, @spl)
			
			if(array_size(@spl['players']) <= 1) {
				clear_task()
				_spl_end(@id)
			}
		})
		
		export('spleef.'.@id, @spl)
		
	), 'spl_'.@id)

}

proc _spl_end(@id, @world = @pworld) {
	@spl = import('spleef.'.@id)
	if(array_size(@spl['players']) < 1) {
		foreach(@player in all_players(@world)) {
			if(!ponline(@player), continue())
			tmsg(@player, color('gray').'[Spleef] '.color('r').'Nobody wins! ... ?')
		}
	} else {
		@winner = @spl['players'][0]
		foreach(@player in all_players(@world)) {
			if(!ponline(@player), continue())
			tmsg(@player, color('gray').'[Spleef] '.color('r').@winner.' wins!')
		}
		_spl_reward(@winner)
		set_timeout(3000, closure(
			@arena = get_value('spleef', @id)
			if(ponline(@winner)
			&& pworld(@winner) == @world) {
				set_ploc(@winner, @arena['lobby'])
				_spl_clear_pinv(@winner)
			}
		))
	}
	
	if(has_bind('block_break_spl_'.@id)) {
		unbind('block_break_spl_'.@id)
	}
	
	@spl['players'] = array()
	@spl['state'] = 0
	export('spleef.'.@id, @spl)
}
