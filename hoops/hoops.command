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
				x_recompile_includes('core.library');
				
			case 'join':
				include('core.library/game.ms');
				if(!import('hoops')) {
					_hoops_create();
				}
				_hoops_player_add(player());
				broadcast(player(). ' joined Hoops!', all_players(pworld()));
				
			case 'start':
				include('core.library/game.ms');
				broadcast(player(). ' started Hoops!', all_players(pworld()));
				_hoops_queue(7);
			
			default:
				return(false);
		}
	}
));
