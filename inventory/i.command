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
		@itemName = array_implode(@args, ' ');
		@amount = 1;
		@meta = associative_array();

		@bracePos = string_position(@itemName, '{')
		@barPos = string_position(@itemName, '|')
		// yaml meta support
		if(@barPos > -1 && (@bracePos == -1 || @bracePos > @barPos)) {
			try {
				@meta = yml_decode(@itemName[cslice(@barPos + 1, length(@itemName) - 1)]);
			} catch(FormatException @ex) {
				die(color('red').'Invalid YAML for item meta: '.@itemName[cslice(@barPos + 1, length(@itemName) - 1)]);
			}
			@itemName = @itemName[cslice(0, @barPos - 1)];
		// json meta support
		} else if(@bracePos > -1) {
			try {
				@meta = json_decode(@itemName[cslice(@bracePos, length(@itemName) - 1)]);
			} catch(FormatException @ex) {
				die(color('red').'Invalid JSON for item meta: '.@itemName[cslice(@bracePos, length(@itemName) - 1)]);
			}
			@itemName = @itemName[cslice(0, @bracePos - 1)];
		// basic item quantity support
		} else if(array_size(@args) > 1) {
			@index = -1;
			if(is_integral(@args[-1]) && @args[-1] > 0) {
				@amount = integer(@args[-1]);
				@index = -2;
			}
			@itemName = array_implode(@args[cslice(0, @index)], '_');
		}
		try {
			pgive_item(array('name': to_upper(@itemName), 'qty': @amount, 'meta': @meta));
			msg(color('yellow').'You\'ve been given '.@amount.' of '.@itemName.'.');
		} catch(Exception @ex) {
			msg(color('red').'The item '.@itemName.' doesn\'t appear to exist.');
		}
	}
));
