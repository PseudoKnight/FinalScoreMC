register_command('runas', array(
	description: 'Runs a command for a player. Use -s flag to silence message.',
	usage: '/runas <player> [-s] <cmd>',
	permission: 'command.runas',
	executor: closure(@alias, @sender, @args, @info) {
		if(array_size(@args) < 2) {
			return(false);
		}
		@player = _find_player(@args[0]);
		@cmd = null;
		if(@args[1] === '-s') { // silent mode
			@cmd = array_implode(@args[2..-1]);
		} else {
			@cmd = array_implode(@args[1..-1]);
			tmsg(@player, color('GREEN').player().' ran this command for you:');
			tmsg(@player, color('GOLD').@cmd);
		}
		console("@cmd was run on @player", false);
		if(!call_alias(@cmd)) {
			sudo(@player, @cmd);
		}
	}
));
