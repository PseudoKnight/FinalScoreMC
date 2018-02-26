register_command('race', array(
	'description': 'Commands for managing and participating in races.',
	'usage': '/race <start|join> <track>',
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		return(array());
	},
	'executor': closure(@alias, @sender, @args, @info) {
		if(array_size(@args) < 2) {
			return(false);
		}
		@action = @args[0];
		@id = @args[1];
		include('core.library/game.ms');
		switch(@action) {
			case 'start':
				@race = _race_create_and_join(@id);
				set_entity_loc(puuid(), @race['lobby']);
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
				@num = x_recompile_includes('../core.library');
				msg(color('green').'Recompiled '.@num.' files.');
				
			default:
				return(false);
		}
	}
));
