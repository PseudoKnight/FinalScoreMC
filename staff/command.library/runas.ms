register_command('runas', array(
	'description': 'Runs a command for a player.',
	'usage': '/runas <player> <command>',
	'permission': 'command.runas',
	'executor': closure(@alias, @sender, @args, @info) {
		if(array_size(@args) < 2) {
			return(false);
		}
		@player = _find_player(@args[0]);
		@cmd = @args[1];
		if(substr(@cmd, 0, 2) === '-s') {
			@cmd = substr(@cmd, 3);
		} else {
			tmsg(@player, color('a').player().' ran this command for you:');
			tmsg(@player, color('6').@cmd);
		}
		console('\''.@cmd.'\' was run on '.@player, false);
		scriptas(@player,
			if(!call_alias(@cmd)) {
				sudo(@cmd);
			}
		)
	}
));
