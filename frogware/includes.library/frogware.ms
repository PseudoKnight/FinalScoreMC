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
	_fw_msg('Best frog'.if(array_size(@winners) > 1, 's').' in the house: '.array_implode(@winners, ' & '))
	foreach(@p in all_players('custom')) {
		if(array_contains(@winners, @p)) {
			@coins = _fw_totalplayers();
			_acc_add(@p, @coins);
			tmsg(@p, color('6').'+'.@coins.' coins');
			_fw_changeteam(@p, 'winners');
		} else {
			_fw_changeteam(@p, 'losers');
		}
		_clear_pinv(@p);
	}
	if(array_contains(get_scoreboards(), 'fw')) {
		set_timeout(5000, closure(){
			remove_scoreboard('fw')
			_remove_activity('frogware');
		});
	}
}

proc _fw_startround(@secs = 12) {
	@loc = sk_region_info('frogware', 'custom')[0][1];
	@loc[0] += 18;
	@loc[2] += 18;
	play_effect(@loc, 'RECORD_PLAY', array('id': 0, 'radius': 32));

	@blocks = import('frogware.blocks');
	if(!is_null(@blocks)) {
		foreach(@index: @block in @blocks) {
			if(@block[1] < @loc[1][1]) {
				if(@block[0] == @loc[0][0] || @block[0] == @loc[1][0]
				|| @block[2] == @loc[0][2] || @block[2] == @loc[1][2]) {
					set_block_at(@block, '35:15');
				} else {
					set_block_at(@block, '155:0');
				}
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
					foreach(@team in get_teams('fw')) {
						if(@team['name'] === 'winners'
						&& array_contains(@team['players'], @p)) {
							set_pscore('score', @p, get_pscore('score', @p, 'fw') + 1, 'fw')
							_fw_changeteam(@p, 'losers')
							@count++
						}
					}
					@score = get_pscore('score', @p, 'fw')
					if(@score == @goal) {
						array_push(@winners, @p)
					} else if(@score > @highscore) {
						@highscore = @score
					}
				} else {
					set_pscoreboard(@p)
					reset_all_pscores(@p, 'fw')
					_clear_pinv(@p)
				}
			}
		}
		if(array_size(@winners) > 0 || @total == 0) {
			_fw_endgame(@winners)
		} else {
			@secs = 13 - round(8 * (@highscore / @goal))
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
				play_effect(@loc, 'RECORD_PLAY', array('id': rand(2256, 2268), 'radius': 32));
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
