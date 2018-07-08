register_command('hoops', array(
	'description': 'Creates, joins and manages a game of basketball.',
	'usage': '/hoops <start|join|reload>',
	'permission': 'command.hoops',
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		return(array());
	},
	'executor': closure(@alias, @sender, @args, @info) {
		if(!@args) {
			@args[0] = 'start';
		}
		
		if(!sk_region_exists('hoops')) {
			die(color('red').'Hoops doesn\'t exist in this world.');
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

			case 'join':
				include('core.library/game.ms');
				if(array_contains(get_bars(), 'hoops')) {
					die('Already running or in practice mode.');
				}
				if(!import('hoops')) {
					_hoops_create();
				}
				_hoops_player_add(player());
				broadcast(player(). ' joined Hoops!', all_players(pworld()));
				
			case 'start':
				include('core.library/game.ms');
				@game = import('hoops');
				if(!@game || array_size(@game['players']) < 2) {
					die('Not enough players.');
				} else if(array_contains(get_bars(), 'hoops')) {
					die('Already running.');
				}
				broadcast(player(). ' started Hoops!', all_players(pworld()));
				_hoops_queue(5);
			
			default:
				return(false);
		}
	}
));
