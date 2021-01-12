register_command('worms', array(
	'description': 'Creates a worms game.',
	'usage': '/worms <region>',
	'permission': 'command.worms',
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		return(array());
	},
	'executor': closure(@alias, @sender, @args, @info) {
		if(@args[0] == 'reload') {
			@count = x_recompile_includes('core.library');
			die(color('green').'Recompiled '.@count.' scripts');
		}
		
		@game = import('worms'.@args[0]);
		if(@game) {
			die(color('gold').'Worms is already running.');
		}
		
		include('core.library/events.ms');
		include('core.library/game.ms');
		include('core.library/player.ms');
		include('core.library/projectile.ms');
		include('core.library/segment.ms');
		include('core.library/worm.ms');
		@game = _worms_create(@args[0]);
		_generator_create('dungeon', 'dirt', @game['region'], @game['world'], time(), closure(@start, @end, @spawns){
			@game['spawns'] = @spawns;
			_worms_start(@game);
		});
	}
));
