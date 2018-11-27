register_command('marathon', array(
	'description': 'Creates a Marathon',
	'usage': '/marathon <difficulty|number>',
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		if(array_size(@args) == 1) {
			return(_strings_start_with_ic(array('easy', 'easy-medium', 'medium', 'medium-hard', 'hard', 'very-hard'), @args[-1]));
		}
		return(array());
	},
	'executor': closure(@alias, @sender, @args, @info) {
		// marathon join subcommand
		@num = 0;
		@difficulty = null;
		if(@args) {
		 	if(@args[0] == 'join') {
				@marathon = import('marathon');
				if(@marathon) {
					if(!_psession(player())['activity']) {
						@marathon['players'][player()] = @marathon['courses'][0];
						_worldmsg(pworld(), color('green').color('bold').player().' joined the queued Marathon.');
					} else {
						msg(color('gold').'You appear to be playing another game.');
					}
				}
				return(true);
			} else if(is_integral(@args[0])) {
				@num = integer(@args[0]);
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
		
		// else queue up the marathon
		// populate course list
		@coursedata = get_values('times');
		@courses = array_filter(@coursedata, closure(@key, @value){
			return(is_array(@value) && @key != 'times');
		});
		@courses = array_rand(@courses, if(@num && @num < array_size(@courses), @num, array_size(@courses)));
		
		// remove namespace from course name
		foreach(@index: @course in @courses) {
			@name = split('.', @course)[1];
			@courses[@index] = @name;
		}
		
		// filter courses
		if(@difficulty) {
			@cakes = get_value('cakeinfo');
			foreach(@index: @course in @courses) {
				if(@cakes[@course]['difficulty'] != @difficulty) {
					array_remove(@courses, @index);
				}
			}
		}

		// populate coursetimes array
		@coursetimes = associative_array();
		foreach(@course in @courses) {
			@coursetimes[@course] = null;
		}
		
		// create game object
		@players = associative_array();
		@marathon = array(
			'players': @players,
			'time': time(),
			'times': @coursetimes,
			'courses': @courses,
		);
		@players[player()] = @courses[0];
		export('marathon', @marathon);
		
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
					try(title(@p, '', @timer[0]));
				}
				die();
			}
			clear_task();
			
			@firstwarp = get_value('warp', @courses[0]);
			
			set_interval(1000, 0, closure(){
				@time = time();
				if(array_size(@players) < 2) {
					clear_task();
					if(array_size(@players) == 1) {
						@lastplayer = array_keys(@players)[0];
						title(@lastplayer, 'Too fast!', '');
						_worldmsg(pworld(), color('green').color('bold').@lastplayer.' left all other players in their dust.');
						remove_bar(@lastplayer);
						_set_pactivity(@lastplayer, null);
					}
					export('marathon', null);
					die();
				}
				foreach(@p: @course in @players) {
					// handle marathon joiners
					if(!array_contains(get_bars(), @p)) {
						create_bar(@p, array('title': @p.': '.@course, 'color': 'GREEN', 'visible': false));
						foreach(@p2 in array_keys(@players)) {
							bar_add_player(@p, @p2);
						}
						_set_pactivity(@p, 'marathon');
						set_ploc(@p, @firstwarp);
					}

					if(@marathon['times'][@course]) {
						if(@time > @marathon['times'][@course] + 120000) {
							if(ponline(@p)) {
								title(@p, 'Too slow!', '');
								_worldmsg(pworld(), color('yellow').color('bold').@p.' fell behind on '.@course);
							}
							array_remove(@marathon['players'], @p);
							remove_bar(@p);
							_set_pactivity(@p, null);
						} else {
							@percent = 1.0 - (@time - @marathon['times'][@course]) / 120000;
							update_bar(@p, array(
								'percent': @percent,
								'color': if(@percent < 0.25, 'RED', if(@percent < 0.5, 'YELLOW', 'GREEN')),
								'visible': if(@percent < 0.75, true, false),
							));
						}
					} else {
						update_bar(@p, array('percent': 1.0, 'color': 'GREEN', 'visible': false));
					}
				}
			});
		});
	}
));
