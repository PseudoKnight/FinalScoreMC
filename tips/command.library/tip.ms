register_command('tip', array(
	'description': 'Displays a random tip.',
	'usage': '/tip',
	'executor': closure(@alias, @sender, @args, @info) {
		@tips = import(_world_group(pworld()).'-tips', array('Sometimes there\'s no more tips.'));
		@tip = @tips[rand(array_size(@tips))];
		msg(colorize('&7TIP: &r'.@tip));
	}
));
