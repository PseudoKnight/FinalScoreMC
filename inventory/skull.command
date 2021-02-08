register_command('skull', array(
	'description': 'Generates a skull with a specific account name.',
	'usage': '/skull <name>',
	'permission': 'command.skull',
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		return(array());
	},
	'executor': closure(@alias, @sender, @args, @info) {
		if(@args) {
			@pdata = null;
			try {
				@pdata = _pdata(@args[0]);
				if(array_index_exists(@pdata, 'noskull')) {
					die(color('red').'This player is tagged as having an invalid skull.');
				}
				pgive_item(array('name': 'PLAYER_HEAD', 'meta': array('owner': @pdata['name'])));
			} catch (NotFoundException @ex) {
				pgive_item(array('name': 'PLAYER_HEAD', 'meta': array('owner': @args[0])));
			}
		} else {
			return(false);
		}
	}
));
