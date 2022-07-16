register_command('timetravel', array(
	description: 'Sets the world\'s time of day with a smooth interpolation.'
		.' Time must be a number from 0-24000. Speed is a tick multiplier.',
	usage: '/time <time> <speed>',
	permission: 'command.time',
	tabcompleter: closure(return(array())),
	executor: closure(@alias, @sender, @args) {
		if(array_size(@args) < 2) {
			return(false);
		}
		@targetTime = integer(@args[0]) % 24000;
		@tickStep = integer(@args[1]);
		@world = pworld();
		set_interval(50, closure(){
			@time = get_world_time(@world) + @tickStep;
			if(@time >= @targetTime + @tickStep) {
				@time -= 24000;
			}
			if(@time >= @targetTime) {
				@time = @targetTime;
				clear_task();
			}
			set_world_time(@world, @time);
		});
	}
));