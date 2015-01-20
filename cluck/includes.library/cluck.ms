proc _cluck_defaults() {
	return(array(
	'round': 1, 
	'count': 10, # of chicken spawns
	'chickens': array(array(), array()), # chicken entity ids to check if they're alive at round end
	'hit': array(0, 0), # num chickens hit
	'player': array('', ''),
	'gameover': array(0, 0),
	'active': 0, # if round is in progress
	'score': array(0, 0), # cumulative hit chickens 
	'sound': array(
		'gameover': array(-563, 55, -323, 'custom'), 
		'winround': array(-563, 58, -323, 'custom'), 
		'startround': array(-563, 52, -323, 'custom')
	),
	'color': array('yellow', 'gold'),
	'spawnloc': array(
		array(-575.5, 63, -336, 'custom'), 
		array(-575.5, 63, -323, 'custom')
	)
	))
}

proc _cluck_startround() {
    @cluck = import('cluck')
	_regionmsg('cluck', 'Round '.@cluck['round'])
	if(@cluck['player'][0] && !@cluck['gameover'][0]) {
		_clear_pinv(@cluck['player'][0])
		set_pinv(@cluck['player'][0], array(0: array('type': 261), 1: array('type': 262, 'qty': 10)))
	}
	if(@cluck['player'][1] && !@cluck['gameover'][1]) {
		_clear_pinv(@cluck['player'][1])
		set_pinv(@cluck['player'][1], array(0: array('type': 261), 1: array('type': 262, 'qty': 10)))
	}
	
	bind(entity_damage, array('id': 'cluckchicken'), array('cause': 'PROJECTILE', 'type': 'CHICKEN', 'world': 'custom'), @event) {
		@cluck = import('cluck')
		if(array_contains(@cluck['chickens'][0], @event['id'])) {
			if(@event['shooter'] != @cluck['player'][0]) {
				cancel()
			} else {
				@cluck['score'][0] += 1
				@cluck['hit'][0] += 1
				set_plevel(@event['shooter'], @cluck['score'][0])
				array_remove_values(@cluck['chickens'][0], @event['id'])
			}
		} else if(array_contains(@cluck['chickens'][1], @event['id'])) {
			if(@event['shooter'] != @cluck['player'][1]) {
				cancel()
			} else {
				@cluck['score'][1] += 1
				@cluck['hit'][1] += 1
				set_plevel(@event['shooter'], @cluck['score'][1])
				array_remove_values(@cluck['chickens'][1], @event['id'])
			}
		}
	}

	set_block_at(@cluck['sound']['startround'], '69:13')
	queue_push(closure(){
		set_block_at(@cluck['sound']['startround'], '69:5')
	})
	
	export('cluck', @cluck)
	_cluck_spawn()
}

proc _cluck_spawn() {
	@cluck = import('cluck')
	queue_delay(1000, 'cluck')
	for(@i = @cluck['count'], @i > 0, @i--) {
		queue_delay(400 * rand(1, 12 - @cluck['round']), 'cluck')
		queue_push(closure(){
			# Let's check if some player is in the way
			foreach(@player in all_players('custom')) {
				if(!ponline(@player), continue())
				if(array_contains(sk_current_regions(@player), 'cluckdeny')
				&& !array_contains(@cluck['player'], @player)) {
					@loc = get_spawn()
					@loc = array(@loc[0] + 0.5, @loc[1] - 1, @loc[2] + 0.5, @loc[3])
					set_ploc(@player, @loc)
					tmsg(@player, 'Don\'t get in player\'s way.')
				}
			}
			
			# Mirror chicken spawns for duel mode
			@offset =  rand(10)
			@adult = rand(10)
			@angle = rand(100)
			foreach(@p in array(0, 1)) {
				if(!@cluck['player'][@p] || @cluck['gameover'][@p]) {
					continue()
				}
				
				if(ponline(@cluck['player'][@p]) && array_contains(sk_current_regions(@cluck['player'][@p]), 'cluck'.@p)) {
					@loc = array(@cluck['spawnloc'][@p][0], @cluck['spawnloc'][@p][1], @cluck['spawnloc'][@p][2] + @offset, 'custom')
					@entityid = spawn_mob('chicken', 1, @loc)[0]
					if(@adult) {
						play_sound(@loc, array('sound': 'CHICKEN_EGG_POP'))
					} else {
						set_mob_age(@entityid, -24000)
						play_sound(@loc, array('sound': 'CHICKEN_EGG_POP', 'pitch': 2))
					}
					set_entity_velocity(@entityid, array(0, 1.1, (@angle - (12.5 * @offset)) * (@cluck['round'] / 1000)))
					set_entity_health(@entityid, 25)
					@cluck['chickens'][@p][] = @entityid
					
				} else { # they stepped off the shooting range
					if(ponline(@cluck['player'][@p]) && pworld(@cluck['player'][@p]) == 'custom') {
						_clear_pinv(@cluck['player'][@p])
						set_plevel(@cluck['player'][@p], 0)
						tmsg(@cluck['player'][@p], 'You must stand on the shooting pad.')
					}
					@cluck['gameover'][@p] = @cluck['round']
					if((!@cluck['player'][0] || @cluck['gameover'][0])
					&& (!@cluck['player'][1] || @cluck['gameover'][1])) {
						queue_clear('cluck')
						_cluck_endround()
					}
				}
			}
		}, 'cluck')
	}
	queue_delay(5000, 'cluck')
	queue_push(closure(){
		_cluck_endround()
	}, 'cluck')
}

proc _cluck_endround() {
	@cluck = import('cluck')
	try(foreach(@chicken in array_merge(@cluck['chickens'][0], @cluck['chickens'][1])) {
		if(entity_exists(@chicken)) {
			entity_remove(@chicken)
		}
	}, return())
	foreach(@p in array(0, 1)) {
		if(!@cluck['player'][@p] || (@cluck['gameover'][@p] && @cluck['gameover'][@p] < @cluck['round'])) {
			continue()
		}
		
		_regionmsg('cluck', color(@cluck['color'][@p]).@cluck['player'][@p].' hit '.@cluck['hit'][@p].' chickens.')
		_clear_pinv(@cluck['player'][@p])

		# Did we not meet the required hit chickens? (or round 10)
		if(@cluck['hit'][@p] < @cluck['count'] / 2 || @cluck['round'] == 10) {
			_regionmsg('cluck', color(@cluck['color'][@p]).color('l').to_upper(@cluck['player'][@p]).' GAMEOVER! Score: '.@cluck['score'][@p])
			@cluck['gameover'][@p] = @cluck['round']

			# STATS
			#-------
			@scores = get_value('cluck')
			if(!array_index_exists(@scores, @cluck['player'][@p]), @best = 0, @best = @scores[@cluck['player'][@p]])
			if(@cluck['score'][@p] > @best) {
				if(@best > 0, _regionmsg('cluck', color('l').'You beat your personal best of '.@best.'!'))
				msg(color(6).'+ '.(@cluck['score'][@p] - @best).' coins')
				_acc_add(@cluck['player'][@p], @cluck['score'][@p] - @best)
				@scores[@cluck['player'][@p]] = @cluck['score'][@p]
				@top = false
				for(@i = 0, @i < 10, @i++) {
					if(@top && array_index_exists(@scores['top'], @i) && @scores['top'][@i]['name'] == @cluck['player'][@p]) {
						array_remove(@scores['top'], @i)
					} else if(!@top && (!array_index_exists(@scores['top'], @i) || @scores['top'][@i]['score'] < @cluck['score'][@p])) {
						_regionmsg('cluck', color('l').'Top 10 Score!')
						array_insert(@scores['top'], array('name': @cluck['player'][@p], 'score': @cluck['score'][@p]), @i)
						@top = true
					}
				}
				if(array_size(@scores['top']) > 10) {
					array_remove(@scores['top'], 10)
				}
				store_value('cluck', @scores)
			}
			#-------

			set_block_at(@cluck['sound']['gameover'], '69:13')
			queue_push(closure(){
				set_block_at(@cluck['sound']['gameover'], '69:5')
			})
			
		} else {
			set_block_at(@cluck['sound']['winround'], '69:13')
			queue_push(closure(){
				set_block_at(@cluck['sound']['winround'], '69:5')
			})
		}
	}

	_remove_region_entities('cluck', array('DROPPED_ITEMS', 'EXPERIENCE_ORB', 'CHICKEN'))
	# Reset for the next round.
	if(((!@cluck['player'][0] || @cluck['gameover'][0])
	&& (!@cluck['player'][1] || @cluck['gameover'][1]))
	|| @cluck['round'] == 10) {
		@cluck = _cluck_defaults()
	} else {
		@cluck['round'] += 1
		@cluck['chickens'] = array(array(), array())
		@cluck['hit'] = array(0, 0)
		@cluck['active'] = 0
	}
	unbind('cluckchicken')
	export('cluck', @cluck)
}