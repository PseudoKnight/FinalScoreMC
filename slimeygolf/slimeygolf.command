register_command('slimeygolf', array(
	'description': 'Starts a game of SlimeyGolf.',
	'usage': '/slimeygolf',
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		return(array());
	},
	'executor': closure(@alias, @sender, @args, @info) {
		include('basic.library/game.ms');
		@loc = get_command_block();
		if(!@loc) {
			@loc = ploc();
		}
		if(_is_survival_world(@loc['world'])) {
			die(color('gold').'Not allowed in this world.');
		}
		@course = _get_course(@loc);
		if(!@course) {
			die(color('gold').'No Slimey Golf course here.');
		}
		if(array_contains(get_scoreboards(), @course.'1')) {
			die(color('gold').'This game is already active.');
		}
		_start_game(@course, @loc);
	}
));
