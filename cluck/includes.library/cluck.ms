proc('_cluck_defaults') {
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
		'gameover': array(-563, 55, -323), 
		'winround': array(-563, 58, -323), 
		'startround': array(-563, 52, -323)
	),
	'color': array('yellow', 'gold'),
	'spawnloc': array(
		array(-575.5, 63, -336), 
		array(-575.5, 63, -323)
	)
	))
}

proc('_cluck_startround') {
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
	
	bind('entity_damage', array('id': 'cluckchicken'), array('cause': 'PROJECTILE', 'type': 'CHICKEN', 'world': 'custom'), @event) {
		@cluck = import('cluck')
		if(array_contains(@cluck['chickens'][0], @event['id'])) {
			if(@event['shooter'] != @cluck['player'][0]) {
				cancel()
			} else {
				@cluck['score'][0] += 1
				@cluck['hit'][0] += 1
				set_plevel(@cluck['score'][0])
				array_remove_values(@cluck['chickens'][0], @event['id'])
			}
		} else if(array_contains(@cluck['chickens'][1], @event['id'])) {
			if(@event['shooter'] != @cluck['player'][1]) {
				cancel()
			} else {
				@cluck['score'][1] += 1
				@cluck['hit'][1] += 1
				set_plevel(@cluck['score'][1])
				array_remove_values(@cluck['chickens'][1], @event['id'])
			}
		}
	}

	set_block_at(@cluck['sound']['startround'], '69:13')
	set_timeout(50, closure(set_block_at(@cluck['sound']['startround'], '69:5')))
	
	export('cluck', @cluck)
	_cluck_spawn()
}

proc('_cluck_spawn') {
	@cluck = import('cluck')
	queue_delay(1000, 'cluck')
	for(@i = @cluck['count'], @i > 0, @i--) {
		queue_delay(400 * rand(1, 9), 'cluck')
		queue_push(closure(){
			@offset =  rand(10)
			foreach(@i in array(0, 1)) {
				if(!@cluck['player'][@i] || @cluck['gameover'][@i]) {
					continue()
				}
				if(ponline(@cluck['player'][@i]) && array_contains(sk_current_regions(@cluck['player'][@i]), 'cluck'.@i)) {
					# Let's check if some other player is where they shouldn't be
					foreach(@player in all_players('custom')) {
						if(array_contains(sk_current_regions(@player), 'cluckdeny')
						&& !array_contains(@cluck['player'], @player)) {
							@loc = get_spawn()
							@loc = array(@loc[0] + 0.5, @loc[1] - 1, @loc[2] + 0.5, @loc[3])
							set_ploc(@player, @loc)
							tmsg(@player, 'Don\'t get in player\'s way.')
							tmsg(@player, color('gold').'-1 Coin')
							_acc_subtract(@player, 1)
							if(@cluck['player'][0]) {
								_acc_add(@cluck['player'][0], 1)
							}
							if(@cluck['player'][1]) {
								_acc_add(@cluck['player'][1], 1)
							}
						}
					}
					# spawn ALL the chickens!
					@loc = array(@cluck['spawnloc'][@i][0], @cluck['spawnloc'][@i][1], @cluck['spawnloc'][@i][2] + @offset, 'custom')
					@entityid = spawn_mob('chicken', 1, @loc)[0]
					if(rand(10) < 1) {
						set_mob_age(@entityid, -24000)
						play_sound(@loc, array('sound': 'CHICKEN_EGG_POP', 'pitch': 2))
					} else {
						play_sound(@loc, array('sound': 'CHICKEN_EGG_POP'))
					}
					set_entity_velocity(@entityid, array(0, 1.1, (rand(100) - (12.5 * @offset)) * (@cluck['round'] / 1000)))
					set_entity_health(@entityid, 25)
					array_push(@cluck['chickens'][@i], @entityid)
				} else {
					if(ponline(@cluck['player'][@i]) && pworld(@cluck['player'][@i]) == 'custom') {
						_clear_pinv(@cluck['player'][@i])
						set_plevel(@cluck['player'][@i], 0)
						tmsg(@cluck['player'][@i], 'You must stand on the shooting pad.')
					}
					@cluck['gameover'][@i] = @cluck['round']
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

proc('_cluck_endround') {
	@cluck = import('cluck')
	foreach(@chicken in array_merge(@cluck['chickens'][0], @cluck['chickens'][1])) {
		if(entity_exists(@chicken)) {
			entity_remove(@chicken)
		}
	}
	foreach(@i in array(0, 1)) {
		if(!@cluck['player'][@i] || (@cluck['gameover'][@i] && @cluck['gameover'][@i] < @cluck['round'])) {
			continue()
		}
		
		_regionmsg('cluck', color(@cluck['color'][@i]).@cluck['player'][@i].' hit '.@cluck['hit'][@i].' chickens.')
		_clear_pinv(@cluck['player'][@i])

		# Did we not meet the required hit chickens? (or round 10)
		if(@cluck['hit'][@i] < floor((@cluck['round'] * 0.5) + 5) || @cluck['round'] == 10) {
			_regionmsg('cluck', color(@cluck['color'][@i]).color('l').to_upper(@cluck['player'][@i]).' GAMEOVER! Score: '.@cluck['score'][@i])

			# STATS
			#-------
			@scores = get_value('cluck')
			if(!array_index_exists(@scores, @cluck['player'][@i]), @best = 0, @best = @scores[@cluck['player'][@i]])
			if(@cluck['score'][@i] > @best) {
				if(@best > 0, _regionmsg('cluck', color('l').'You beat your personal best of '.@best.'!'))
				msg(color(6).'+ '.(@cluck['score'][@i] - @best).' coins')
				_acc_add(@cluck['player'][@i], @cluck['score'][@i] - @best)
				@scores[@cluck['player'][@i]] = @cluck['score'][@i]
				@top = false
				for(@i = 0, @i < 10, @i++) {
					if(@top && array_index_exists(@scores['top'], @i) && @scores['top'][@i]['name'] == @cluck['player'][@i]) {
						array_remove(@scores['top'], @i)
					} else if(!@top && (!array_index_exists(@scores['top'], @i) || @scores['top'][@i]['score'][0] < @cluck['score'][@i])) {
						_regionmsg('cluck', color('l').'Top 10 Score!')
						array_insert(@scores['top'], array('name': @cluck['player'][@i], 'score': @cluck['score'][@i]), @i)
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
			set_timeout(50, closure(set_block_at(@cluck['sound']['gameover'], '69:5')))
		} else {
			set_block_at(@cluck['sound']['winround'], '69:13')
			set_timeout(50, closure(set_block_at(@cluck['sound']['winround'], '69:5')))
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