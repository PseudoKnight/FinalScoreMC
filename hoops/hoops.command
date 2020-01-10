register_command('hoops', array(
	'description': 'Creates, joins and manages a game of basketball.',
	'usage': '/hoops',
	'permission': 'command.hoops',
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		return(array());
	},
	'executor': closure(@alias, @sender, @args, @info) {
		if(!@args) {
			@args[0] = 'start';
		}
		
		switch(@args[0]) {
			case 'reload':
				if(!has_permission('command.hoops.reload')) {
					die(color('red').'No permission.');
				}
				if(import('hoops')) {
					include('core.library/game.ms');
					_hoops_delete();
				}
				x_recompile_includes('core.library');
				
			case 'start':
				if(!sk_region_exists('hoops')) {
					die(color('red').'Hoops doesn\'t exist in this world.');
				}
				include('core.library/game.ms');
				if(!import('hoops')) {
					_hoops_create();
				} else {
					die(color('red').'Already running.');
				}
				@players = array();
				foreach(@p in all_players(pworld())) {
					if(array_contains(sk_current_regions(@p), 'hoops')) {
						@players[] = @p;
					}
				}
				if(array_size(@players) < 2) {
					die('Not enough players.');
				} else if(array_contains(get_bars(), 'hoops')) {
					die('Already running.');
				}
				foreach(@p in @players) {
					_hoops_player_add(@p);
				}
				broadcast(player(). ' started Hoops!', all_players(pworld()));
				_hoops_queue(5);
			
			default:
				return(false);
		}
	}
));
