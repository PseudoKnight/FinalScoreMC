register_command('homeless', array(
	description: 'Flags all players who were last in a world (or specified player).',
	usage: '/homeless [world|player]',
	permission: 'command.homeless',
	tabcompleter: closure(return(array())),
	executor: closure(@alias, @sender, @args, @info) {
		if(@args && !array_contains(get_worlds(), @args[0])) {
			@player = @args[0];
			@pdata = _pdata(@player);
			@pdata['homeless'] = true;
			_store_pdata(@player, @pdata);
			msg('Set '.@player.' to "homeless".');
		} else {
			@world = array_get(@args, 0, 'outworld');
			foreach(@key: @pdata in get_values('uuids')) {
				if(array_index_exists(@pdata, 'world') && string_starts_with(@pdata['world'], @world)) {
					@pdata['homeless'] = true;
					@pdata['world'] = 'psi';
					store_value(@key, @pdata);
					msg('Set '.@pdata['name'].' to "homeless".');
				} else if(array_index_exists(@pdata, 'survival') && array_index_exists(@pdata['survival'], 'loc')
				&& string_starts_with(@pdata['survival']['loc'][3], @world)) {
					array_remove(@pdata['survival'], 'loc');
					store_value(@key, @pdata);
					msg('Removed '.@world.' from survival world location for '.@pdata['name'].'.');
				}
			}
		}
	}
));
