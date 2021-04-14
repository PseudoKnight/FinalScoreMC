include('utils.ms');
include('tasks.ms');

proc _fw_startgame(@pts) {
	_fw_startround();
	bind('entity_damage', array('id': 'fwdamage'), array('type': 'PLAYER', 'world': 'custom'), @e) {
		if(_fw_player(@e['player'])) {
			modify_event('amount', 0);
		}
	}
	_fw_msg('Game started. First to '.@pts.' points wins!');
	set_pscore('score', 'GOAL', @pts, 'fw');
	sk_region_flag('custom', 'frogware', 'pvp', 'allow');
}

proc _fw_endgame(@winners) {
	unbind('fwdamage');
	sk_region_flag('custom', 'frogware', 'pvp', 'deny');
	@messages = array(
		'Best frog in the house: ',
		'BeWare this frog: ',
		'All hail, king of the frogs: ',
		'Viletoad honors: ',
		'Beaten by: ',
		'Most hoppity: ',
	);
	_fw_msg(color('green').array_get_rand(@messages).array_implode(@winners, ' & '));
	foreach(@p in all_players('custom')) {
		if(_fw_player(@p)) {
			if(array_contains(@winners, @p)) {
				@coins = _fw_totalplayers();
				if(@coins > 3) {
					_acc_add(@p, @coins - 2);
					tmsg(@p, color('6').'+'.@coins.' coins');
					@session = _psession(@p);
					if(!array_index_exists(@session, 'trophies')) {
						@session['trophies'] = array();
					}
					@session['trophies'][] = color('yellow').'Best Frog in the House!';
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
	@region = sk_region_info('frogware', 'custom', 0);
	@loc = @region[1];
	@loc[0] += 18;
	@loc[2] += 18;
	foreach(@p in all_players('custom')) {
		if(array_contains(sk_current_regions(@p), 'frogware')) {
			stop_named_sound(@p, 'music_disc.stal', 'RECORDS');
		}
	}

	@blocks = import('frogware.blocks');
	if(!is_null(@blocks)) {
		foreach(@index: @block in @blocks) {
			if(@block[1] < @region[1][1]) {
				set_block(@block, 'WHITE_CONCRETE');
			} else {
				set_block(@block, 'AIR');
			}
			array_remove(@blocks, @index);
		}
	}

	if(pworld() !== 'custom') {
		_fw_endgame(array());
		_fw_msg('Host left the game.');
		return();
	}
	queue_delay(1000, 'fw')
	queue_push(closure(){
		@winners = array();
		@count = 0;
		@total = 0;
		@highscore = 0;
		@goal = get_pscore('score', 'GOAL', 'fw');
		foreach(@p in all_players('custom')) {
			if(_fw_player(@p)) {
				@total++;
				if(array_contains(sk_current_regions(@p), 'frogware')) {
					if(pmode(@p) == 'ADVENTURE') {
						set_pmode(@p, 'SURVIVAL');
					}
					if(get_pteam(@p, 'fw')['name'] == 'winners') {
						play_sound(ploc(@p), associative_array('sound': 'ENTITY_VILLAGER_YES'), @p);
						set_pscore('score', @p, get_pscore('score', @p, 'fw') + 1, 'fw');
						_fw_changeteam(@p, 'losers');
						@count++;
					}
					@score = get_pscore('score', @p, 'fw');
					if(@score == @goal) {
						@winners[] = @p;
					} else if(@score > @highscore) {
						@highscore = @score;
					}
					_clear_pinv(@p);
				} else {
					set_pscoreboard(@p);
					reset_all_pscores(@p, 'fw');
					_equip_kit(@p);
				}
			}
		}
		if(array_size(@winners) > 0 || @total == 0) {
			_fw_endgame(@winners);
		} else {
			@secs = 13 - integer(round(8 * (@highscore / @goal)));
			@tasks = array();
			if((@highscore / @goal) < 0.33) {
				@tasks = array('climb', 'keepaway', 'harvest', 'koth', 'cake', 'fall', 'cluck', 'frogegg', 'lavafall',
						'shepherd', 'anvil', 'trade', 'fish', 'panel');
			} else if((@highscore / @goal) < 0.90 || @total == 1) {
				@tasks = array('climb', 'keepaway', 'harvest', 'koth', 'cake', 'fall', 'cluck', 'frogegg', 'lavafall',
						'shepherd', 'anvil', 'trade', 'fish', 'panel');
			} else {
				@tasks = array('pvp');
			}
			@task = array_get_rand(@tasks);
			if(@total == 1 && @task === 'pvp', @task = array_get_rand(@tasks));
			queue_delay(1000, 'fw2');
			queue_push(closure(){
				play_named_sound(@loc, array('sound': 'music_disc.stal', 'pitch': 10 / @secs, 'category': 'RECORDS', 'volume': 3));
				_fw_task(@task, 'start', @secs);
			}, 'fw2');
			for(@i = @secs, @i >= 0, @i--) {
				if(@i > 0) {
					queue_push(closure(){
						_fw_countdown(@i);
					}, 'fw2');
					queue_delay(1000, 'fw2');
				} else {
					queue_push(closure(){
						_fw_countdown(@i);
						_fw_task(@task, 'end', @secs);
					}, 'fw2');
				}
			}
		}
	}, 'fw')

}
