register_command('unshare', array(
	'description': 'Unshare horses (and other things) with friends.',
	'usage': '/unshare <player> <sharable[s]>',
	'settabcompleter': closure(@alias, @sender, @args, @info) {
		if(array_size(@args) > 1) {
			return(_strings_start_with_ic(array('horses'), @args[-1]));
		}
	},
	'executor': closure(@alias, @sender, @args, @info) {
		@shareables = array('horses');
		@types = @args[1..-1];
		foreach(@type in @types) {
			if(!array_contains(@shareables, @type)) {
				die(color('red').'Unknown type: '.@type.'\nShareable: '.@shareables);
			}
		}
		try {
			@player = player(@args[0]);
		} catch(PlayerOfflineException @ex) {
			if(get_value('players', to_lower(@args[0]))) {
				@player = @args[0];
			} else {
				die('Unknown player.');
			}
		}
	
		@pdata = _pdata(player());
		if(!array_index_exists(@pdata, 'shared') || !array_index_exists(@pdata['shared'], @player)) {
			die(color('gold').'You are not sharing anything with this player.');
		}
		foreach(@type in @types) {
			if(!array_contains(@pdata['shared'][@player], @type)) {
				die(color('gold').'You are not sharing '.@type.' with '.@player);
			} else {
				array_remove_values(@pdata['shared'][@player], @type);
				if(array_size(@pdata['shared'][@player]) < 1) {
					array_remove(@pdata['shared'], @player);
					if(array_size(@pdata['shared']) < 1) {
						array_remove(@pdata, 'shared');
					}
				}
			}
		}
		_store_pdata(player(), @pdata);
		msg(color('green').'You are no longer sharing '.array_implode(@types, ' and ').' with '.@player.'.');
	
		@pdata = _pdata(@player);
		if(!array_index_exists(@pdata, 'shared') || !array_index_exists(@pdata['shared'], player())) {
			die(color('gold').'They are not sharing anything with you.');
		}
		foreach(@type in @types) {
			if(!array_contains(@pdata['shared'][player()], @type)) {
				die(color('gold').'They are not sharing '.@type.' with you.');
			} else {
				array_remove_values(@pdata['shared'][player()], @type);
				if(array_size(@pdata['shared'][player()]) < 1) {
					array_remove(@pdata['shared'], player());
					if(array_size(@pdata['shared']) < 1) {
						array_remove(@pdata, 'shared');
					}
				}
			}
		}
		_store_pdata(@player, @pdata);
		if(ponline(@player)) {
			tmsg(@player, color('green').player().' is no longer sharing '.array_implode(@types, ' and ').' with you.');
		}
	}
));
