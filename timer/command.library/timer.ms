register_command('timer', array(
	'description': 'Handles time trials for speed runs. (CommandBlocks Only)',
	'usage': '/timer <start|stop> <id> <player>',
	'permission': 'command.timer',
	'executor': closure(@alias, @sender, @args, @info) {
		if(array_size(@args) != 3
		|| phas_flight(@args[2])
		|| pmode(@args[2]) != 'ADVENTURE') {
			die();
		}
		
		@id = @args[1];
		@player = @args[2];
		@startLoc = ploc(@player);
		
		@timers = import('timers');
		
		if(@args[0] === 'start') {
		
			set_phealth(@player, 20);
			set_phunger(@player, 20);
			set_psaturation(@player, 5);
			set_ponfire(@player, 0);
			set_plevel(@player, 0);
			set_pexp(@player, 0);
		
			if(array_index_exists(@timers, @player)) {
				clear_task(@timers[@player][2]);
			} else {
				_add_activity(@player.'timer', @player.' on '.to_upper(@id));
			}
		
			@timers[@player] = array(@id, time(), 0);
			@uuid = _get_uuid(to_lower(@player), false);
			@ptime = get_value('times.'.@id, @uuid);
			if(is_null(@ptime)) {
				@ptime = 0;
			}
		
			play_sound(ploc(@player), array('sound': 'FIREWORK_BLAST'), @player);
		
			@stop = false;
			@timers[@player][2] = set_interval(1000, closure(){
				if(ponline(@player)) {
					@ploc = ploc(@player);
					if(array_contains(sk_current_regions(@player), @id)) {
						if(!array_index_exists(@timers, @player)) {
							console('[Timer] ERROR: Failed to find player in array:', false);
							console('[Timer] '.@timers, false);
							die();
						}
						@time = integer(round((time() - @timers[@player][1]) / 1000));
						if(extension_exists('CHNaughty')) {
							action_msg(@player, @time);
						} else {
							set_plevel(@player, @time);
						}
		
						if(@time < @ptime) {
							@percent = integer((@time / @ptime) * 100);
							set_pexp(@player, min(99, @percent));
						}
		
						if(@time + 5 > @ptime && @time <= @ptime + 0.5) {
							if(@time == round(@ptime)) {
								play_sound(@ploc, array('sound': 'VILLAGER_NO'), @player);
							} else {
								play_sound(@ploc, array('sound': 'CLICK', 'pitch': 2), @player);
							}
						}
		
					} else if(@ploc['y'] < 0) {
						pkill(@player);
		
					} else {
						if(extension_exists('CHNaughty')) {
							action_msg(@player, 'X');
						} else if(!_is_survival_world(pworld(@player))) {
							set_plevel(@player, 0);
						}
						@stop = true;
					}
				} else {
					@stop = true;
				}
		
				if(@stop) {
					array_remove(@timers, @player);
					unbind(@player.'reset');
					unbind(@player.'timerdeath');
					if(ponline(@player) && pworld(@player) === 'custom') {
						set_plevel(@player, 0);
						set_pexp(@player, 0);
						ptake_item(@player, array('name': 'GOLD_NUGGET'));
					}
					clear_task();
					_remove_activity(@player.'timer');
				}
			});
		
			if(@ptime) {
				@restartButton = array('name': 'GOLD_NUGGET', 'meta': array('display': color('green').color('bold').'Restart Button'));
				set_pinv(@player, 0, @restartButton);
			
				if(!has_bind(@player.'reset')) {
					bind(player_interact, array('id': @player.'reset'), array('player': @player, 'item': 371), @e, @startLoc) {
						if(@e['action'] == 'right_click_block') {
							@block = split(':', @e['block'])[0];
							if(@block == '77' || @block == '143') {
								die();
							}
						}
						cancel();
						set_ploc(@startLoc);
					}
				}
				if(!has_bind(@player.'timerdeath')) {
					bind(player_death, array('id': @player.'timerdeath'), array('player': @player), @e, @restartButton) {
						if(!_is_survival_world(pworld())) {
							modify_event('drops', array());
							set_timeout(500, closure(){
								respawn();
								set_timeout(50, closure(){
									set_pinv(player(), 0, @restartButton);
								});
							});
						}
					}
				}
			}
		
		
		} else if(@args[0] === 'stop'
		&& array_index_exists(@timers, @player)
		&& @timers[@player][0] == @id) {
		
			@time = round((time() - @timers[@player][1]) / 1000, 1);
			unbind(@player.'reset');
			unbind(@player.'timerdeath');
			ptake_item(@player, array('name': 'GOLD_NUGGET'));
			clear_task(@timers[@player][2]);
			array_remove(@timers, @player);
			_remove_activity(@player.'timer');
			play_sound(ploc(@player), array('sound': 'ORB_PICKUP'), @player);
		
			tmsg(@player, color('yellow').'You achieved a time of '.color('bold').@time.color('yellow').' seconds.');
			console(@player.' achieved a time of '.@time.' at '.@id, false);
			set_plevel(@player, integer(@time));
		
			# PERSONAL TIME
			@uuid = _get_uuid(to_lower(@player), false);
			@ptime = get_value('times.'.@id, @uuid);
			if(@ptime && @time >= @ptime) {
				die();
			}
		
			if(@ptime) {
				tmsg(@player, color('green').'You beat your personal best time of '.color('bold').@ptime.color('green').' seconds.');
			}
			@loc = ploc(@player);
			@loc['y'] += 3;
			store_value('times.'.@id, @uuid, @time);
		
			# TOP TIMES
			@times = get_value('times', @id);
			if(!@times) {
				@times = array(array(@uuid, @player, @time));
				store_value('times', @id, @times);
				die();
			}
		
			@place = 0;
			@rankup = false;
			@tied = false;
			for(@i = 0, @i < 20, @i++) {
				if(!@place) {
					if(!array_index_exists(@times, @i) || @time < @times[@i][2]) {
						if(array_index_exists(@times, @i) && @times[@i][0] != @uuid) {
							@rankup = true;
						}
						@place = @i + 1;
						if(@i > 0 && @times[@i - 1][2] == @time) {
							@tied = true;
							@place--;
						}
						array_insert(@times, array(@uuid, @player, @time), @i);
					}
				} else {
					if(array_index_exists(@times, @i) && @times[@i][0] == @uuid) {
						array_remove(@times, @i);
					}
				}
			}
			if(@place) {
				switch(@place) {
					case 1:
						@place = '1st';
					case 2:
						@place = '2nd';
					case 3:
						@place = '3rd';
					default:
						@place = @place.'th';
				}
				if(@rankup) {
					broadcast(color('green').@player.' got a '.color('bold').@place.color('green').' place time for '.to_upper(@id).'!');
				} else if(@tied) {
					broadcast(color('green').@player.' tied the '.color('bold').@place.color('green').' place time for '.to_upper(@id).'!');
				}
				launch_firework(@loc, array(
					'strength': 1,
					'flicker': true,
					'trail': true,
					'colors': array(array(rand(256), rand(256), rand(256))),
					'fade': array(array(rand(256), rand(256), rand(256))),
					'type': 'BALL_LARGE',
				));
				if(array_size(@times) > 20) {
					array_remove(@times, 20);
				}
				store_value('times', @id, @times);
		
				// Recalculate average placement
				@id = 'all';
				include('subcommands/recalculate.ms');
		
			} else {
				launch_firework(@loc, array(
					'strength': 0,
					'trail': false,
					'colors': array(array(rand(256), rand(256), rand(256))),
					'fade': array(array(rand(256), rand(256), rand(256))),
				));
			}
		}
	});
);
