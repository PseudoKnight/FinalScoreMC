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
		if(array_size(@args) == 2) {
			@amount = @args[1];
			if(!is_integral(@amount) || @amount < 1) {
				die(color('gold').'Amount must be a positive integer.');
			}
		}
		try {
			pgive_item(array('name': to_upper(@args[0]), 'qty': @amount));
			msg(color('yellow').'You\'ve been given '.@amount.' of '.@args[0].'.');
		} catch(Exception @ex) {
			msg(color('red').'The item '.@args[0].' doesn\'t appear to exist.');
		}
	}
));
