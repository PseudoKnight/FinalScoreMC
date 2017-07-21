register_command('warp', array(
	'description': 'Teleports you to a predefined location.',
	'usage': '/warp [warp_name] [player]',
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		return(array());
	},
	'executor': closure(@alias, @sender, @args, @info) {
		if(!@args) {
			run('/warps list');
			die();
		}
		
		if(array_size(@args) == 2) {
			if(@loc = get_command_block()) {
				@player = @args[0];
				@warpid = @args[1];
				if(@loc['world'] != pworld(@player)) {
					die('This commandblock cannot teleport players in other worlds.');
				}
			} else {
				die(color('gold').'You cannot teleport others.');
			}
		} else {
			 @player = player();
			 @warpid = @args[0];
		}
		
		@warp = get_value('warp.'.to_lower(@warpid));
		if(!@warp) {
			die(color('gold').'That warp does not exist.');
		}
		
		include('../includes.library/teleports.ms');
		if(!_allows_teleports(pworld(@player))) {
			die(color('gold').'You cannot warp in this world.');
		}
		
		_warmuptp(@player, @warp, @warp[3] == 'custom');
	}
));
