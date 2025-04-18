register_command('timer', array(
	description: 'Handles time trials for speed runs. (CommandBlocks Only)',
	usage: '/timer <start|stop|checkpoint> <id> [x y z]',
	permission: 'command.timer',
	executor: closure(@alias, @sender, @args, @info) {
		if(array_size(@args) == 1 || array_size(@args) == 4) {
			die();
		}

		@player = _get_nearby_player(get_command_block(), 6);
		if(!@player || phas_flight(@player)) {
			return();
		}

		if(extension_exists('chgeyser')) {
			if(geyser_connected(@player)) {
				return();
			}
		}

		@id = @args[1];
		@timers = import('timers');

		if(@args[0] == 'start') {

			@startLoc = ploc(@player);
			if(array_size(@args) == 5) {
				@yaw = @startLoc['yaw'];
				@pitch = @startLoc['pitch'];
				@startLoc = _center(_relative_coords(get_command_block(), @args[2], @args[3], @args[4]), 0);
				@startLoc['yaw'] = @yaw;
				@startLoc['pitch'] = @pitch;
			}

			set_phealth(@player, 20);
			set_phunger(@player, 20);
			set_psaturation(@player, 5);
			set_ponfire(@player, 0);
			set_plevel(@player, 0);
			set_pexp(@player, 0);
			clear_peffects(@player);
			set_pbed_location(@player, @startLoc);

			if(array_index_exists(@timers, @player)) {
				clear_task(@timers[@player][2]);
			} else {
				@title = _to_upper_camel_case(@id);
				_add_activity(@player.'timer', @player.' on '.@title);
				_set_pactivity(@player, @title, true); // overrideable
			}

			@timers[@player] = array(@id, time(), 0);
			@uuid = _get_uuid(to_lower(@player), false);
			@ptime = get_value('times.'.@id, @uuid);
			if(is_null(@ptime)) {
				@ptime = 0;
			}

			play_sound(ploc(@player), array(sound: 'ENTITY_FIREWORK_ROCKET_BLAST'), @player);

			@stop = false;
			@timers[@player][2] = set_interval(1000, closure(){
				if(ponline(@player)) {
					@ploc = ploc(@player);
					if(array_contains(sk_current_regions(@player), @id)) {
						if(!array_index_exists(@timers, @player)) {
							console('[Timer] ERROR: Failed to find player in array:', false);
							console('[Timer] '.@timers, false);
							clear_task();
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
								play_sound(@ploc, array(sound: 'ENTITY_VILLAGER_NO'), @player);
							} else {
								play_sound(@ploc, array(sound: 'UI_BUTTON_CLICK', pitch: 2), @player);
							}
						}

						if(pmode(@player) != 'ADVENTURE') {
							@stop = true;
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
					unbind(@player.'checkpoint');
					if(ponline(@player) && pworld(@player) === 'custom') {
						set_plevel(@player, 0);
						set_pexp(@player, 0);
						ptake_item(@player, array(name: 'GOLD_NUGGET'));
						ptake_item(@player, array(name: 'IRON_NUGGET'));
					}
					clear_task();
					_remove_activity(@player.'timer');
					if(!_psession(@player)['activity'] != 'marathon') {
						_set_pactivity(@player, null);
					}
				}
			});

			@restartButton = array(name: 'IRON_NUGGET', meta: array(display: color('green').color('bold').'Restart Button'));
			@checkpointButton = array(name: 'GOLD_NUGGET', meta: array(display: color('green').color('bold').'Checkpoint Button'));
			set_pinv(@player, 1, @restartButton);
			set_pheld_slot(@player, 0);

			unbind(@player.'checkpoint'); // in case they restarted from after a checkpoint
			ptake_item(@player, @checkpointButton);

			unbind(@player.'reset');
			bind('player_interact', array(id: @player.'reset'), array(player: @player, itemname: 'IRON_NUGGET'), @event, @startLoc) {
				if(!pcooldown('IRON_NUGGET') && (!@event['block'] || !string_ends_with(@event['block'], 'BUTTON'))) {
					cancel();
					set_pcooldown('IRON_NUGGET', 5);
					set_timeout(1, closure(){
						set_entity_fall_distance(puuid(), 0);
						set_ploc(@startLoc);
						play_sound(@startLoc, array(sound: 'ENTITY_ENDERMAN_TELEPORT'), player());
						set_ponfire(0);
					});
				}
			}

			if(!has_bind(@player.'timerdeath')) {
				bind('player_death', array(id: @player.'timerdeath'), array(player: @player), @event, @restartButton, @checkpointButton) {
					if(!_is_survival_world(pworld())) {
						modify_event('drops', array());
						set_timeout(400, closure(){
							pforce_respawn();
							set_timeout(100, closure(){
								if(!_is_survival_world(pworld())) {
									set_pinv(player(), 1, @restartButton);
									if(has_bind(player().'checkpoint')) {
										set_pinv(player(), 2, @checkpointButton);
									}
								}
							});
						});
					} else {
						unbind();
					}
				}
			}

		} else if(@args[0] == 'checkpoint'
		&& array_index_exists(@timers, @player)
		&& @timers[@player][0] == @id) {
			@loc = ploc(@player);
			if(array_size(@args) == 5) {
				@yaw = @loc['yaw'];
				@pitch = @loc['pitch'];
				@loc = _center(_relative_coords(get_command_block(), @args[2], @args[3], @args[4]), 0);
				@loc['yaw'] = @yaw;
				@loc['pitch'] = @pitch;
			}
			set_pbed_location(@player, @loc);
			@checkpointButton = array(name: 'GOLD_NUGGET', meta: array(display: color('green').color('bold').'Checkpoint Button'));
			set_pinv(@player, 2, @checkpointButton);
			unbind(@player.'checkpoint');
			bind('player_interact', array(id: @player.'checkpoint'), array(player: @player, itemname: 'GOLD_NUGGET'), @event, @loc) {
				if(!pcooldown('GOLD_NUGGET') && (!@event['block'] || !string_ends_with(@event['block'], 'BUTTON'))) {
					cancel();
					set_pcooldown('GOLD_NUGGET', 5);
					set_timeout(1, closure(){
						set_entity_fall_distance(puuid(), 0);
						set_ploc(@loc);
						play_sound(@loc, array(sound: 'ENTITY_ENDERMAN_TELEPORT'), player());
						set_ponfire(0);
					});
				}
			}

			@marathon = import('marathon');
			if(@marathon && array_index_exists(@marathon['players'], @player)) {
				@numCourses = array_size(@marathon['courses']);
				update_bar(@player, @marathon['players'][@player] / @numCourses + (1 / @numCourses / 2));
			}

		} else if(@args[0] == 'stop'
		&& array_index_exists(@timers, @player)
		&& @timers[@player][0] == @id) {

			@time = round((time() - @timers[@player][1]) / 1000, 1);
			unbind(@player.'timerdeath');
			unbind(@player.'checkpoint');
			ptake_item(@player, array('name': 'GOLD_NUGGET'));
			clear_task(@timers[@player][2]);
			array_remove(@timers, @player);
			_remove_activity(@player.'timer');
			play_sound(ploc(@player), array(sound: 'ENTITY_EXPERIENCE_ORB_PICKUP'), @player);

			tmsg(@player, color('yellow').'You achieved a time of '.color('bold').@time.color('yellow').' seconds.');
			console(@player.' achieved a time of '.@time.' at '.@id, false);
			set_plevel(@player, integer(@time));

			# MARATHON
			@marathon = import('marathon');
			if(@marathon && array_index_exists(@marathon['players'], @player)) {

				// we do not want to wait to remove reset button
				unbind(@player.'reset');
				ptake_item(@player, array(name: 'IRON_NUGGET'));

				@currentIndex = @marathon['players'][@player];

				if(@id != @marathon['courses'][@currentIndex]) {
					tmsg(@player, 'You skipped a course. Disqualified!');
					try(remove_bar(@player))
					_set_pactivity(@player, null);
					array_remove(@marathon['players'], @player);
				} else {
					@index = @currentIndex + 1;
					if(array_index_exists(@marathon['courses'], @index)) {
						@courseName = @marathon['courses'][@index];
						@marathon['players'][@player] = @index;
						@warp = get_value('warp', @courseName);
						set_entity_fall_distance(puuid(@player), 0);
						set_ploc(@player, @warp);
						@title = _to_upper_camel_case(@courseName);
						update_bar(@player, array(title: @player.': '.@title, percent: @index / array_size(@marathon['courses'])));
						title(@player, @title, '');

						// update progress of all players
						@highest = @index;
						foreach(@p: @i in @marathon['players']) {
							if(@i > @highest) {
								@highest = @i;
							}
						}
						@ranks = array('WHITE', 'YELLOW', 'RED');
						foreach(@p: @i in @marathon['players']) {
							@coursesBehind = @highest - @i;
							if(@coursesBehind >= array_size(@ranks)) {
								if(ponline(@p)) {
									title(@p, 'Too slow!', '');
									broadcast(color('yellow').color('bold').@p.' fell behind', all_players(pworld(@p)));
								}
								array_remove(@marathon['players'], @p);
								remove_bar(@p);
								_set_pactivity(@p, null);
							} else {
								update_bar(@p, array(color: @ranks[@coursesBehind]));
							}
						}

					} else {
						broadcast(color('bold').@player.' completed the Marathon!', all_players(pworld(@player)));
						_set_pactivity(@player, null);
						array_remove(@marathon['players'], @player);
						update_bar(@player, array(color: 'GREEN', percent: 1.0));
						set_timeout(7000, closure(){
							remove_bar(@player);
						});
						if(array_size(@marathon['players']) == 1) {
							@lastplayer = array_keys(@marathon['players'])[0];
							remove_bar(@lastplayer);
							_set_pactivity(@lastplayer, null);
							array_remove(@marathon['players'], @lastplayer);
						}
					}
				}
			} else {
				_set_pactivity(@player, null);
				set_timeout(7000, closure() {
					if(!has_bind(@player.'timerdeath')) {
						unbind(@player.'reset');
						if(ponline(@player) && !_is_survival_world(pworld(@player))) {
							ptake_item(@player, array(name: 'IRON_NUGGET'));
						}
					}
				});
			}

			// Check if time is better than personal best
			@uuid = _get_uuid(to_lower(@player), false);
			@ptime = get_value('times.'.@id, @uuid);
			if(@ptime && @time > @ptime) {
				// Time was not better
				die();
			}

			if(@time == @ptime) {
				tmsg(@player, color('green').'You tied your personal best.');
				die();
			}

			// Update personal time for this course
			if(@ptime) {
				tmsg(@player, color('green').'You beat your personal best time of '.color('bold').@ptime.color('green').' seconds.');
			}
			@loc = ploc(@player);
			@loc['y'] += 3;
			store_value('times.'.@id, @uuid, @time);

			// Update rankings for this course
			@times = get_value('times', @id);
			if(!@times) {
				// Create rankings for this mew course
				@times = array(array(@uuid, @player, @time));
				store_value('times', @id, @times);
				die();
			}
			@place = 0;
			@rankup = false;
			@tied = false;
			for(@i = 0, @i <= array_size(@times), @i++) {
				if(!@place) {
					if(!array_index_exists(@times, @i) || @time < @times[@i][2]) {
						if(array_index_exists(@times, @i) && (@times[@i][0] != @uuid || @i == 0)) {
							@rankup = true;
						}
						@place = @i + 1;
						while(@place > 1 && @times[@place - 2][2] == @time) {
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
			store_value('times', @id, @times);

			// Celebrate good times, come on!
			@rank = @place.'th';
			if(@place < 4 || @place > 20) {
				switch(@place % 10) {
					case 1:
						@rank = @place.'st';
					case 2:
						@rank = @place.'nd';
					case 3:
						@rank = @place.'rd';
					default:
						@rank =  @place.'th';
				}
			}
			if(@place < array_size(@times) / 2) {
				if(@tied) {
					_broadcast(color('green').@player.' tied the '.color('bold').@rank.color('green').' place time for '._to_upper_camel_case(@id).'!');
				} else if(@rankup) {
					_broadcast(color('green').@player.' got a '.color('bold').@rank.color('green').' place time for '._to_upper_camel_case(@id).'!');
				}
				launch_firework(@loc, array(
					strength: 1,
					colors: array(array(rand(256), rand(256), rand(256))),
					fade: array(array(rand(256), rand(256), rand(256))),
					type: 'BALL_LARGE',
				));
			} else {
				if(@tied) {
					tmsg(@player, color('green').'You tied the '.color('bold').@rank.color('green').' place time for '._to_upper_camel_case(@id).'!');
				} else if(@rankup) {
					tmsg(@player, color('green').'You got a '.color('bold').@rank.color('green').' place time for '._to_upper_camel_case(@id).'!');
				}
				launch_firework(@loc, array(
					strength: 0,
					colors: array(array(rand(256), rand(256), rand(256))),
					fade: array(array(rand(256), rand(256), rand(256))),
				));
			}

			// Recalculate course rankings
			@times = get_values('times');
			@top = get_value('rank.times');
			x_new_thread('times'.@player, closure(){
				@players = array();
				foreach(@key: @time in @times) {
					if(is_array(@time)) {
						@lastTime = 1.0;
						@lastCount = 0;
						foreach(@i: @t in @time) {
							if(@t[2] == @lastTime){
								@lastCount++;
							} else {
								@lastCount = 0;
							}
							if(!array_index_exists(@players, @t[0])) {
								@players[@t[0]] = array(@t[1], array_size(@time) - @i + @lastCount);
							} else {
								@players[@t[0]][1] += array_size(@time) - @i + @lastCount;
							}
							@lastTime = @t[2];
						}
					}
				}
				@ranks = array();
				foreach(@uuid2: @score in @players) {
					@ranks[] = array(@uuid2, @score[0], @score[1]);
				}
				array_sort(@ranks, closure(@left, @right){
					return(@left[2] < @right[2]);
				});
				@overallRankup = false;
				@suffix = 'th';
				if(@rankup || @tied) {
					@overallPlace = 0;
					foreach(@index: @time in @top) {
						if(@time[0] == @uuid) {
							@overallPlace = @index + 1;
							break();
						}
					}
					if(@overallPlace) {
						foreach(@index: @time in @ranks) {
							if(@time[0] == @uuid) {
								if(@index + 1 < @overallPlace) {
									@place = @index + 1;
									if(@place > 20 || @place < 4) { // special cases for 11, 12, and 13
										switch(@place % 10) {
											case 1:
												@suffix = 'st';
											case 2:
												@suffix = 'nd';
											case 3:
												@suffix = 'rd';
										}
									}
									@overallRankup = true;
								}
								break();
							}
						}
					}
				}
				x_run_on_main_thread_later(closure(){
					store_value('rank.times', @ranks);
					if(@overallRankup) {
						_broadcast(color('green').@player.' moved to '.@place.@suffix.' place overall!');
						play_sound(@loc, array(sound: 'UI_TOAST_CHALLENGE_COMPLETE'));
					}

					// Force cached menus to regenerate
					delete_virtual_inventory(@player.'easy-courses');
					delete_virtual_inventory(@player.'hard-courses');
				});
			});
		}
	})
);
