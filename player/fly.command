register_command('fly', array(
	'description': 'Changes or toggles flight mode.',
	'usage': '/fly [<player> <on|off>]',
	'permission': 'command.fly',
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		if(array_size(@args) == 2) {
			return(_strings_start_with_ic(array('on', 'off'), @args[-1]));
		}
	},
	'executor': closure(@alias, @sender, @args, @info) {
		if(!@args) {
			if(phas_flight()) {
				set_pflight(player(), 0);
				msg(color('green').'Turned off flying.');
			} else {
				set_pflight(player(), 1);
				msg(color('green').'Turned on flying.');
			}
		} else if(array_size(@args) == 1) {
			return(false);
		} else {
			@player = _find_player(@args[0]);
			if(@player != player() && !has_permission('command.fly.others')) {
				die(color('gold').'You do not have permission to change other player\'s flight mode.');
			}
			if(pworld(@player) != pworld()) {
				die(color('gold').'You cannot set the flight mode of a player in another world.');
			}
			switch(to_lower(@args[1])) {
				case '1':
				case 'on':
				case 'true':
					set_pflight(@player, 1);
					msg(color('green').'Turned on fly mode for '.@player.'.');
					tmsg(@player, color('yellow').player().' turned on fly mode on you.');

				case '0':
				case 'off':
				case 'false':
					set_pflight(@player, 0);
					msg(color('green').'Turned off fly mode for '.@player.'.');
					tmsg(@player, color('yellow').player().' turned off fly mode on you.');

				default:
					return(false);
			}
		}
	}
));
