register_command('homeless', array(
	'description': 'Sets players\' current world (ie. outworld) as not existing anymore.',
	'usage': '/homeless [player]',
	'permission': 'command.homeless',
	'executor': closure(@alias, @sender, @args, @info) {
		if(@args) {
			@player = @args[0];
			@pdata = _pdata(@player);
			@pdata['homeless'] = true;
			_store_pdata(@player, @pdata);
			msg('Set '.@player.' to "homeless".');
		} else {
			foreach(@key: @pdata in get_values('uuids')) {
				if(array_index_exists(@pdata, 'world')
				&& (@pdata['world'] == 'outworld' || @pdata['world'] == 'outworld_nether' || @pdata['world'] == 'outworld_the_end')) {
					@pdata['homeless'] = true;
					@pdata['world'] = 'omega';
					store_value(@key, @pdata);
					msg('Set '.@pdata['name'].' to "homeless".');
				}
			}
		}
	}
));
