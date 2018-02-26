register_command('times', array(
	'description': 'Lists and manages time trial records.',
	'usage': '/times <top|avg|segmented|reset|resetplayer|recalculate> [course_id] [player]',
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		if(array_size(@args) == 1) {
			return(_strings_start_with_ic(array('top', 'avg', 'segmented', 'reset', 'resetplayer', 'recalculate'), @args[-1]));
		}
		return(array());
	},
	'executor': closure(@alias, @sender, @args, @info) {
		@action = 'top';
		if(@args) {
			@action = @args[0];
		}
		
		@id = '';
		@player = '';
		if(array_size(@args) > 1) {
			@id = @args[1];
			if(array_size(@args) > 2) {
				@player = @args[2];
			}
		} else {
			@regions = sk_current_regions();
			if(!@regions) {
				die(color('gold').'You are not standing in a course.');
			}
			@id = @regions[-1];
		}

		switch(@action) {
			case 'avg':
				@times = get_values('times', @id);
				@total = 0;
				@alltimes = array();
				foreach(@time in @times) {
					if(is_array(@time)) {
						continue();
					}
					@total += @time;
					@alltimes[] = @time;
				}
				array_sort(@alltimes, 'NUMERIC');
				@median = array_size(@alltimes) / 2;
				if(array_size(@alltimes) % 2 > 0) {
					@median = (@alltimes[floor(@median)] + @alltimes[ceil(@median)]) / 2;
				} else {
					@median = @alltimes[@median];
				}
				@avg = round(@total / (array_size(@times) - 1), 1);
				msg('Median time: '.color('green').@median.color('r').' | Average time: '.color('green').@avg);
			
			case 'reset':
				if(!has_permission('command.resettimes')) {
					die('You do not have permission to reset stats for this course.');
				}
				if(!has_value('times', @id)) {
					die('There are no stats to reset for '.to_upper(@id).'.');
				}
				@times = get_values('times', @id);
				foreach(@key: @time in @times) {
					clear_value(@key);
				}
				msg('Reset stats for '.to_upper(@id).'.');
				
			case 'resetplayer':
				if(!has_permission('command.resettimes')) {
					die('You do not have permission to reset stats for this course.')
				}
				if(!@player) {
					die('This requires a player.');
				}
				@puuid = _get_uuid(to_lower(@player));
				@courses = get_values('times'.if(@id !== 'all', '.'.@id))
				if(is_null(@courses)) {
					die('Unknown arena.');
				}
				@count = 0;
				foreach(@key: @time in @courses) {
					if(is_array(@time) && @key != 'times') {
						foreach(@i: @t in @time) {
							if(@t[0] == @puuid) {
								msg('Removing '.@player.' from top ten in '.split('.', @key)[1]);
								array_remove(@time, @i);
								store_value(@key, @time);
								break();
							}
						}
					} else {
						try {
							@uuid = split('.', @key)[2];
						} catch(IndexOverflowException @ex) {
							// not a player time
							continue();
						}
						if(@uuid == @puuid) {
							msg('Removing '.@player.'\'s time in '.split('.', @key)[1]);
							clear_value(@key);
							@count += 1;
						}
					}
				}
				msg('Finished resetting '.@player.'\'s times in '.@count.' courses.');

			case 'segmented':
				@times = get_values('times');
				x_new_thread('segmented_times', closure(){
					@players = associative_array();
					@courses = array();
					foreach(@key: @time in @times) {
						if(!is_array(@time)) {
							@split = split('.', @key);
							@course = @split[1];
							if(!array_contains(@courses, @course)) {
								@courses[] = @course;
							}
							@uuid = @split[2];
							if(!array_index_exists(@players, @uuid)) {
								@players[@uuid] = array('total': @time, 'count': 1);
							} else {
								@players[@uuid]['total'] += @time;
								@players[@uuid]['count']++;
							}
						}
					}
					@filtered = array_filter(@players, closure(@key, @value) {
						return(@value['count'] == array_size(@courses));
					});
					@players = array();
					foreach(@uuid: @value in @filtered) {
						@players[] = array('name': _pdata_by_uuid(@uuid)['name'], 'total': @value['total']);
					}
					array_sort(@players, closure(@left, @right){
						return(@left['total'] > @right['total']);
					});
					@output = colorize('&e&m|-------------------&e&l[ TOP SEGMENTED TIMES ]&r');
					foreach(@index: @value in @players) {
						@time = '';
						if(@value['total'] >= 3600) {
							@time = simple_date('h\u0027h\u0027 m\u0027m\u0027 ss.S', integer(@value['total'] * 1000));
						} else {
							@time = simple_date('m\u0027m\u0027 ss.S', integer(@value['total'] * 1000));
						}
						@time = substr(@time, 0, length(@time) - 2).'s';
						@output .= '\n'.color('gray').(@index + 1).color('green').' [ '.@time.' ] '.color('reset').@value['name'];
					}
					msg(@output);
				});
				
			case 'top':
				if(@id == 'all') {
				
					@top = get_value('times');
					msg(colorize('&e&m|------------------&e&l[ TOP SCORE TOTALS ]'));
					for(@i = 0, @i < array_size(@top), @i++) {
						msg(colorize(' '.if(@i < 9, '&80').'&7'.(@i + 1).'&a [ '.@top[@i][2].' ] &r'.@top[@i][1]));
					}
				
				} else if(@player) {
					@uuid = _get_uuid(to_lower(@player));
					@time = get_value('times.'.@id, @uuid);
					if(!@time) {
						die('No time for '.@player.' on '.@id.'.')
					}
					msg(color('yellow').@player.'\'s best time for '.color('gold').to_upper(@id).color('r').' is '.color('green').@time.' seconds.')
					
				} else {
					
					@times = get_value('times', @id);
					if(!@times) {
						die('No top times for '.to_upper(@id).'.');
					}
					msg(colorize('&e&m|-------------------&e&l[ TOP TIMES: '.to_upper(@id).' ]'));
					@lastTime = 1.0;
					@lastCount = 0;
					for(@i = 0, @i < array_size(@times), @i++) {
						@thisTime = @times[@i][2];
						if(@thisTime == @lastTime){
							@lastCount++;
						} else {
							@lastCount = 0;
						}
						@time = '';
						if(@thisTime >= 60) {
							@time = simple_date('m\u0027m\u0027 ss.S', integer(@thisTime * 1000));
						} else {
							@time = simple_date('s.S', integer(@thisTime * 1000));
						}
						@time = substr(@time, 0, length(@time) - 2).'s';
						@place = @i + 1 - @lastCount;
						msg(colorize(' '.if(@place < 10, '&80').'&7'.@place.'&a [ '.@time.' ] &r'.@times[@i][1]));
						@lastTime = @thisTime;
					}
				
				}

		}
	}
));
