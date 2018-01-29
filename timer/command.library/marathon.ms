register_command('marathon', array(
	'description': 'Creates a Marathon',
	'usage': '/marathon',
	'executor': closure(@alias, @sender, @args, @info) {
		// marathon join subcommand
		if(@args) {
		 	if(@args[0] != 'join') {
				return(false);
			}
			@marathon = import('marathon');
			if(@marathon) {
				if(!_psession(player())['activity']) {
					@marathon['players'][player()] = @marathon['courses'][0];
					msg(color('green').'Joined.');
				} else {
					msg(color('gold').'You appear to be playing another game.');
				}
			}
			return(true);
		}
		// else queue up the marathon
		// populate course list
		@coursedata = get_values('times');
		@courses = array_filter(@coursedata, closure(@key, @value){
			return(is_array(@value) && @key != 'times');
		});
		@courses = array_rand(@courses, array_size(@courses));
		@coursetimes = associative_array();
		foreach(@index: @course in @courses) {
			@name = split('.', @course)[1];
			@courses[@index] = @name;
			@coursetimes[@name] = null;
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
		
		_click_tell(all_players(pworld()), array('&7[Marathon] ', array('&b[JOIN] ', '/marathon join'), player().' queued up a marathon.'));
		
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
				foreach(@p in @players) {
					try(title(@p, '', @timer[0]));
				}
				die();
			}
			clear_task();
			
			// setup players
			@firstwarp = get_value('warp', @courses[0]);
			foreach(@p: @course in @players) {
				create_bar(@p, array('title': @p.': '.@course, 'color': 'GREEN'));
				bar_add_player(@p, @p);
				_set_pactivity(@p, 'marathon');
				set_ploc(@p, @firstwarp);
			}
			
			set_interval(1000, closure(){
				@time = time();
				if(array_size(@players) < 2) {
					clear_task();
					if(array_size(@players) == 1) {
						@lastplayer = array_keys(@players)[0];
						title(@lastplayer, 'Too fast!', '');
						_worldmsg(pworld(), color('bold').@lastplayer.' left all other players in their dust.');
						remove_bar(@lastplayer);
						_set_pactivity(@lastplayer, null);
					}
					export('marathon', null);
					die();
				}
				foreach(@p: @course in @players) {
					try {
						if(@marathon['times'][@course]) {
							if(@time > @marathon['times'][@course] + 120000) {
								if(ponline(@p)) {
									title(@p, 'Too slow!', '');
								}
								array_remove(@marathon['players'], @p);
								remove_bar(@p);
								_set_pactivity(@p, null);
							} else {
								@percent = 1.0 - (@time - @marathon['times'][@course]) / 120000;
								update_bar(@p, array('percent': @percent, 'color': if(@percent < 0.25, 'RED', 'YELLOW')));
							}
						} else {
							update_bar(@p, array('percent': @percent, 'color': 'GREEN'));
						}
					} catch(NotFoundException @ex) {
						remove_bar(@p);
					}
				}
			});
		});
	}
));
