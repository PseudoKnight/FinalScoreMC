proc('_cluck_defaults') {
	return(array(
	'round': 1, 
	'count': 10, # countdown for chicken spawns
	'chickens': array(), # chicken entity ids to check if they're alive at round end
	'hit': 0, # num chickens hit
	'player': '',
	'active': 0, # if round is in progress
	'score': 0, # cumulative hit chickens 
	'sound': array(
		'gameover': array(-563, 55, -323), 
		'winround': array(-563, 58, -323), 
		'startround': array(-563, 52, -323)
	),
	'color': array('yellow', 'gold'),
	'spawnloc': array(
		array(-575.5, 63, -335), 
		array(-575.5, 63, -323)
	)
	))
}

proc('_cluck_startround') {
    @cluck = import('cluck')
	_regionmsg('cluck', 'Round '.@cluck['round'])
	_clear_pinv()
	set_pinv(@cluck['player'], array(0: array('type': 261), 1: array('type': 262, 'qty': 10)))
	set_block_at(@cluck['sound']['startround'], '69:13')
	bind('entity_damage', array('id': 'cluckchicken'), array('cause': 'PROJECTILE', 'type': 'CHICKEN', 'world': 'custom'), @event) {
		@cluck = import('cluck')
		if(@event['shooter'] != @cluck['player']) {
			@cluck['count']++
			array_remove_values(@cluck['chickens'], @event['id'])
			export('cluck', @cluck)
		} else if(array_contains(@cluck['chickens'], @event['id'])) {
			@cluck['score'] = @cluck['score'] + 1
			@cluck['hit']++
			set_plevel(@cluck['score'])
			array_remove_values(@cluck['chickens'], @event['id'])
			export('cluck', @cluck)
		}
	}

	set_timeout(100, closure(set_block_at(@cluck['sound']['startround'], '69:5')))
	export('cluck', @cluck)
	set_timeout(1000, closure(){
		_cluck_spawn()
	})
}

proc('_cluck_spawn') {
	queue_delay(400 * rand(1, 9), 'cluck')
	queue_push(closure(){
		@cluck = import('cluck')
		# Let's make sure the player isn't cheating, but we'll just reset the round
		if(ponline(@cluck['player']) && array_contains(sk_current_regions(@cluck['player']), 'cluck0')) {
			# Let's check if some other player is where they shouldn't be
			foreach(@player in all_players('custom')) {
				if(array_contains(sk_current_regions(@player), 'cluckdeny0')) {
					set_ploc(@player, array(-544,62, -367, 'custom'))
					tmsg(@player, 'Don\'t get in player\'s way.')
				}
			}
			# spawn ALL the chickens!
			if(@cluck['count'] > 0) {
				@loc = array(@cluck['spawnloc'][0][0], @cluck['spawnloc'][0][1], @cluck['spawnloc'][0][2] + rand(9), 'custom')
				@entityid = spawn_mob('chicken', 1, @loc)[0]
				if(rand(10) < 1) {
					set_mob_age(@entityid, -24000)
					play_sound(@loc, array('sound': 'CHICKEN_EGG_POP', 'pitch': 2))
				} else {
					play_sound(@loc, array('sound': 'CHICKEN_EGG_POP'))
				}
				set_entity_velocity(@entityid, array(0, 1.1, (rand(100) - (12.5 * abs(@cluck['spawnloc'][0][2] - @loc[2]))) * (@cluck['round'] / 1000)))
				set_entity_health(@entityid, 25)
				array_push(@cluck['chickens'], @entityid)
				@cluck['count'] = @cluck['count'] - 1
				export('cluck', @cluck)
				_cluck_spawn()
			} else {
				export('cluck', @cluck)
				set_timeout(5000, closure(){
					_cluck_endround()
				})
			}
		} else {
			if(ponline(@cluck['player']) && pworld(@cluck['player']) == 'custom') {
				_clear_pinv()
				set_plevel(@cluck['player'], 0)
			}
			unbind('cluckchicken')
			foreach(@chicken in @cluck['chickens']) {
				if(entity_type(@chicken), try(entity_remove(@chicken)))
			}
			@cluck = _cluck_defaults()
			export('cluck', @cluck)
			queue_clear('cluck')
			msg('You stepped off the shooting pad. Cluck is reset.')
		}
	}, 'cluck')
}

proc('_cluck_endround') {
	@cluck = import('cluck')
	if(@cluck['count'] > 0, return())
	foreach(@chicken in @cluck['chickens']) {
		if(entity_type(@chicken), entity_remove(@chicken))
	}
	_regionmsg('cluck', color(@cluck['color'][0]).@cluck['player'].' hit '.@cluck['hit'].' chickens.')

	# Did we not meet the required hit chickens? (or round 10)
	if(@cluck['hit'] < floor((@cluck['round'] * 0.5) + 5) || @cluck['round'] == 10) {
		_regionmsg('cluck', color('l').'GAMEOVER! Score: '.@cluck['score'])

		# STATS
		#-------
		@scores = get_value('cluck')
		if(!array_index_exists(@scores, player()), @best = 0, @best = @scores[player()])
		if(@cluck['score'] > @best) {
			if(@best > 0, _regionmsg('cluck', color('l').'You beat your personal best of '.@best.'!'))
			msg(color(6).'+ '.(@cluck['score'] - @best).' coins')
			_acc_add(player(), @cluck['score'] - @best)
			@scores[player()] = @cluck['score']
			@top = false
			for(@i = 0, @i < 10, @i++) {
				if(@top && array_index_exists(@scores['top'], @i) && @scores['top'][@i]['name'] == player()) {
					array_remove(@scores['top'], @i)
				} else if(!@top && (!array_index_exists(@scores['top'], @i) || @scores['top'][@i]['score'] < @cluck['score'])) {
					_regionmsg('cluck', color('l').'Top 10 Score!')
					array_insert(@scores['top'], array('name': player(), 'score': @cluck['score']), @i)
					@top = true
				}
			}
			if(array_size(@scores['top']) > 10) {
				array_remove(@scores['top'], 10)
			}
			store_value('cluck', @scores)
		}
		#-------

		@cluck['score'] = 0
		@cluck['round'] = 1
		@cluck['player'] = ''
		set_block_at(@cluck['sound']['gameover'], '69:13')
		set_timeout(50, closure(set_block_at(@cluck['sound']['gameover'], '69:5')))
	} else {
		@cluck['round'] = @cluck['round'] + 1
		set_block_at(@cluck['sound']['winround'], '69:13')
		set_timeout(50, closure(set_block_at(@cluck['sound']['winround'], '69:5')))
	}
	_remove_region_entities('cluck', array('DROPPED_ITEMS', 'EXPERIENCE_ORB', 'CHICKEN'))
	# Reset for the next round.
	@cluck['chickens'] = array()
	@cluck['hit'] = 0
	@cluck['count'] = 10
	@cluck['active'] = 0
	unbind('cluckchicken')
	export('cluck', @cluck)
	_clear_pinv()
}