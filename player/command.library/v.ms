register_command('v', array(
	'description': 'Toggles you to/from Spectator mode.',
	'usage': '/v',
	'permission': 'command.vanish',
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		return(array());
	},
	'executor': closure(@alias, @sender, @args, @info) {
		if(pmode() == 'SPECTATOR') {
			@worlds = _worlds_config();
			if(extension_exists('CHDynmap')) {
				dm_set_pvisible(true);
			}
			set_pmode(@worlds[pworld()]['mode']);
		} else {
			if(extension_exists('CHDynmap')) {
				dm_set_pvisible(false);
			}
			set_pmode('SPECTATOR');
		}
	}
));
