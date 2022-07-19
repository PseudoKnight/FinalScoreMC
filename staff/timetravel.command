register_command('timetravel', array(
	description: 'Sets the world\'s time of day with a smooth interpolation.'
		.' Time must be a number from 0-24000.',
	usage: '/time <time> [seconds=5]',
	permission: 'command.time',
	tabcompleter: closure(return(array())),
	executor: closure(@alias, @sender, @args) {
		if(!@args) {
			return(false);
		}
		@targetTime = integer(@args[0]) % 24000;
		@seconds = array_get(@args, 1, 5);

		if(@targetTime < 0) {
			die('Time must be a positive number.');
		}
		if(@seconds <= 0) {
			die('Seconds must be a positive number.');
		}

		@world = pworld();
		_time_travel(@world, @targetTime, @seconds * 20);
	}
));