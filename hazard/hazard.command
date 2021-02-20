register_command('hazard', array(
	description: 'Creates, joins and starts a half-hazard game.',
	usage: '/hazard start',
	tabcompleter: closure(@alias, @sender, @args, @info) {
		if(array_size(@args) == 1) {
			return(_strings_start_with_ic(array('start'), @args[-1]));
		}
		return(array());
	},
	executor: closure(@alias, @sender, @args, @info) {
		include_dir('core.library');
		switch(array_get(@args, 0, null)) {
			case 'start':
				@game = import('hazard');
				if(!@game) {
					@game = _hazard_create();
				} else {
					die(color('gold').'Already running!');
				}
				_hazard_add_player(@sender, @game);
				msg('Preparing hazard map...');
				_hazard_start(@game);

			case 'reload':
				if(player() != '~console' && !pisop()) {
					die(color('red').'No permission.');
				}
				x_recompile_includes('core.library');
				msg(color('green').'Done!');

			default:
				return(false);
		}
	},
));
