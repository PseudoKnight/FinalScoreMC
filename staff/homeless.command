register_command('homeless', array(
	'description': 'Sets players\' current world (ie. outworld) as not existing anymore.',
	'usage': '/homeless [player]',
	'permission': 'command.homeless',
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		return(array());
	},
	'executor': closure(@alias, @sender, @args, @info) {
		if(@args) {
			@player = @args[0];
			@pdata = _pdata(@player);
			@pdata['homeless'] = true;
			_store_pdata(@player, @pdata);
			msg('Set '.@player.' to "homeless".');
		} else {
			foreach(@key: @pdata in get_values('uuids')) {
				if(array_index_exists(@pdata, 'world') && string_starts_with(@pdata['world'], 'outworld')) {
					@pdata['homeless'] = true;
					@pdata['world'] = 'psi';
					store_value(@key, @pdata);
					msg('Set '.@pdata['name'].' to "homeless".');
				} else if(string_starts_with(string(_nested_array_get(@pdata, 'survival', 'loc', 3)), 'outworld')) {
					array_remove(@pdata['survival'], 'loc');
					store_value(@key, @pdata);
					msg('Removed outworld from survival world location for '.@pdata['name'].'.');
				}
			}
		}
	}
));
