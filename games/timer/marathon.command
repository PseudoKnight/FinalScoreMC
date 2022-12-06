register_command('marathon', array(
	description: 'Creates a Marathon',
	usage: '/marathon <difficulty | numCourses:6,10,12,20>',
	tabcompleter: closure(@alias, @sender, @args, @info) {
		if(array_size(@args) == 1) {
			return(_strings_start_with_ic(array('6', '10', '12', '20', 'easy', 'easy-medium', 'medium', 'medium-hard', 'hard', 'very-hard'), @args[-1]));
		}
		return(array());
	},
	executor: closure(@alias, @sender, @args, @info) {
		// marathon join subcommand
		@num = 6;
		@difficulty = null;
		if(@args) {
		 	if(@args[0] == 'join') {
				@marathon = import('marathon');
				if(@marathon) {
					if(!_pbusy()) {
						@marathon['players'][player()] = 0;
						_worldmsg(pworld(), color('green').color('bold').player().' joined the queued Marathon.');
					} else {
						msg(color('gold').'You appear to be playing another game.');
					}
				}
				return(true);
			} else if(is_integral(@args[0])) {
				@num = integer(@args[0]);
				if(!array_contains(array(6, 10, 12, 20), @num)) {
					die(color('gold').'Can only play 6, 10, 12, or 20 random courses. You gave: '.@num);
				}
			} else if(array_contains(array('easy', 'easy-medium', 'medium', 'medium-hard', 'hard', 'very-hard'), @args[0])) {
				@difficulty = @args[0];
			} else {
				return(false);
			}
		} else {
			return(false);
		}
		
		@marathon = import('marathon');
		if(@marathon) {
			die(color('gold').'Marathon already running!');
		}

		// we need cake info to filter by difficulty
		@cakes = null;
		if(@difficulty) {
			@cakes = get_value('cakeinfo');
		}

		// populate course list
		@coursedata = get_values('times');
		@courses = array();
		foreach(@key: @value in @coursedata) {
			if(is_array(@value) && @key != 'times') { // make sure we are getting an actual course
				@course = split('.', @key)[1]; // grab the name by removing the namespace
				if(!@difficulty || @cakes[@course]['difficulty'] == @difficulty) {
					@courses[] = @course;
				}
			}
		}

		// release data
		@coursedata = null;
		@cakes = null;

		// randomize and limit to number selected
		try {
			@courses = array_rand(@courses, @num, false);
		} catch(RangeException @ex) {
			die(color('red').'Insufficient courses. Required: '.@num.', Found: '.array_size(@courses));
		}
		
		// create game object
		@players = associative_array();
		@marathon = array(
			players: @players,
			time: time(),
			courses: @courses,
		);
		@players[player()] = 0;
		export('marathon', @marathon);

		@warp = get_value('warp', @courses[0]);
		
		_click_tell(all_players(pworld()), array('&7[Marathon] ', array('&b[JOIN] ', '/marathon join'),
				player().' queued up a marathon ('.array_size(@courses).' courses)'));
		
		// start countdown
		@timer = array(15);
		@world = pworld();
		set_interval(1000, closure(){
			if(!ponline(player()) || pworld() != @world) {
				export('marathon', null);
				clear_task();
			}
			if(array_size(@players) < 2) {
				die();
			}
			if(--@timer[0] > 0) {
				foreach(@p in array_keys(@players)) {
					try(title(@p, '', @timer[0]))
				}
				die();
			}
			clear_task();
			
			set_interval(1000, 0, closure(){
				@time = time();
				if(array_size(@players) >= 2) {
					foreach(@p: @course in @players) {
						// handle marathon joiners
						if(!array_contains(get_bars(), @p)) {
							create_bar(@p, array(title: @p.': '.@course, style: 'SEGMENTED_'.@num, percent: 0.0));
							foreach(@p2 in array_keys(@players)) {
								bar_add_player(@p, @p2);
							}
							_set_pactivity(@p, 'Marathon');
							set_ploc(@p, @warp);
						// handle marathon leavers
						} else if(!ponline(@p) || pworld(@p) != @world) {
							remove_bar(@p);
							array_remove(@players, @p);
						}
					}
				} else {
					clear_task();
					if(array_size(@players) == 1) {
						@lastplayer = array_keys(@players)[0];
						title(@lastplayer, 'Too fast!', '');
						_worldmsg(pworld(), color('green').color('bold').@lastplayer.' left all other players in their dust.');
						remove_bar(@lastplayer);
						_set_pactivity(@lastplayer, null);
					}
					export('marathon', null);
				}
			});
		});
	}
));
