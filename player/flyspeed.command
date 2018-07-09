register_command('flyspeed', array(
	'description': 'Changes your flyspeed.',
	'usage': '/flyspeed [speed]',
	'permission': 'command.fly',
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		return(array());
	},
	'executor': closure(@alias, @sender, @args, @info) {
		@speed = 0.1
		if(@args) {
			@speed = clamp(double(@args[0]), -1.0, 1.0);
		}
		set_pflyspeed(@speed);
		msg('Set your fly speed to '.@speed);
	}
));
