register_command('icon', array(
	'description': 'Sets an icon next to a player\'s name in chat.',
	'usage': '/icon <player> [icon]',
	'permission': 'command.icon',
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		return(array());
	},
	'executor': closure(@alias, @sender, @args, @info) {
		if(!@args) {
			return(false);
		}
		@player = @args[0];
		@pdata = _pdata(@player);
		if(array_size(@args) == 2) {
			@pdata['icon'] = colorize($);
			msg('Added icon: '.@pdata['icon']);
		} else if(array_index_exists(@pdata, 'icon')) {
			array_remove(@pdata, 'icon');
			msg('Removed icon.');
		}
		_store_pdata(@player, @pdata);
	}
));
