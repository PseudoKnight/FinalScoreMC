register_command('frogware', array(
	'description': 'Joins and starts FrogWare.',
	'usage': '/frogware <join|start|forcestop> [points]',
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		if(array_size(@args) == 1) {
			return(_strings_start_with_ic(array('join', 'start', 'forcestop'), @args[-1]));
		}
		return(array());
	},
	'executor': closure(@alias, @sender, @args, @info) {
		if(!@args) {
			return(false);
		}
		switch(@args[0]) {
			case 'join':
				if(!sk_region_exists('custom', 'frogware')) {
					die(color('gold').'Define the frogware region first.');
				}
				if(!array_contains(get_scoreboards(), 'fw')) {
					create_scoreboard('fw');
					create_objective('score', 'DUMMY', 'fw');
					create_team('losers', 'fw');
					create_team('winners', 'fw');
					set_objective_display('score', array('slot': 'SIDEBAR', 'displayname': color('a').color('l').'Get Ready!'), 'fw');
					set_team_display('winners', array('prefix': color(10)), 'fw');
					set_team_display('losers', array('prefix': color(15)), 'fw');
				}
				set_pscoreboard(player(), 'fw');
				team_add_player('losers', player(), 'fw');
				include('../includes.library/frogware.ms');

				@scores = array();
				foreach(@p in all_players('custom')) {
					if(_fw_player(@p)) {
						array_push(@scores, get_pscore('score', @p, 'fw'));
					}
				}
				set_pscore('score', player(), if(@scores, min(@scores), 0), 'fw');

				set_ploc(_fw_loc(-1));
				set_phunger(20);
				set_psaturation(5);
				set_phealth(20);
				_clear_pinv(player());

			case 'start':
				if(get_pscoreboard(player()) !== 'fw') {
					die(color('gold').'You haven\'t joined first.');
				}
				@points = 20;
				if(array_size(@args) == 2) {
					@points = integer(@args[1]);
				}
				if(queue_running('fw') || queue_running('fw2')) {
					die(color('gold').'Already running.');
				}
				_add_activity('frogware', 'FrogWare');
				include('../includes.library/frogware.ms');
				foreach(@p in all_players('custom')) {
					if(_fw_player(@p)) {
						set_pmode(@p, 'SURVIVAL');
						set_phunger(@p, 20);
						set_psaturation(@p, 5);
						set_phealth(@p, 20);
						_clear_pinv(@p);
					}
				}
				_fw_startgame(@points);

			case 'forcestop':
				queue_clear('fw');
				queue_clear('fw2');
				queue_clear('fw3');
				remove_scoreboard('fw');
				unbind('fwdamage');
				_remove_activity('frogware');

			default:
				msg(color('bold').'FROGWARE --------------');
				msg('| FrogWare is a game inspired by GarryWare,\n'
				.'| which is in turn inspired by WarioWare.\n'
				.'| Players get a random task every round that\n'
				.'| they have to complete in several seconds.\n'
				.'| They get a point for completing a task.\n'
				.'| First player to reach 25 points wins.');
				msg(color('bold').'FROGWARE COMMANDS -----');
				msg('/frogware join '.color('gray').'Joins the game');
				msg('/frogware start '.color('gray').'Starts the game');
				msg('/frogware forcestop '.color('gray').'(restricted) Stops the game');
		}
	}
));
