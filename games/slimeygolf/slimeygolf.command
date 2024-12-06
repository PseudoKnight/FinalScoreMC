register_command('slimeygolf', array(
	description: 'Starts a game of SlimeyGolf.',
	usage: '/slimeygolf',
	tabcompleter: _create_tabcompleter(
		array('test', 'set'),
		array('<set': array('bounciness', 'slickness', 'slimeblock_bounciness', 'booster_acceleration', 'booster_dampener', 'fan_vertical_acceleration')),
		closure(@alias, @sender, @args) {
			if(@args[0] === 'set' && !@args[2]) {
				@physics = import('slimeygolf.physics');
				if(@physics && array_index_exists(@physics, @args[1])) {
					return(array(@physics[@args[1]]));
				}
			}
		}
	),
	executor: closure(@alias, @sender, @args, @info) {
		include('basic.library/game.ms');
		@loc = get_command_block();
		if(!@loc) {
			@loc = ploc();
		}
		@world = @loc['world'];
		if(_is_survival_world(@world)) {
			die(color('gold').'Not allowed in this world.');
		}
		@course = _get_course(@loc);
		if(!@course) {
			die(color('gold').'No Slimey Golf course here.');
		}
		@test = false;
		if(@args) {
			if(@args[0] === 'test') {
				@test = true;
			} else if(@args[0] === 'set') {
				if(array_size(@args) < 3) {
					die(color('gold').'Expected more arguments.');
				}
				if(!has_permission('group.moderator')) {
					die(color('gold').'No permission to modify the physics.');
				}
				@physics = import('slimeygolf.physics');
				if(!@physics) {
					die(color('gold').'Game not running.');
				}
				@setting = @args[1];
				@current = @physics[@setting];
				@new = double(@args[2]);
				@physics[@setting] = @new;
				die(color('green')."Set @setting from @current to @new");
			} else {
				die(color('gold').'Invalid command.');
			}
		}
		if(array_contains(get_scoreboards(), @course)) {
			die(color('gold').'This game is already active.');
		}
		_start_game(@course, @world, @test);
	}
));
