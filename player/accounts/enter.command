register_command('enter', array(
	description: 'Sets an player\'s server enter message.',
	usage: '/enter <message>',
	tabcompleter: closure(@alias, @sender, @args, @info) {
		return(array());
	},
	executor: closure(@alias, @sender, @args, @info) {
		@msg = array_implode(@args);
		if(!@msg) {
			die('Enter a message to be displayed when entering the server.');
		} else if(length(@msg) > 88) {
			die('Enter messages must be 88 or less characters.');
		}

		@pdata = _pdata(player());
		@escapedMessage = replace(@msg, '\\', '\\\\');
		@escapedMessage = replace(@escapedMessage, '"', '\\u0022');
		@pdata['enter'] = @escapedMessage;
		_store_pdata(player(), @pdata);
		msg(colorize('&7Set server enter message to: '));
		@pre = _timestamp().color('dark_green').'\u00bb ';
		@name = _colorname().color('italic').player();
		_tellraw(array(player()), array(array('plain', @pre), array('hover', @name, 'Last played: Now'), '&e&o '.@escapedMessage));
	}
));
