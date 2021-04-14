register_command('frogware', array(
	description: 'Joins and starts FrogWare.',
	usage: '/frogware <join|start> [points]',
	tabcompleter: closure(@alias, @sender, @args, @info) {
		if(array_size(@args) == 1) {
			if(has_permission('group.engineer')) {
				return(_strings_start_with_ic(array('join', 'start', 'stop'), @args[-1]));
			} else {
				return(_strings_start_with_ic(array('join', 'start'), @args[-1]));
			}
		}
		return(array());
	},
	executor: closure(@alias, @sender, @args, @info) {
		if(!@args) {
			return(false);
		}
		include_dir('core.library');
		switch(@args[0]) {
			case 'join':
				if(!sk_region_exists('custom', 'frogware')) {
					die(color('gold').'Define the frogware region first.');
				}
				_fw_add_player(player());

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
				include_dir('tasks.library');
				_fw_startgame(@points);

			case 'stop':
				queue_clear('fw');
				queue_clear('fw2');
				queue_clear('fw3');
				remove_scoreboard('fw');
				unbind('fwdamage');
				unbind('fwtask');
				_remove_activity('frogware');
				msg('Stopped.');

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
		}
	}
));
