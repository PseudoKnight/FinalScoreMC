include('utils.ms');
include('tasks.ms');

proc _fw_startgame(@pts) {
	_fw_startround()
	bind(entity_damage, array('id': 'fwdamage'), array('type': 'PLAYER', 'world': 'custom'), @e) {
		if(_fw_player(@e['player'])) {
			modify_event('amount', 0)
		}
	}
	_fw_msg('Game started. First to '.@pts.' points wins!')
	set_pscore('score', 'GOAL', @pts, 'fw')
	sk_region_flag('custom', 'frogware', 'pvp', 'allow');
}

proc _fw_endgame(@winners) {
	unbind('fwdamage')
	sk_region_flag('custom', 'frogware', 'pvp', 'deny');
	@messages = array(
		'Best frog in the house: ',
		'Best in show: ',
		'BeWare this frog: ',
		'All your base are belong to ',
		'Be jelly of ',
		'All hail, king of the frogs, ',
		'Viletoad honors ',
		'Achievement get: Beaten by ',
		'Most hoppity: ',
	)
	_fw_msg(color('green').array_rand(@messages, 1, false)[0].array_implode(@winners, ' & '));
	foreach(@p in all_players('custom')) {
		if(_fw_player(@p)) {
			if(array_contains(@winners, @p)) {
				@coins = _fw_totalplayers();
				if(@coins > 3) {
					_acc_add(@p, @coins - 2);
					tmsg(@p, color('6').'+'.@coins.' coins');
					@pstate = _pstate(@p);
					if(!array_index_exists(@pstate, 'trophies')) {
						@pstate['trophies'] = array();
					}
					@pstate['trophies'][] = color('yellow').'Best Frog in the House!';
				}
				_fw_changeteam(@p, 'winners');
			} else {
				_fw_changeteam(@p, 'losers');
			}
			_equip_kit(@p);
			set_pmode(@p, 'ADVENTURE');
		}
	}
	if(array_contains(get_scoreboards(), 'fw')) {
		set_timeout(5000, closure(){
			remove_scoreboard('fw');
			_remove_activity('frogware');
			store_value('frogware', @winners);
		});
	}
}

proc _fw_startround(@secs = 12) {
	@region = sk_region_info('frogware', 'custom')[0];
	@loc = @region[1];
	@loc[0] += 18;
	@loc[2] += 18;
	foreach(@p in all_players('custom')) {
		if(_fw_player(@p)) {
			stop_named_sound(@p, 'record.stal', 'RECORDS');
		}
	}

	@blocks = import('frogware.blocks');
	if(!is_null(@blocks)) {
		foreach(@index: @block in @blocks) {
			if(@block[1] < @region[1][1]) {
				set_block_at(@block, '155:0');
			} else {
				set_block_at(@block, 0);
			}
			array_remove(@blocks, @index);
		}
	}

	if(pworld() !== 'custom') {
		_fw_endgame(array())
		_fw_msg('Host left the game.')
		return();
	}
	queue_delay(1000, 'fw')
	queue_push(closure(){
		@winners = array()
		@count = 0
		@total = 0
		@highscore = 0
		@goal = get_pscore('score', 'GOAL', 'fw')
		foreach(@p in all_players('custom')) {
			if(_fw_player(@p)) {
				@total++
				if(array_contains(sk_current_regions(@p), 'frogware')) {
					if(pmode(@p) == 'ADVENTURE') {
						set_pmode(@p, 'SURVIVAL');
					}
					if(get_pteam(@p, 'fw')['name'] == 'winners') {
						play_sound(ploc(@p), associative_array('sound': 'VILLAGER_YES'), @p);
						set_pscore('score', @p, get_pscore('score', @p, 'fw') + 1, 'fw')
						_fw_changeteam(@p, 'losers')
						@count++
					}
					@score = get_pscore('score', @p, 'fw')
					if(@score == @goal) {
						array_push(@winners, @p)
					} else if(@score > @highscore) {
						@highscore = @score
					}
					_clear_pinv(@p);
				} else {
					set_pscoreboard(@p)
					reset_all_pscores(@p, 'fw')
					_equip_kit(@p);
				}
			}
		}
		if(array_size(@winners) > 0 || @total == 0) {
			_fw_endgame(@winners)
		} else {
			@secs = 13 - integer(round(8 * (@highscore / @goal)))
			@tasks = array();
			if((@highscore / @goal) < 0.33) {
				@tasks = array('climb', 'keepaway', 'harvest', 'koth', 'cake', 'fall', 'cluck', 'frogegg', 'lavafall',
						'shepherd', 'anvil', 'trade', 'fish');
			} else if((@highscore / @goal) < 0.90 || @total == 1) {
				@tasks = array('climb', 'keepaway', 'harvest', 'koth', 'cake', 'fall', 'cluck', 'frogegg', 'lavafall',
						'shepherd', 'anvil', 'trade', 'fish');
			} else {
				@tasks = array('pvp');
			}
			@task = @tasks[rand(array_size(@tasks))]
			if(@total == 1 && @task === 'pvp', @task = @tasks[rand(array_size(@tasks))])
			queue_delay(1000, 'fw2')
			queue_push(closure(){
				play_named_sound(@loc, array('sound': 'record.stal', 'pitch': 10 / @secs, 'category': 'RECORDS', 'volume': 3));
				_fw_task(@task, 'start', @secs)
			}, 'fw2')
			for(@i = @secs, @i >= 0, @i--) {
				if(@i > 0) {
					queue_push(closure(){
						_fw_countdown(@i)
					}, 'fw2')
					queue_delay(1000, 'fw2')
				} else {
					queue_push(closure(){
						_fw_countdown(@i)
						_fw_task(@task, 'end', @secs)
					}, 'fw2')
				}
			}
		}
	}, 'fw')

}
