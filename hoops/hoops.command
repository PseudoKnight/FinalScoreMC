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
		include('core.library/game.ms');
		switch(@args[0]) {
			case 'reload':
				if(!has_permission('command.hoops.reload')) {
					die(color('red').'No permission.');
				}
				if(import('hoops')) {
					_hoops_delete();
				}
				x_recompile_includes('core.library');

			case 'start':
				if(!sk_region_exists('hoops')) {
					die(color('red').'Hoops doesn\'t exist in this world.');
				}
				if(import('hoops')) {
					die(color('red').'Already running.');
				}
				_hoops_create();
				@count = _hoops_add_players();
				if(@count < 2) {
					_hoops_delete();
					die(color('red').'Not enough players.');
				}
				_hoops_equip_players();
				broadcast(player(). ' started Hoops!', all_players(pworld()));
				_hoops_queue(5);

			case 'practice':
				_hoops_ball_create();

			default:
				return(false);
		}
	}
));
