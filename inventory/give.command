register_command('give', array(
	'description': 'Gives a new item to a player.',
	'usage': '/give <player> <id> [quantity]',
	'permission': 'command.items.others',
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		return(array());
	},
	'executor': closure(@alias, @sender, @args, @info) {
		if(array_size(@args) < 2) {
			return(false);
		}
		@player = _find_player(@args[0]);
		@amount = 1;
		if(array_size(@args) == 3) {
			@amount = @args[1];
			if(!is_integral(@amount) || @amount < 1) {
				die(color('gold').'Amount must be a positive integer.');
			}
		}
		try {
			pgive_item(@player, array('name': to_upper(@args[1]), 'qty': @amount));
			msg(color('yellow').'You\'ve been given '.@amount.' of '.@args[1].'.');
		} catch(Exception @ex) {
			msg(color('red').'The item '.@args[1].' doesn\'t appear to exist.');
		}
	}
));
