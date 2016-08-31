if(!import('timers')) {
	@timers = get_value('session.timers')
	if(!@timers) {
		@timers = associative_array();
	} else {
		clear_value('session.timers');
	}
	export('timers', @timers);
}

register_command('timer', array(
	'description': 'Handles time trials for speed runs.',
	'usage': '/timer <start|stop> <id> <player>',
	'permission': 'command.timer',
	'executor': closure(@alias, @sender, @args, @info) {
		include('commands.library/timer.ms');
	});
);

// Calculate trophies
bind(player_join, null, null, @event) {
	queue_push(closure(){
		try {
			@top = get_value('times');
			for(@i = 0, @i < 10, @i++) {
				if(@top[@i][0] == player()) {
					@pstate = _pstate(player());
					@rank = '&e\u278A';
					switch(@i) {
						case 1:
							@rank = '&e\u278B';
						case 2:
							@rank = '&e\u278C';
						case 3:
							@rank = '\u278D';
						case 4:
							@rank = '\u278E';
						case 5:
							@rank = '\u278F';
						case 6:
							@rank = '\u2790';
						case 7:
							@rank = '\u2791';
						case 8:
							@rank = '\u2792';
						case 9:
							@rank = '\u2793';
					}
					if(!array_index_exists(@pstate, 'trophies')) {
						@pstate['trophies'] = array();
					}
					@pstate['trophies'][] = @rank.' \u231B Time Trials';
					break();
				}
			}
		} catch(PlayerOfflineException @ex) {
			// left soon after joining
		}
	}, 'trophies');
}
