register_command('exit', array(
	description: 'Sets an player\'s server exit message.',
	usage: '/exit <message>',
	tabcompleter: closure(@alias, @sender, @args, @info) {
		return(array());
	},
	executor: closure(@alias, @sender, @args, @info) {
		@msg = array_implode(@args);
		if(!@msg) {
			die('Enter a message to be displayed when exiting the server.');
		} else if(length(@msg) > 88) {
			die('Exit messages must be 88 or less characters.');
		}
	
		@pdata = _pdata(player());
		@pdata['exit'] = @msg;
		_store_pdata(player(), @pdata);
		msg(colorize('&7Set server exit message to: '));
		msg(_timestamp().colorize('&4\u00ab &o'._colorname().'&o'.player().'&e&o '.@msg));
	}
));
