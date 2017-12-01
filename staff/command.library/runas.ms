register_command('runas', array(
	'description': 'Runs a command for a player.',
	'usage': '/runas <player> <cmd>',
	'permission': 'command.runas',
	'executor': closure(@alias, @sender, @args, @info) {
		if(array_size(@args) < 2) {
			return(false);
		}
		@player = _find_player(@args[0]);
		if(@args[1] === '-s') {
			@cmd = array_implode(@args[2..-1]);
		} else {
			@cmd = array_implode(@args[1..-1]);
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
