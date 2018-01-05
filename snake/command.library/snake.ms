register_command('snake', array(
	'description': 'Starts or gets statistics for Snake.',
	'usage': '/snake',
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		if(array_size(@args) == 1) {
			return(_strings_start_with_ic(array('top', 'resetstats'), @args[-1]));
		}
		return(array());
	},
	'executor': closure(@alias, @sender, @args, @info) {
		if(!@args) {
			if(queue_running('snake_cleanup')) {
				die(color('gold').'The game is still resetting.');
			}
			if(array_contains(all_virtualchests(), 'snake')
			|| array_contains(get_scoreboards(), 'snake')) {
				die(color('gold').'Already running.');
			}
			include('../core.library/menu.ms');
			_snake_menu();
			die();
		}
		switch(@args[0]) {
			case 'top':
			case 'stats':
				@top = get_value('snake.endless.top');
				if(!@top) {
					die(color('gold').'There are no top scores.. yet!');
				}
				msg(color('green').color('bold').'Top Snakes [Endless Mode]');
				@i = 0;
				@size = min(20, array_size(@top));
				do {
					@name = _pdata_by_uuid(@top[@i]['uuid'])['name'];
					msg(color('green').'['.@top[@i]['value'].'] '.color('white').@name);
				} while(++@i < @size);
			
			case 'resetstats':
				if(!has_permission('group.moderator')) {
					die(color('gold').'You do not have permission.');
				}
				foreach(@key: @value in get_values('snake.endless')) {
					clear_value(@key);
				}
				msg(color('green').'Reset stats.');
				
			case 'reload':
				if(!has_permission('group.moderator')) {
					die(color('gold').'You do not have permission.');
				}
				if(queue_running('snake_cleanup')) {
					die(color('gold').'The game is still resetting.');
				}
				if(array_contains(all_virtualchests(), 'snake')
				|| array_contains(get_scoreboards(), 'snake')) {
					die(color('gold').'Already running.');
				}
				x_recompile_includes('../core.library');
				msg(color('green').'Done!');
				
			case 'end':
				if(!has_permission('group.moderator')) {
					die(color('gold').'You do not have permission.');
				}
				if(queue_running('snake_cleanup')) {
					die(color('gold').'The game is still resetting.');
				}
				include('../core.library/game.ms');
				_snake_cleanup(import('snake'));
				msg(color('green').'Done!');
			
			default:
				return(false);
		}
	}
));
