register_command('map', array(
	'description': 'Manages custom maps players can create.',
	'usage': '/map <create|load|delete> <id> [dimension]',
	'permission': 'command.map',
	'tabcompleter': _create_tabcompleter(
		array('create', 'load', 'delete'),
		null,
		array('<<create': array('normal', 'nether', 'the_end'))
	),
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
					throw(InsufficientArgumentsException, 'A map ID was not given.');
				}
				if(_map_exists(@id)) {
					throw(IllegalArgumentException, 'Map file by that ID already exists.');
				}
				if(get_value('map', @id)) {
					throw(IllegalArgumentException, 'Map data by that ID already exists.');
				}
				@dimension = to_upper(array_get(@args, 2, 'NORMAL'));
				msg('Creating map...');
				_map_create(@id, @dimension);
				_map_load(@id);

			case 'load':
				if(is_null(@id)) {
					throw(InsufficientArgumentsException, 'A map ID was not given.');
				}
				if(!_map_exists(@id)) {
					throw(NotFoundException, 'A map by that ID does not exist.');
				}
				msg('Loading map...');
				_map_load(@id);

			case 'delete':
				if(is_null(@id)) {
					throw(InsufficientArgumentsException, 'A map ID was not given.');
				}
				if(!_map_exists(@id)) {
					throw(NotFoundException, 'A map by that ID does not exist.');
				}
				_map_delete(@id);
				msg('Deleted map.');

			default:
				return(false);
		}
	}
));
