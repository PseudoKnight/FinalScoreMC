register_command('v', array(
	description: 'Toggles you to/from Spectator mode.',
	usage: '/v',
	permission: 'command.vanish',
	tabcompleter: closure(@alias, @sender, @args, @info) {
		return(array());
	},
	executor: closure(@alias, @sender, @args, @info) {
		if(pmode() == 'SPECTATOR') {
			@worlds = _worlds_config();
			set_pmode(@worlds[pworld()]['mode']);
		} else {
			set_pmode('SPECTATOR');
		}
	}
));
