proc _fw_create_scoreboard() {
	if(!array_contains(get_scoreboards(), 'fw')) {
		create_bar('fw', array(
			style: 'SOLID',
			percent: 0.0,
			visible: false,
		));
		create_scoreboard('fw');
		create_objective('score', 'DUMMY', 'fw');
		create_team('losers', 'fw');
		create_team('winners', 'fw');
		set_objective_display('score', array(slot: 'SIDEBAR', displayname: color('a').color('l').'Get Ready!'), 'fw');
		set_team_display('winners', array(color: 'GREEN'), 'fw');
		set_team_display('losers', array(color: 'YELLOW'), 'fw');
	}
}

proc _fw_start_game(@pts) {
	_add_activity('frogware', 'FrogWare', 'frogware', 'custom');
	@invitations = array();
	foreach(@p in all_players('custom')) {
		if(_fw_player(@p)) {
			set_pmode(@p, 'SURVIVAL');
			_fw_reset_player(@p);
		} else {
			@invitations[] = @p;
		}
	}
	_click_tell(@invitations, array('&7[FrogWare]&r Starting... ', array('&b[Click to Join]', '/frogware join')));
	bind('entity_damage', array(id: 'fwdamage'), array(type: 'PLAYER', world: 'custom'), @event) {
		if(_fw_player(@event['player'])) {
			modify_event('amount', 0);
		}
	}
	_fw_msg('Game started. First to '.@pts.' points wins!');
	set_pscore('score', 'GOAL', @pts, 'fw');
	sk_region_flag('custom', 'frogware', 'pvp', 'allow');
	_fw_start_round();
}

proc _fw_start_round(@secs = 12, @previousTask = null) {
	@region = sk_region_info('frogware', 'custom', 0);
	@loc = @region[1];
	@loc[0] += 18;
	@loc[2] += 18;
	foreach(@p in all_players('custom')) {
		stop_named_sound(@p, 'music_disc.stal', 'RECORDS');
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

	queue_delay(1000, 'fw');
	queue_push(closure(){
		update_bar('fw', array(visible: false));
		@winners = array();
		@count = 0;
		@total = 0;
		@firstplace = 0;
		@secondplace = 0;
		@goal = get_pscore('score', 'GOAL', 'fw');
		foreach(@p in all_players('custom')) {
			if(_fw_player(@p)) {
				@total++;
				if(array_contains(sk_current_regions(@p), 'frogware')) {
					if(pmode(@p) == 'ADVENTURE') {
						set_pmode(@p, 'SURVIVAL');
					}
					if(get_pteam(@p, 'fw')['name'] == 'winners') {
						play_sound(ploc(@p), associative_array(sound: 'ENTITY_VILLAGER_YES'), @p);
						set_pscore('score', @p, get_pscore('score', @p, 'fw') + 1, 'fw');
						_fw_change_team(@p, 'losers');
						@count++;
					}
					@score = get_pscore('score', @p, 'fw');
					if(@score == @goal) {
						@winners[] = @p;
					} else if(@score >= @firstplace) {
						@secondplace = @firstplace;
						@firstplace = @score;
					} else if(@secondplace == 0) {
						@secondplace = @score;
					}
				} else {
					set_pscoreboard(@p);
					reset_all_pscores(@p, 'fw');
					_equip_kit(@p);
					bar_remove_player('fw', @p);
				}
			}
		}
		if(array_size(@winners) > 0 || @total == 0) {
			_fw_end_game(@winners);
		} else {
			@secs = 13 - integer(round(8 * (@firstplace / @goal)));
			@tasks = null;
			if(@total != 1 && rand() < (@firstplace - 2 - @secondplace) / 10) {
				// CATCH-UP TASKS
				// 10% chance for every point above a 2 point lead
				@tasks = array('explosive', 'koth', 'pvp');
			} else if(@goal - @firstplace > 2 || @total == 1) {
				// NORMAL TASKS
				// first place player is more than a couple points away from winning (or only one player)
				@tasks = array('climb', 'keepaway', 'harvest', 'koth', 'cake', 'fall', 'cluck', 'frogegg', 'lavafall',
					'shepherd', 'anvil', 'trade', 'fish', 'panel', 'mine', 'enderpearl', 'extinguish', 'hotpotato',
					'parking', 'musicalchairs', 'step', 'fashion', 'elytra', 'mario', 'rise', 'rocketjump', 'hat');
			} else {
				// FINAL TASKS
				// first place player is within a couple points of winning.
				@tasks = array('pvp');
			}
			if(@previousTask && array_size(@tasks) > 1) {
				array_remove_values(@tasks, @previousTask);
			}
			@task = array_get_rand(@tasks);
			include("../tasks.library/@task.ms");
			queue_delay(1000, 'fw2');
			queue_push(closure(){
				play_named_sound(@loc, array(sound: 'music_disc.stal', pitch: 10 / @secs, category: 'RECORDS', volume: 3));
				_fw_start_task(@secs);
				update_bar('fw', array(visible: true, percent: 0.0, color: 'WHITE'));
			}, 'fw2');
			for(@i = @secs, @i >= 0, @i--) {
				if(@i > 0) {
					queue_push(closure(){
						foreach(@p in all_players('custom')) {
							if(_fw_player(@p) && !sk_region_contains('frogware', location_shift(ploc(@p), 'up', 2))) {
								set_pscoreboard(@p);
								reset_all_pscores(@p, 'fw');
								_equip_kit(@p);
								bar_remove_player('fw', @p);
							}
						}
						_fw_countdown(@i);
						update_bar('fw', array(percent: (@secs - @i) / @secs, color: if(@i < 4, 'YELLOW', 'WHITE')));
					}, 'fw2');
					queue_delay(1000, 'fw2');
				} else {
					queue_push(closure(){
						_fw_countdown(@i);
						update_bar('fw', array(percent: 1.0, color: 'RED'));
						_fw_end_task(@secs);
						foreach(@p in all_players('custom')) {
							if(_fw_player(@p)) {
								clear_pinv(@p);
							}
						}
						unbind('fwtask');
						_fw_start_round(@secs, @task);
					}, 'fw2');
				}
			}
		}
	}, 'fw');

}

proc _fw_end_game(@winners) {
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
				@coins = _fw_total_players();
				if(@coins > 3) {
					_acc_add(@p, @coins - 2);
					tmsg(@p, color('6').'+'.@coins.' coins');
					@session = _psession(@p);
					if(!array_index_exists(@session, 'trophies')) {
						@session['trophies'] = array();
					}
					@session['trophies'][] = color('yellow').'Best Frog in the House!';
					store_value('frogware', @winners);
				}
				_fw_change_team(@p, 'winners');
				launch_firework(location_shift(ploc(@p), 'up'), array(strength: 0, type: 'BALL_LARGE'));
				set_timeout(1000, closure(){
					launch_firework(location_shift(ploc(@p), 'up'), array(strength: 0, type: 'BALL_LARGE'));
					set_timeout(1000, closure(){
						launch_firework(location_shift(ploc(@p), 'up'), array(strength: 0, type: 'BALL_LARGE', flicker: true));
					});
				});
				discord_broadcast('minecraft_chat', array(embed: array(title: @p.' wins FrogWare!')));
			} else {
				_fw_change_team(@p, 'losers');
			}
			_equip_kit(@p);
			set_pmode(@p, 'ADVENTURE');
		}
	}
	if(array_contains(get_scoreboards(), 'fw')) {
		set_timeout(5000, closure(){
			remove_scoreboard('fw');
			remove_bar('fw');
			_remove_activity('frogware');
		});
	}
}
