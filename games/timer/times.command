@courses = array('all');
foreach(@course in array_keys(get_values('times'))) {
	@split = split('.', @course);
	if(array_size(@split) == 2) {
		@courses[] = @split[1];
	}
}
register_command('times', array(
	description: 'Lists and manages time trial records.',
	usage: '/times <top|avg|segmented|best|worst> [course] [player]',
	tabcompleter: closure(@alias, @sender, @args, @info) {
		if(array_size(@args) == 1) {
			if(pisop(@sender)) {
				return(_strings_start_with_ic(array('top', 'avg', 'segmented', 'best', 'worst', 'reset', 'resetplayer', 'recalculate'), @args[-1]));
			} else {
				return(_strings_start_with_ic(array('top', 'avg', 'segmented', 'best', 'worst'), @args[-1]));
			}
		} else if(array_size(@args) == 2) {
			return(_strings_start_with_ic(@courses, @args[-1]));
		}
		return(null);
	},
	executor: closure(@alias, @sender, @args, @info) {
		@action = 'top';
		@id = '';
		@player = '';

		if(@args) {
			if(array_contains(array('top', 'avg', 'segmented', 'best', 'worst', 'reset', 'resetplayer', 'recalculate'), @args[0])) {
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
				if(!@times) {
					die('No average times for '.@title.'.');
				}
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
				if(array_size(@alltimes) % 2 == 0) {
					@median = (@alltimes[@median - 1] + @alltimes[@median]) / 2;
				} else {
					@median = @alltimes[integer(@median)];
				}
				@avg = round(@total / (array_size(@times) - 1), 1);
				msg(@title.' | Median time: '.color('green').@median.color('r').' | Average time: '.color('green').@avg);

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
							if(@t[0] != @puuid) {
								continue();
							}
							msg('Removing '.@player.' from top list in '.split('.', @key)[1]);
							array_remove(@time, @i);
							store_value(@key, @time);
							break();
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
							msg('Removing '.@player.' time in '.split('.', @key)[1]);
							clear_value(@key);
							@count += 1;
						}
					}
				}
				msg('Finished resetting '.@player.' times in '.@count.' courses.');

			case 'segmented':
				@times = get_values('times');
				x_new_thread('segmented_times', closure(){
					@players = associative_array();
					@courses = associative_array();
					foreach(@key: @time in @times) {
						if(is_array(@time)) {
							// Only looking for player times
							continue();
						}
						@split = split('.', @key);
						@course = @split[1];
						@uuid = @split[2];
						if(!array_index_exists(@courses, @course)) {
							@courses[@course] = array(
								count: 1,
								total: @time,
								players: array(@uuid),
							);
						} else {
							@courses[@course]['count']++;
							@courses[@course]['total'] += @time;
							@courses[@course]['players'][] = @uuid;
						}
						if(!array_index_exists(@players, @uuid)) {
							@players[@uuid] = array(
								total: @time,
								count: 1
							);
						} else {
							@players[@uuid]['total'] += @time;
							@players[@uuid]['count']++;
						}
					}
					@filtered = array_filter(@players, closure(@key, @value) {
						return(@value['count'] >= array_size(@courses) / 2);
					});

					foreach(@course: @data in @courses) {
						@data['avg'] = round(@data['total'] / @data['count'], 1);
					}

					@players = array();
					foreach(@uuid: @value in @filtered) {
						if(@value['count'] < array_size(@courses)) {
							foreach(@course: @data in @courses) {
								if(!array_contains(@data['players'], @uuid)) {
									@value['total'] += @data['avg'];
								}
							}
						}
						@players[] = array(
							uuid: @uuid,
							total: @value['total'], 
							count: @value['count']
						);
					}
					array_sort(@players, closure(@left, @right){
						return(@left['total'] > @right['total']);
					});

					@players = @players[cslice(0, min(18, array_size(@players) - 1))];
					foreach(@pdata in @players) {
						@pdata['name'] = _pdata_by_uuid(@pdata['uuid'])['name'];
					}

					@output = colorize('&e&m|---------------------------&e&l[ TOP SEGMENTED TIMES ]&r');
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
						if(!is_array(@topTimes) || @key == 'times') {
							// Only looking for the top times for each course
							continue();
						}
						@course = split('.', @key)[1];
						@place = 9000.1; // always use the best magic numbers
						foreach(@i: @entry in @topTimes) {
							if(@entry[0] != @puuid) {
								continue();
							}
							// address ties now
							@tie = 0;
							while(@i > 0 && @topTimes[@i - 1][2] == @entry[2]) {
								@i--;
								@tie++;
							}
							@place = @i + 1.0 + @tie / 10;
							break();
						}
						@courseMap[@course] = @place;
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

					msg(color('yellow').color('bold')._to_upper_camel_case(@action).' ranked courses:');
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
						if(@rank >= 9000) {
							msg(color('gray').'Unranked - '.@prefix.@title);
						} else if(@course['rank'] != @rank) {
							msg(color('gray').@rank.' - '.@prefix.@title.color('gray').' (tie)');
						} else {
							msg(color('gray').@rank.' - '.@prefix.@title);
						}
					}
				});

			case 'top':
				@top = if(@id == 'all', get_value('rank.times'), get_value('times', @id));
				if(!@top) {
					die('No top times for '.@title.'.');
				}
				@uuid = null;
				if(@player) {
					@uuid = _get_uuid(to_lower(@player));
				} else if(ponline(@sender)) {
					@uuid = puuid(@sender, true);
				}
				@indexes = range(min(15, array_size(@top)));
				if(array_size(@indexes) < array_size(@top)) {
					@checkForPlayer = @id == 'all' || @uuid && !is_null(get_value('times.'.@id, @uuid));
					for(@i = if(@checkForPlayer, 0, 15), @i < array_size(@top) && array_size(@indexes) < 19, @i++) {
						if(@top[@i][0] == @uuid) {
							@checkForPlayer = false;
						}
						if(@i >= 15) {
							// Try to list target player at the bottom of the list if still unfound
							if(!@checkForPlayer || @i + 1 == array_size(@top) || @top[@i + 1][0] == @uuid) {
								@indexes[] = @i;
							} else if(@i == 15) {
								// ellipsis
								@indexes[] = null;
							}
						}
					}
				}
				if(@id == 'all') {
					msg(colorize('&e&m|------------------&e&l[ TOTAL COURSE RANKINGS ]'));
					@max = min(19, array_size(@top));
					foreach(@lineIndex: @i in @indexes) {
						if(is_null(@i)) {
							msg('  ···');
							continue();
						}
						if(@top[@i][0] == @uuid) {
							msg(colorize(' '.if(@i < 9, '&80').'&e'.(@i + 1).' [ '.@top[@i][2].' ] &l'.@top[@i][1]));
						} else {
							msg(colorize(' '.if(@i < 9, '&80').'&7'.(@i + 1).'&a [ '.@top[@i][2].' ] &r'.@top[@i][1]
									.if(@lineIndex == 18 && array_size(@top) - 1 > @i, ' (and '.(array_size(@top) - 1 - @i).' more)')));
						}
					}
				} else {
					msg(colorize('&e&m|-------------------&e&l[ TOP TIMES: '.@title.' ]'));
					@lastTime = 1.0;
					@lastCount = 0;
					foreach(@lineIndex: @i in @indexes) {
						if(is_null(@i)) {
							msg('  ···');
							continue();
						}
						@thisTime = @top[@i][2];
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
						if(@top[@i][0] == @uuid) {
							msg(colorize(' '.if(@place < 10, '&80').'&e'.@place.' [ '.@time.' ] &l'.@top[@i][1]));
						} else {
							msg(colorize(' '.if(@place < 10, '&80').'&7'.@place.'&a [ '.@time.' ] &r'.@top[@i][1]
									.if(@lineIndex == 18 && array_size(@top) - 1 > @i, ' (and '.(array_size(@top) - 1 - @i).' more)')));
						}
						@lastTime = @thisTime;
					}
				}

			case 'recalculate':
				if(!pisop()) {
					die('Only ops can recalculate times.');
				}
				@allcourses = get_values('times');
				x_new_thread('times', closure(){
					// Add all players to course lists
					foreach(@key: @time in @allcourses) {
						if(is_array(@time)) {
							// This is a list. We are only interested in player times.
							continue();
						}
						@split = split('.', @key, 2);
						@course = @split[1];
						@uuid = @split[2];
						@player = _pdata_by_uuid(@uuid)['name'];
						@times = @allcourses['times.'.@course];
						for(@i = 0, @i <= array_size(@times), @i++) {
							if(!array_index_exists(@times, @i)) {
								// end of list
								@times[] = array(@uuid, @player, @time);
								break();
							} else if(@times[@i][0] == @uuid) {
								// already exists in the list
								break();
							} else if(@time < @times[@i][2]) {
								// can insert the player into the list here
								array_insert(@times, array(@uuid, @player, @time), @i);
								break();
							}
						}
					}

					// Recalculate totals based on the new lists
					@players = array();
					foreach(@key: @topTimes in @allcourses) {
						if(is_array(@topTimes) && @key != 'times') {
							@lastTime = 1.0;
							@lastCount = 0;
							foreach(@i: @entry in @topTimes) {
								@uuid = @entry[0];
								@player = @entry[1];
								@time = @entry[2];

								// Give full points for ties
								if(@time == @lastTime){
									@lastCount++;
								} else {
									@lastCount = 0;
								}

								// Increment scores based on how many players they beat
								if(!array_index_exists(@players, @uuid)) {
									@players[@uuid] = array(@player, array_size(@topTimes) - @i + @lastCount);
								} else {
									@players[@uuid][1] += array_size(@topTimes) - @i + @lastCount;
								}
								@lastTime = @time;
							}
						}
					}
					// Convert to normal array for sorting
					@ranks = array();
					foreach(@uuid: @entry in @players) {
						@ranks[] = array(@uuid, @entry[0], @entry[1]);
					}
					array_sort(@ranks, closure(@left, @right){
						return(@left[2] < @right[2]);
					});

					// Store the new lists on the main thread to avoid issues.
					x_run_on_main_thread_later(closure(){
						clear_value('times'); // legacy ranks
						store_value('rank.times', @ranks);
						foreach(@key: @value in @allcourses) {
							if(is_array(@value)) {
								store_value(@key, @value);
							}
						}
						msg('Finished.');
					});
				});
		}
	}
));
