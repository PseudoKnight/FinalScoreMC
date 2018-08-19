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
		@index = -1;
		if(array_size(@args) > 2) {
			@amount = @args[-1];
			if(!is_integral(@amount) || @amount < 1) {
				@amount = 1;
			} else {
				@index = -2;
			}
		}
		@itemName = to_upper(array_implode(@args[cslice(1, @index)], '_'));
		try {
			pgive_item(@player, array('name': @itemName, 'qty': @amount));
			msg(color('yellow').'You\'ve been given '.@amount.' of '.@itemName.'.');
		} catch(Exception @ex) {
			msg(color('red').'The item '.@itemName.' doesn\'t appear to exist.');
		}
	}
));
