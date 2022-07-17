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
		@currentTime = get_world_time(@world);
		if(@targetTime <= @currentTime) {
			@targetTime += 24000;
		}
		@timeDelta = @targetTime - @currentTime;
		@steps = ceil(@seconds * 20);

		@daylightCycle = get_gamerule(@world, 'DODAYLIGHTCYCLE');
		set_gamerule(@world, 'DODAYLIGHTCYCLE', false);

		@step = array(0);
		set_interval(50, closure(){
			@step[0]++;
			@interp = -(cos(math_const('PI') * @step[0] / @steps) - 1) / 2;
			@time = @currentTime + integer(round(@timeDelta * @interp));
			set_world_time(@world, @time);
			if(@step[0] == @steps) {
				set_gamerule(@world, 'DODAYLIGHTCYCLE', @daylightCycle);
				clear_task();
			}
		});
	}
));