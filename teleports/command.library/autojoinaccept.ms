register_command('autojoinaccept', array(
	'description': 'Accepts a teleport request.',
	'usage': '/autojoinaccept',
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		return(array());
	},
	'executor': closure(@alias, @sender, @args, @info) {
		@pdata = _pdata(player());
		if(array_index_exists(@pdata, 'joinaccept')) {
			array_remove(@pdata, 'joinaccept');
			msg(colorize('Toggled auto-join-accept &c&loff&r.'));
		} else {
			@pdata['joinaccept'] = true;
			msg(colorize('Toggled auto-join-accept &a&lon&r.'));
		}
		_store_pdata(player(), @pdata);
	}
));
