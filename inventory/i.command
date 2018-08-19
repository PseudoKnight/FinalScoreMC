register_command('i', array(
	'description': 'Creates a new item.',
	'usage': '/i <id:data> [quantity]',
	'permission': 'command.items',
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		return(array());
	},
	'executor': closure(@alias, @sender, @args, @info) {
		if(!@args) {
			return(false);
		}
		@amount = 1;
		@index = -1;
		if(array_size(@args) > 1) {
			@amount = @args[-1];
			if(!is_integral(@amount) || @amount < 1) {
				@amount = 1;
			} else {
				@index = -2;
			}
		}
		@itemName = to_upper(array_implode(@args[cslice(0, @index)], '_'));
		try {
			pgive_item(array('name': @itemName, 'qty': @amount));
			msg(color('yellow').'You\'ve been given '.@amount.' of '.@args[0].'.');
		} catch(Exception @ex) {
			msg(color('red').'The item '.@itemName.' doesn\'t appear to exist.');
		}
	}
));
