register_command('snake', array(
	description: 'Starts or gets statistics for Snake.',
	usage: '/snake',
	tabcompleter: _create_tabcompleter(
		array(
			'group.admin': array('top', 'resetstats', 'start', 'end'),
			'group.engineer': array('top', 'start', 'end'),
			null: array('top', 'start')),
		array('<top': array('endless', 'gluttony')),
	),
	executor: closure(@alias, @sender, @args, @info) {
		switch(array_get(@args, 0, 'start')) {
			case 'top':
				@mode = 'endless';
				if(array_size(@args) > 1) {
					@mode = @args[1];
				}
				@top = get_value('snake', @mode, 'top');
				if(!@top) {
					die(color('gold').'There are no top scores.. yet!');
				}
				msg(color('green').color('bold').'Top Snakes ('.@mode.')');
				@i = 0;
				@size = min(19, array_size(@top));
				do {
					@name = _pdata_by_uuid(@top[@i]['uuid'])['name'];
					msg(color('green').'['.@top[@i]['value'].'] '.color('white').@name);
				} while(++@i < @size)
			
			case 'resetstats':
				if(!has_permission('group.admin')) {
					die(color('gold').'You do not have permission.');
				}
				foreach(@key: @value in get_values('snake.endless')) {
					clear_value(@key);
				}
				msg(color('green').'Reset stats.');

			case 'start':
				if(queue_running('snake_cleanup')) {
					die(color('gold').'The game is still resetting.');
				}
				if(has_inventory('snake')
				|| array_contains(get_scoreboards(), 'snake')) {
					die(color('gold').'Already running.');
				}
				include('core.library/menu.ms');
				_snake_menu();
				
			case 'end':
				if(!has_permission('group.engineer')) {
					die(color('gold').'You do not have permission.');
				}
				if(queue_running('snake_cleanup')) {
					die(color('gold').'The game is still resetting.');
				}
				include('core.library/game.ms');
				_snake_cleanup(import('snake'));
				msg(color('green').'Done!');
			
			default:
				return(false);
		}
	}
));
