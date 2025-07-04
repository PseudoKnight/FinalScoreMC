@tracks = array();
foreach(@track in array_keys(get_values('track'))) {
	@tracks[] = split('.', @track)[-1];
}

register_command('race', array(
	description: 'Commands for managing and participating in races.',
	usage: '/race <start|join> <track>',
	tabcompleter: _create_tabcompleter(
		array(
			'group.admin': array('join', 'start', 'end', 'reload'),
			'group.builder': array('join', 'start', 'end'),
			null: array('join', 'start')),
		@tracks,
	),
	executor: closure(@alias, @sender, @args, @info) {
		if(array_size(@args) < 2) {
			return(false);
		}
		@action = @args[0];
		@id = @args[1];
		include('core.library/game.ms');
		switch(@action) {
			case 'start':
				@race = _race_create_and_join(@id);
				_race_countdown(@race);
				
			case 'join':
				_race_create_and_join(@id);
			
			case 'end':
				if(!has_permission('group.builder')) {
					die(color('gold').'Do not have permission.');
				}
				@race = import('race'.@id);
				_race_end(@race);
				
			case 'reload':
				if(!has_permission('group.admin')) {
					die(color('gold').'Do not have permission.');
				}
				@num = x_recompile_includes('core.library');
				msg(color('green').'Recompiled '.@num.' files.');
				
			default:
				return(false);
		}
	}
));
