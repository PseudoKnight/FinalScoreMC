register_command('noskull', array(
	'description': 'Flags a user as having an invalid skull that can cause lag.',
	'usage': '/noskull <player> [value]',
	'permission': 'command.noskull',
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		return(array());
	},
	'executor': closure(@alias, @sender, @args, @info) {
		if(!@args) {
			return(false);
		}
		@player = @args[0];
		@pdata = _pdata(@player);
		if(array_size(@args) > 1 && @args[1] == 'false') {
			array_remove(@pdata, 'noskull');
			msg(color('green').'Unflagged user as having an invalid skull.');
		} else {
			@pdata['noskull'] = true;
			msg(color('green').'Flagged user as having an invalid skull.');
		}
		_store_pdata(@player, @pdata);
	}
));
