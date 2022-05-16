register_command('hoops', array(
	description: 'Creates a game of basketball in a hoops region.',
	usage: '/hoops',
	permission: 'command.hoops',
	tabcompleter: closure(return(array())),
	executor: closure(@alias, @sender, @args, @info) {
		@action = array_get(@args, 0, 'start');
		include('core.library/game.ms');
		switch(@action) {
			case 'start':
				@regions = sk_current_regions();
				if(!@regions || !string_contains_ic(@regions[-1], 'hoops')) {
					die(color('red').'You must be in the hoops region.');
				}
				@region = @regions[-1];
				if(import(@region)) {
					die(color('red').'Already running.');
				}
				_hoops_create();
				_hoops_add_players();
				_hoops_equip_players();
				_hoops_queue();
				broadcast(player(). ' started Hoops!', all_players(pworld()));

			default:
				return(false);
		}
	}
));
