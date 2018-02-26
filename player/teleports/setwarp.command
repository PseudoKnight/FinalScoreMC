register_command('setwarp', array(
	'description': 'Sets a location for players to teleport to.',
	'usage': '/setwarp <warp_name>',
	'permission': 'command.setwarp',
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		return(array());
	},
	'executor': closure(@alias, @sender, @args, @info) {
		if(!@args) {
			return(false);
		}
		
		@warp = @args[0];
		if(reg_count('\\w', @warp) < 0) {
			die(color('gold').'This needs to be in alphanumeric characters.');
		}
		@loc = ploc();
		@loc = array(round(@loc[0], 1), @loc[1], round(@loc[2], 1), @loc[3], floor(@loc[4]), floor(@loc[5]));
		if(has_value('warp.'.@warp)) {
			try {
				if(function_exists('dm_delete_marker')) {
					dm_delete_marker('warps', 'warp.'.@warp);
				}
			} catch(Exception @ex) {
				// ignore
			}
		}
		store_value('warp.'.@warp, @loc);
		if(function_exists('dm_create_marker')) {
			dm_create_marker('warps', array('id': 'warp.'.@warp, 'label': 'WARP.'.to_upper(@warp), 'location': @loc, 'world': @loc[3], 'icon': 'star', 'persistent': true)); # radius is workaround for a bug
		}
		msg('Warp created.');
	}
));
