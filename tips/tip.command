register_command('tip', array(
	'description': 'Displays a random tip.',
	'usage': '/tip',
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		return(array());
	},
	'executor': closure(@alias, @sender, @args, @info) {
		@tips = import(_world_group(pworld()).'-tips', array('Sometimes there\'s no more tips.'));
		@tip = array_get_rand(@tips);
		msg(colorize('&7TIP: &r'.@tip));
	}
));
