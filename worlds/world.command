register_command('world', array(
	description: 'Lists and manages worlds.',
	usage: '/world <list|create|unload|reload> [name] [value]',
	permission: 'command.world',
	tabcompleter: closure(@alias, @sender, @args, @info) {
		if(array_size(@args) == 1) {
			return(_strings_start_with_ic(array('list', 'create', 'unload', 'reload'), @args[-1]));
		} else if(array_size(@args) == 2 && @args[0] == 'unload') {
			return(_strings_start_with_ic(get_worlds(), @args[-1]));
		}
		return(array());
	},
	executor: closure(@alias, @sender, @args, @info) {
		if(!@args) {
			return(false);
		}
		switch(@args[0]) {
			case 'create':
				if(array_size(@args) < 2) {
					return(false);
				}
				@name = @args[1];
				@start = time();
				if(array_contains(get_worlds(), @name)) {
					die(color('gold').'The world "'.@name.'" already exists.');
				}
				if(!reg_match('[a-zA-Z_]*', @name)) {
					die(color('gold').'Requires a valid world name.');
				}
				@world = array(
					'name': @name,
					'mode': 'SURVIVAL',
					'group': @name,
					'teleports': true,
					'environment': 'NORMAL',
					'seed': null,
				);
				if(array_size(@args) > 2) {
					foreach(@arg in @args[2..-1]) {
						@split = split(':', @arg);
						@key = to_lower(@split[0]);
						@value = @split[1];
						switch(@key) {
							// ints
							case 'seed':
								@value = if(is_integral(@value), integer(@value), @value);
							// booleans
							case 'teleports':
								@value = if(@value == 'true', @value = true, @value = false);
							// do nothing
							case 'generator':
								noop();
							default:
								@value = to_upper(@value);
						}
						@world[@key] = @value;
					}
				}
				_create_world(@name, @world);
				@stop = time();
				msg(color('green').'Created world "'.@name.'" ('.(@stop - @start).'ms)');

			case 'unload':
				if(array_size(@args) < 2) {
					return(false);
				}
				@name = @args[1];
				@start = time();
				_unload_world(@name);
				@stop = time();
				msg(color('green').'Unloaded world "'.@name.'" ('.(@stop - @start).'ms)');

			case 'reload':
				@worlds = yml_decode(read('config.yml'));
				export('worlds', @worlds);
				include('load.ms');

			case 'list':
				@loadedworlds = get_worlds();
				@worlds = _worlds_config();
				@worldnames = array();
				foreach(@world in @loadedworlds) {
					@worldnames[] = @worlds[@world]['name'];
				}
				array_sort(@worldnames);
				@list = '';
				foreach(@world in @worldnames) {
					if(!@list) {
						@list .= color('gray').'Loaded Worlds: '.color('reset').@world;
					} else {
						@list .= ', '.@world;
					}
				}
				msg(@list);
				
			default:
				return(false);
		}
	}
));
