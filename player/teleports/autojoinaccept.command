register_command('autojoinaccept', array(
	description: 'Accepts a teleport request.',
	usage: '/autojoinaccept <on|off>',
	aliases: array('autojoin'),
	tabcompleter: closure(@alias, @sender, @args, @info) {
		return(array());
	},
	executor: closure(@alias, @sender, @args, @info) {
		@pdata = _pdata(player());
		if(!@args) {
			if(array_index_exists(@pdata, 'joinaccept')) {
				array_remove(@pdata, 'joinaccept');
				msg(colorize('Toggled auto-join-accept &c&loff&r.'));
			} else {
				@pdata['joinaccept'] = true;
				msg(colorize('Toggled auto-join-accept &a&lon&r.'));
			}
		} else {
			switch(@args[0]) {
				case 'true':
				case 'on':
				case 'enable':
				case '1':
					if(array_index_exists(@pdata, 'joinaccept')) {
						msg(colorize('Auto-join-accept is already &a&lon&r.'));
					} else {
						@pdata['joinaccept'] = true;
						msg(colorize('Set auto-join-accept &a&lon&r.'));
					}
				case 'false':
				case 'off':
				case 'disable':
				case '0':
					if(array_index_exists(@pdata, 'joinaccept')) {
						array_remove(@pdata, 'joinaccept');
						msg(colorize('Set auto-join-accept &c&loff&r.'));
					} else {
						msg(colorize('Auto-join-accept already &c&loff&r.'));
					}
				default:
					return(false);
			}
		}
		_store_pdata(player(), @pdata);
	}
));
