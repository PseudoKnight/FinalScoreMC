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
		@item = split(':', @args[0]);
		if(!is_numeric(@item[0])) {
			@item[0] = data_values(@item[0]);
		}
		if(is_null(@item[0])) {
			die(color('gold').'Unknown item name');
		}
		if(array_size(@item) == 1) {
			@item[1] = 0;
		}
		@amount = 1;
		if(array_size(@args) == 2) {
			@amount = @args[1];
			if(!is_integral(@amount) || @amount < 1) {
				die(color('gold').'Amount must be a positive integer.');
			}
		}
		try {
			pgive_item(@item[0].':'.@item[1], @amount);
			msg(color('yellow').'You\'ve been given '.@amount.' '.data_name(@item[0].':'.@item[1]).'.');
		} catch(Exception @ex) {
			msg(color('red').'The item '.@args[0].' doesn\'t appear to exist.');
		}
	}
));
