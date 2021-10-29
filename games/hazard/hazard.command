register_command('hazard', array(
	description: 'Starts a half-hazard game.',
	usage: '/hazard',
	tabcompleter:  closure(return(array())),
	executor: closure(@alias, @sender, @args, @info) {
		include_dir('core.library');
		@game = import('hazard');
		if(!@game) {
			@game = _hazard_create();
		} else {
			die(color('gold').'Already running!');
		}
		_hazard_start(@game);
	},
));
