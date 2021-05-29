register_command('map', array(
	'description': 'Manages custom maps players can create.',
	'usage': '/map <create|load> <id>',
	'permission': 'command.map',
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		if(array_size(@args) == 1) {
			return(_strings_start_with_ic(array('create'), @args[-1]));
		}
		return(array());
	},
	'executor': closure(@alias, @sender, @args, @info) {
		if(!@args) {
			return(false);
		}
		@action = @args[0];
		@id = array_get(@args, 1, null);

		include('.library/maps.ms');

		switch(@action) {
			case 'create':
				if(is_null(@id)) {
					throw(InsufficientArgumentsException, 'A map id was not given.');
				}
				if(_map_exists(@id)) {
					throw(NotFoundException, 'A map by that id already exists.');
				}
				_map_load(@id);

			case 'load':
				if(is_null(@id)) {
					throw(InsufficientArgumentsException, 'A map id was not given.');
				}
				if(!_map_exists(@id)) {
					throw(NotFoundException, 'A map by that id does not exist.');
				}
				_map_load(@id);

			default:
				return(false);
		}
	}
));
