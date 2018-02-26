register_command('where', array(
	'description': 'Lists which players are in which worlds.',
	'usage': '/where',
	'aliases': array('mvw'),
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		return(array());
	},
	'executor': closure(@alias, @sender, @args, @info) {
		@worlds = _worlds_config();
		@list = associative_array();
		foreach(@player in all_players()) {
			@world = @worlds[pworld(@player)]['name'];
			if(!array_index_exists(@list, @world)) {
				@list[@world] = array();
			}
			@list[@world][] = display_name(@player);
		}
		foreach(@world: @players in @list) {
			msg(@world.': '.array_implode(@players));
		}
	}
));
