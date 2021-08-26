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
		
		include_dir('core.library');
		@game = _worms_create(@args[0]);
		_generator_create('dungeon_v1', 'dirt', @game['region'], @game['world'], time(), closure(@start, @end, @spawns){
			@game['spawns'] = @spawns;
			_worms_start(@game);
		});
	}
));
