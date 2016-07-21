if(!import('timers')) {
	@ignorelist = get_value('session.timers')
	if(!@ignorelist) {
		@ignorelist = associative_array();
	} else {
		clear_value('session.timers');
	}
	export('timers', @ignorelist);
}

register_command('timer', array(
	'description': 'Handles time trials for speed runs.',
	'usage': '/timer <start|stop> <id> <player>',
	'permission': 'command.timer',
	'executor': closure(@alias, @sender, @args, @info) {
		include('commands.library/timer.ms');
	});
);
