register_command('times', array(
	'description': 'Lists and manages time trial records.',
	'usage': '/times <top|avg|segmented|worst> [course_id] [player]',
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		if(array_size(@args) == 1) {
			if(pisop(@sender)) {
				return(_strings_start_with_ic(array('top', 'avg', 'segmented', 'best', 'worst', 'reset', 'resetplayer'), @args[-1]));
			} else {
				return(_strings_start_with_ic(array('top', 'avg', 'segmented', 'best', 'worst'), @args[-1]));
			}
		}
		return(array());
	},
	'executor': closure(@alias, @sender, @args, @info) {
		@action = 'top';
		@id = '';
		@player = '';

		if(@args) {
			if(array_contains(array('top', 'avg', 'segmented', 'best', 'worst', 'reset', 'resetplayer'), @args[0])) {
				@action = @args[0];
				if(array_size(@args) > 1) {
					@id = @args[1];
					if(array_size(@args) > 2) {
						@player = @args[2];
					}
				}
			} else {
				@id = @args[0];
			}
		}
		if(!@id) {
			@regions = null;
			try {
				@regions = sk_current_regions();
			} catch(PlayerOfflineException @ex) {
				// probably console
			}
			if(@regions) {
				@id = @regions[-1];
			} else {
				@id = 'all';
			}
		}
		@title = _to_upper_camel_case(@id);

		switch(@action) {
			case 'avg':
				if(@id == 'all') {
					die(color('gold').'Cannot get the average of all courses at this time.');
				}
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
				if(@id == 'all') {
					die(color('gold').'Cannot reset times for all courses.');
				}
				if(!has_value('times', @id)) {
					die('There are no stats to reset for '.@title.'.');
				}
				@times = get_values('times', @id);
				foreach(@key: @time in @times) {
					clear_value(@key);
				}
				msg('Reset stats for '.@title.'.');

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
						@uuid = null;
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
						return(@value['count'] >= array_size(@courses) - 10);
					});
					@players = array();
					foreach(@uuid: @value in @filtered) {
						@players[] = array('name': _pdata_by_uuid(@uuid)['name'], 'total': @value['total'], 'count': @value['count']);
					}
					array_sort(@players, closure(@left, @right){
						return(@left['total'] > @right['total']);
					});
					@output = colorize('&e&m|-------------------&e&l[ TOP SEGMENTED TIMES ]&r');
					foreach(@index: @value in @players) {
						@time = '';
						if(@value['total'] >= 3600) {
							@time = simple_date('h\u0027h\u0027 m\u0027m\u0027 ss.S', integer(@value['total'] * 1000), 'Etc/UTC');
						} else {
							@time = simple_date('m\u0027m\u0027 ss.S', integer(@value['total'] * 1000));
						}
						@time = substr(@time, 0, length(@time) - 2).'s';
						@output .= '\n'.color('gray').(@index + 1).color('green').' [ '.@time.' ] '.color('reset').@value['name']
								.color(if(@value['count'] == array_size(@courses), 'green', 'gray')).' ('.@value['count'].'/'.array_size(@courses).')';
					}
					msg(@output);
				});

			case 'best':
			case 'worst':
				@courses = get_values('times');
				@puuid = null;
				if(@player) {
					@puuid = _get_uuid(to_lower(@player));
				} else if(ponline(@sender)) {
					@puuid = puuid(@sender, true);
				}
				if(@puuid == null) {
					die('No player specified.');
				}
				x_new_thread('times-ranks', closure(){
					@courseMap = associative_array();
					foreach(@key: @topTimes in @courses) {
						if(is_array(@topTimes) && @key != 'times') {
							@course = split('.', @key)[1];
							@place = 9000.1; // always use the best magic numbers
							foreach(@i: @entry in @topTimes) {
								if(@entry[0] == @puuid) {
									// address ties now
									@tie = 0.0;
									while(@i > 0 && @topTimes[@i - 1][2] == @entry[2]) {
										@i--;
										@tie = @tie + 0.1;
									}
									@place = @i + 1.0 + @tie;
									break();
								}
							}
							@courseMap[@course] = @place;
						}
					}
					@courseList = array();
					foreach(@key: @value in @courseMap) {
						@courseList[] = array(name: @key, rank: @value);
					}
					if(@action == 'best') {
						array_sort(@courseList, closure(@left, @right){
							return(@left['rank'] > @right['rank']);
						});
					} else { // worst
						array_sort(@courseList, closure(@left, @right){
							return(@left['rank'] < @right['rank']);
						});
					}

					msg(color('yellow').color('bold').'Your '.@action.' ranked courses:');
					@top = null;
					for(@i = 0, @i < 19, @i++) {
						@course = @courseList[@i];
						@title = _to_upper_camel_case(@course['name']);
						@rank = integer(@course['rank']);
						if(is_null(@top)) {
							@top = @rank;
						}
						@prefix = color('white');
						if(@top == @rank) {
							@prefix = color('white').color('bold');
						}
						if(@rank == 9001) {
							msg(color('gray').'Unranked - '.@prefix.@title);
						} else if(@course['rank'] != @rank) {
							msg(color('gray').@rank.' - '.@prefix.@title.color('gray').' (tie)');
						} else {
							msg(color('gray').@rank.' - '.@prefix.@title);
						}
					}
				});

			case 'top':
				if(@id == 'all') {
					@top = get_value('times');
					msg(colorize('&e&m|------------------&e&l[ TOTAL COURSE RANKINGS ]'));
					@max = min(19, array_size(@top));
					for(@i = 0, @i < @max, @i++) {
						if(@top[@i][1] == @sender) {
							msg(colorize(' '.if(@i < 9, '&80').'&e'.(@i + 1).' [ '.@top[@i][2].' ] &l'.@top[@i][1]));
						} else {
							msg(colorize(' '.if(@i < 9, '&80').'&7'.(@i + 1).'&a [ '.@top[@i][2].' ] &r'.@top[@i][1]));
						}
					}

				} else if(@player) {
					@uuid = _get_uuid(to_lower(@player));
					@time = get_value('times.'.@id, @uuid);
					if(!@time) {
						die('No time for '.@player.' on '.@id.'.')
					}
					msg(color('yellow').@player.'\'s best time for '.color('gold').@title.color('r').' is '.color('green').@time.' seconds.')

				} else {
					@times = get_value('times', @id);
					if(!@times) {
						die('No top times for '.@title.'.');
					}
					msg(colorize('&e&m|-------------------&e&l[ TOP TIMES: '.@title.' ]'));
					@lastTime = 1.0;
					@lastCount = 0;
					@lines = 1;
					for(@i = 0, @i < array_size(@times) && @lines < 20, @i++) {
						@thisTime = @times[@i][2];
						if(@thisTime == @lastTime){
							@lastCount++;
						} else {
							@lastCount = 0;
						}
						@time = '';
						if(@thisTime >= 3600) {
							@time = '>1 hour'
						} else if(@thisTime >= 60) {
							@time = simple_date('m\u0027m\u0027 ss.S', integer(@thisTime * 1000));
						} else {
							@time = simple_date('s.S', integer(@thisTime * 1000));
						}
						@timeSplit = split('.', @time, 1);
						if(array_size(@timeSplit) > 1) {
							@time = @timeSplit[0].'.'.@timeSplit[1][0].'s';
						}
						@place = @i + 1 - @lastCount;
						if(@times[@i][1] == @sender) {
							msg(colorize(' '.if(@place < 10, '&80').'&e'.@place.' [ '.@time.' ] &l'.@times[@i][1]));
						} else {
							msg(colorize(' '.if(@place < 10, '&80').'&7'.@place.'&a [ '.@time.' ] &r'.@times[@i][1]));
						}
						@lastTime = @thisTime;
						@lines++;
					}
				}
		}
	}
));
