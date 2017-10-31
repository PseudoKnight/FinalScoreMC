register_command('level', array(
	'description': 'Manages and starts custom levels against waves of enemies.',
	'usage': '/level <start|setspawn|delete|setlobby|setschematic|setstartblock> [arena_id] [blocktype|schematic]',
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		if(array_size(@args) == 1) {
			return(_strings_start_with_ic(array('start', 'setspawn', 'delete', 'setlobby', 'setschematic', 'setstartblock'), @args[-1]));
		}
		return(array());
	},
	'executor': closure(@alias, @sender, @args, @info) {
		if(!@args) {
			return(false);
		}
		@action = @args[0];
		switch(@action) {
			case 'reload':
				if(!has_permission('group.engineer')) {
					die(color('gold').'No permission.');
				}
				x_recompile_includes('../core.library');
				x_recompile_includes('../mobs.library');
				msg(color('green').'Done!');
			
			case 'setspawn':
				if(!has_permission('group.engineer')) {
					die(color('gold').'No permission.');
				}
				if(array_size(@args) < 2) {
					die(color('gold').'This requires an arena id');
				}
				@name = @args[1];
				@arena = get_value('level', @name);
				@group = 'spawns';
				if(array_size(@args) > 2) {
					@group = @args[2];
				}
				if(!@arena) {
					@arena = associative_array();
					@arena[@group] = array();
				}
				if(!array_index_exists(@arena, @group)) {
					@arena[@group] = array();
				}
				@loc = array_normalize(_relative(ploc(), 'up'))[0..3];
				@arena[@group][] = @loc;
				store_value('level', @name, @arena);
				msg(color('green').'Added spawn location');
				
			case 'delete':
				if(!has_permission('group.engineer')) {
					die(color('gold').'No permission.');
				}
				if(array_size(@args) < 2) {
					die(color('gold').'This requires an arena id');
				}
				@name = @args[1];
				clear_value('level', @name);
				msg(color('green').'Deleted arena');
				
			case 'setlobby':
				if(!has_permission('group.engineer')) {
					die(color('gold').'No permission.');
				}
				if(array_size(@args) < 2) {
					die(color('gold').'This requires an arena id');
				}
				@name = @args[1];
				@arena = get_value('level', @name);
				if(!@arena) {
					@arena = associative_array();
				}
				@loc = array_normalize(ploc())[0..3];
				@arena['lobby'] = @loc;
				store_value('level', @name, @arena);
				msg(color('green').'Set lobby location');
				
			case 'setschematic':
				if(!has_permission('group.engineer')) {
					die(color('gold').'No permission.');
				}
				if(array_size(@args) < 3) {
					die(color('gold').'This requires an arena id and schematic name.');
				}
				@name = @args[1];
				@arena = get_value('level', @name);
				if(!@arena) {
					@arena = associative_array();
				}
				@arena['schematic'] = @args[2];
				store_value('level', @name, @arena);
				msg(color('green').'Set schematic');
				
			case 'setstartblock':
				if(!has_permission('group.engineer')) {
					die(color('gold').'No permission.');
				}
				if(array_size(@args) < 3) {
					die(color('gold').'This requires an arena id and block type.');
				}
				@name = @args[1];
				@arena = get_value('level', @name);
				if(!@arena) {
					@arena = associative_array();
				}
				@arena['startblock'] = array('loc': ptarget_space(), 'type': @args[2]);
				store_value('level', @name, @arena);
				msg(color('green').'Set startblock');
				
			case 'settrigger':
				if(!has_permission('group.engineer')) {
					die(color('gold').'No permission.');
				}
				if(array_size(@args) < 3) {
					die(color('gold').'This requires an arena id and trigger id.');
				}
				@name = @args[1];
				@arena = get_value('level', @name);
				if(!@arena) {
					@arena = associative_array();
				}
				if(!array_index_exists(@arena, 'triggers')) {
					@arena['triggers'] = associative_array();
				}
				@arena['triggers'][@args[2]] =  ptarget_space();
				store_value('level', @name, @arena);
				msg(color('green').'Set trigger location for '.@args[2]);
				
			case 'start':
				if(@block = get_command_block()) {
					@region = sk_regions_at(@block);
					@world = @block['world'];
				} else {
					@region = sk_current_regions();
					@world = pworld();
				}
				if(!@region) {
					die(color('gold').'There\'s no arena here.');
				}
				@region = @region[-1];
				@arena = get_value('level', @region);
				if(!@arena) {
					die(color('gold').'This region is not defined as an arena.');
				}
				
				@scripts = '';
				try {
					@scripts = read('../arenas/'.@region.'.yml');
				} catch(IOException @ex) {
					die(color('gold').'This are no levels defined for this region.');
				}
				@scripts = yml_decode(@scripts);
				
				@activities = import('activities');
				if(@activities && array_index_exists(@activities, 'level'.@region)) {
					die(color('gold').'Game is already running.');
				}
				if(array_contains(all_virtualchests(), 'levelstart'.@region)) {
					die(color('gold').'Someone is already starting the game.');
				}
				
				include('../core.library/game.ms');
				
				if(array_size(@scripts) == 1) {
					@name = array_keys(@scripts)[0];
					try {
						@level = _level_prepare(@name, @arena, @region, @world);
						_level_start(@level);
					} catch(Exception @ex) {
						console(@ex['classType'].': '.@ex['message'], false);
						foreach(@trace in @ex['stackTrace']) {
							console(split('LocalPackages', @trace['file'])[-1].':'.@trace['line'].' '.@trace['id'], false);
						}
						msg(color('red').@ex['message']);
						msg(color('yellow').'Cleaning up game...');
						_level_end(@level, false);
					}
					return();
				}
				
				@menu = array(
					'id': 'levelstart'.@region,
					'title': 'Pick a Script',
					'size': 9,
				);
				@index = 0;
				foreach(@id: @item in @scripts) {
					@menu[@index] = array(
						'name': @item['name'],
						'meta': array('display': @item['display'], 'lore': @item['lore'], 'flags': array('HIDE_ATTRIBUTES')),
					);
					@index++;
				}
				create_virtualchest(@menu);
				popen_virtualchest('levelstart'.@region);
				
				bind(inventory_close, null, null, @e, @player = player(), @region) {
					if(player() == @player) {
						unbind(player().'click');
						unbind();
						del_virtualchest('levelstart'.@region);
					}
				}
				
				bind(inventory_click, array('id': player().'click'), array('player': player()), @e, @arena, @region) {
					@item = @e['slotitem'];
					if(@item && @item['meta'] && @item['meta']['display']) {
						close_pinv(); // unbinds and deletes menu
						
						@name = replace(to_lower(@item['meta']['display']), ' ', '');

						try {
							@level = _level_prepare(@name, @arena, @region, @world);
							_level_start(@level);
						} catch(Exception @ex) {
							console(@ex['classType'].': '.@ex['message'], false);
							foreach(@trace in @ex['stackTrace']) {
								console(split('LocalPackages', @trace['file'])[-1].':'.@trace['line'].' '.@trace['id'], false);
							}
							msg(color('red').@ex['message']);
							msg(color('yellow').'Cleaning up game...');
							_level_end(@level, false);
						}
					}
				}
				
			default:
				return(false);
		}
	}
));
