proc _cluck_defaults() {
	return(array(
		'state': 0,
		'round': 1,
		'count': 10, # of chicken spawns
		'chickens': array(), # chicken entity ids to check if they're alive at round end
		'hit': 0, # num chickens hit
		'player': '',
		'gameover': 0,
		'score': 0, # cumulative hit chickens
		'sound': array(
			'gameover': array(-563, 55, -323, 'custom'),
			'winround': array(-563, 58, -323, 'custom'),
			'startround': array(-563, 52, -323, 'custom'),
		),
		'spawnloc': array(-575.5, 63, -336, 'custom'),
	));
}

proc _cluck_start(@cluck) {
	@cluck['state'] = 1;
	_clear_pinv(@cluck['player']);
	set_pinv(@cluck['player'], array(0: array('name': 'BOW'), 1: array('name': 'ARROW', 'qty': 10)));
	set_plevel(@cluck['player'], 0);
	_cluck_startround(@cluck);
}

proc _cluck_end(@cluck) {
	queue_clear('cluck');
	_equip_kit(@cluck['player']);
	export('cluck', _cluck_defaults());
	unbind('cluckdamage');
	unbind('cluckclose');
}

proc _cluck_startround(@cluck) {;
	_regionmsg('cluck', 'Round '.@cluck['round']);
	bind(entity_damage, array('id': 'cluckdamage'), array('cause': 'PROJECTILE', 'type': 'CHICKEN', 'world': 'custom'), @event, @cluck) {
		if(array_contains(@cluck['chickens'], @event['id'])) {
			if(@event['shooter'] != @cluck['player']) {
				cancel();
			} else {
				@cluck['score']++;
				@cluck['hit']++;
				pgive_item(@event['shooter'], 262, 1);
				set_plevel(@event['shooter'], @cluck['score']);
				array_remove_values(@cluck['chickens'], @event['id']);
			}
		}
	}

	set_block_at(@cluck['sound']['startround'], '69:13');
	set_timeout(100, closure(set_block_at(@cluck['sound']['startround'], '69:5')));

	queue_delay(2000, 'cluck');
	@spawn = closure(){
		@offset =  rand(10);
		@adult = rand(10);
		@angle = rand(100);
		@loc = @cluck['spawnloc'][];
		@loc[2] += @offset;
		@entityid = spawn_mob('CHICKEN', 1, @loc)[0];
		if(@adult) {
			play_sound(@loc, array('sound': 'CHICKEN_EGG_POP'));
		} else {
			set_mob_age(@entityid, -24000);
			play_sound(@loc, array('sound': 'CHICKEN_EGG_POP', 'pitch': 2));
		}
		set_entity_velocity(@entityid, array(0, 1.1, (@angle - 12.5 * @offset) * (@cluck['round'] / 1000)));
		set_entity_health(@entityid, 25);
		@cluck['chickens'][] = @entityid;
	}
	for(@i = @cluck['count'], @i > 0, @i--) {
		queue_delay(400 * rand(1, 12 - @cluck['round']), 'cluck');
		queue_push(@spawn, 'cluck');
	}
	queue_delay(5000, 'cluck');
	queue_push(closure(_cluck_endround(@cluck)), 'cluck');
}

proc _cluck_endround(@cluck) {
	foreach(@chicken in @cluck['chickens']) {
		try {
			entity_remove(@chicken);
		} catch(BadEntityException @ex) {
			// ignore
		}
	}
	@player = @cluck['player'];
	@score = @cluck['score'];

	_regionmsg('cluck', color('yellow').@player.' hit '.@cluck['hit'].' chickens.');

	# Did we not meet the required hit chickens? (or round 10)
	if(@cluck['hit'] < @cluck['count'] / 2 || @cluck['round'] == 10) {
		_regionmsg('cluck', color('yellow').color('bold').to_upper(@player).' GAMEOVER! Score: '.@score);
		@cluck['gameover'] = @cluck['round'];
		
		if(ponline(@player) && pworld(@player) === 'custom') {
			_clear_pinv(@player);
		}

		/*
			STATS
		*/
		@scores = get_value('cluck');
		@uuid = puuid(@player);
		@best = 0;
		if(array_index_exists(@scores, @uuid)) {
			@best = @scores[@uuid];
		}
		if(@score > @best) {
			if(@best > 0) {
				_regionmsg('cluck', color('bold').'You beat your personal best of '.@best.'!');
			}
			tmsg(@player, color('gold').'+ '.(@score - @best).' coins');
			_acc_add(@player, @score - @best);
			@scores[@uuid] = @score;
			@top = false;
			for(@i = 0, @i < 20, @i++) {
				if(@top && array_index_exists(@scores['top'], @i) && @scores['top'][@i]['uuid'] == @uuid) {
					array_remove(@scores['top'], @i);
				} else if(!@top && (!array_index_exists(@scores['top'], @i) || @scores['top'][@i]['score'] < @score)) {
					_regionmsg('cluck', color('bold').'Top 20 Score!');
					array_insert(@scores['top'], array('name': @player, 'score': @score, 'uuid': @uuid), @i);
					@top = true;
				}
			}
			if(array_size(@scores['top']) > 20) {
				array_remove(@scores['top'], 20);
			}
			store_value('cluck', @scores);
		}
		// END STATS

		set_block_at(@cluck['sound']['gameover'], '69:13');
		set_timeout(100, closure(set_block_at(@cluck['sound']['gameover'], '69:5')));

	} else {
		set_block_at(@cluck['sound']['winround'], '69:13');
		set_timeout(100, closure(set_block_at(@cluck['sound']['winround'], '69:5')));
	}

	_remove_region_entities('cluck', array('DROPPED_ITEM', 'EXPERIENCE_ORB', 'CHICKEN'));
	# Reset for the next round.
	if(!@cluck['player'] || @cluck['gameover'] || @cluck['round'] == 10) {
		@cluck = _cluck_defaults();
	} else {
		@cluck['round']++;
		@cluck['chickens'] = array();
		@cluck['hit'] = 0;
		bind(projectile_hit, array('id': 'cluckstart'), array('type': 'ARROW'), @event, @cluck) {
			if(@event['shooter'] == puuid(@cluck['player'])) {
				unbind();
				_cluck_startround(@cluck);
			}
		}
	}
	unbind('cluckdamage');
	export('cluck', @cluck);
}
