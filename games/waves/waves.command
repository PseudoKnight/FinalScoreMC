register_command('waves', array(
	description: 'Manages and starts custom waves against enemies.',
	usage: '/waves <start|set|delete|info> [arena_id] [spawn|lobby|schematic|startblock] [blocktype|schematicname]',
	tabcompleter: _create_tabcompleter(
		array('start', 'set', 'delete', 'records', 'resetrecords'),
		array('<arena_id>'),
		array(
			'<<set': array('spawn', 'lobby', 'schematic', 'startblock', 'trigger'),
			'<<delete': array('spawns', 'schematic', 'startblock', 'trigger')),
	),
	executor: closure(@alias, @sender, @args, @info) {
		if(!@args) {
			return(false);
		}
		@action = @args[0];
		switch(@action) {
			case 'set':
				if(!has_permission('group.engineer')) {
					die(color('gold').'No permission.');
				}
				@name = array_get(@args, 1, null);
				if(!@name) {
					die(color('gold').'This requires an arena id.');
				}
				@arena = get_value('waves', @name);
				if(!@arena) {
					@arena = associative_array();
				}
				@setting = array_get(@args, 2, null);
				switch(@setting) {
					case 'spawn':
						@group = 'spawns';
						if(array_size(@args) > 3) {
							@group = @args[3];
						}
						if(!array_index_exists(@arena, @group)) {
							@arena[@group] = array();
						}
						@loc = array_normalize(location_shift(ploc(), 'up'))[0..3];
						@arena[@group][] = @loc;
						msg(color('green').'Added spawn location');

					case 'lobby':
						@loc = array_normalize(ploc())[0..3];
						@arena['lobby'] = @loc;
						msg(color('green').'Set lobby location');

					case 'schematic':
						@arena['schematic'] = @args[3];
						msg(color('green').'Set schematic');

					case 'startblock':
						@arena['startblock'] = array(loc: ptarget_space(), type: @args[3]);
						msg(color('green').'Set startblock');

					case 'trigger':
						if(!array_index_exists(@arena, 'triggers')) {
							@arena['triggers'] = associative_array();
						}
						@arena['triggers'][@args[3]] =  ptarget_space();
						msg(color('green').'Set trigger location for '.@args[3]);

				}
				store_value('waves', @name, @arena);

			case 'delete':
				if(!has_permission('group.engineer')) {
					die(color('gold').'No permission.');
				}
				@name = array_get(@args, 1, null);
				if(!@name) {
					die(color('gold').'This requires an arena id.');
				}
				if(array_size(@args) == 2) {
					clear_value('waves', @name);
					msg(color('green').'Deleted arena');
				} else {
					@arena = get_value('waves', @name);
					if(!@arena) {
						die(color('gold').'Arena does not exist: '.@name);
					}
					@key = @args[2];
					if(!array_index_exists(@arena, @key)) {
						die(color('gold').'Value does not exist in arena: '.@key);
					}
					array_remove(@arena, @key);
					msg(color('green').'Removed '.@key.' from '.@name);
					store_value('waves', @name, @arena);
				}

			case 'info':
				if(!has_permission('group.engineer')) {
					die(color('gold').'No permission.');
				}
				@name = array_get(@args, 1, null);
				if(!@name) {
					die(color('gold').'This requires an arena id.');
				}
				@arena = get_value('waves', @name);
				msg(color('green').'Arena info for '.@name);
				msg(map_implode(@arena, ': '.color('gray'), '\n'));

			case 'records':
				@name = array_get(@args, 1, null);
				if(!@name) {
					die(color('gold').'This requires an arena id.');
				}
				@script = array_get(@args, 2, 'random');
				@records = array();
				foreach(@key: @data in get_values('waves', @name, @script)) {
					@uuid = split('.', @key)[-1];
					@pdata = _pdata_by_uuid(@uuid);
					@records[] = array(name: @pdata['name'], waves: @data);
				}
				array_sort(@records, closure(@left, @right){
					return(@left['waves'] < @right['waves']);
				});
				msg(color('green').color('bold').'Player records:');
				foreach(@entry in @records) {
					msg(@entry['name'].': '.@entry['waves']);
				}

			case 'resetrecords':
				if(!has_permission('group.engineer')) {
					die(color('gold').'No permission.');
				}
				@name = array_get(@args, 1, null);
				if(!@name) {
					die(color('gold').'This requires an arena id.');
				}
				@script = array_get(@args, 2, null);
				if(!@script) {
					die(color('gold').'This requires a script name.');
				}
				foreach(@key: @data in get_values('waves', @name, @script)) {
					clear_value(@key);
				}
				msg(color('gold').'Cleared records for '.@name.': '.@script);

			case 'start':
				@region = null;
				@world = pworld();
				if(@block = get_command_block()) {
					@region = sk_regions_at(@block);
					@world = @block['world'];
				} else {
					@region = sk_current_regions();
				}
				if(!@region) {
					die(color('gold').'There is no arena here.');
				}
				@region = @region[-1];
				@arena = get_value('waves', @region);
				if(!@arena) {
					die(color('gold').'This region is not defined as an arena.');
				}
				
				@scripts = '';
				try {
					@scripts = read('arenas/'.@region.'.yml');
				} catch(IOException @ex) {
					die(color('gold').'This are no waves defined for this region.');
				}
				@scripts = yml_decode(@scripts);
				
				@activities = import('activities');
				if(@activities && array_index_exists(@activities, 'waves'.@region)) {
					die(color('gold').'Game is already running.');
				}
				if(has_inventory('wavesstart'.@region)) {
					die(color('gold').'Someone is already starting the game.');
				}
				
				include_dir('core.library');
				include_dir('mobs.library');
				
				if(array_size(@scripts) == 1) {
					@name = array_keys(@scripts)[0];
					@waves = _waves_prepare(@name, @arena, @region, @world);
					try {
						_waves_start(@waves);
					} catch(Exception @ex) {
						console(@ex['classType'].': '.@ex['message'], false);
						foreach(@trace in @ex['stackTrace']) {
							console(split('LocalPackages', @trace['file'])[-1].':'.@trace['line'].' '.@trace['id'], false);
						}
						msg(color('red').@ex['message']);
						msg(color('yellow').'Cleaning up game...');
						_waves_end(@waves, false);
					}
					return(true);
				}
				
				@menu = associative_array();
				@index = 0;
				foreach(@id: @item in @scripts) {
					foreach(@i: @line in @item['lore']) {
						@item['lore'][@i] = color('white').colorize(@line);
					}
					@menu[@index] = array(
						name: @item['name'],
						meta: array(display: @item['display'], lore: @item['lore'], flags: array('HIDE_ATTRIBUTES', 'HIDE_POTION_EFFECTS')),
					);
					@index++;
				}
				create_virtual_inventory('wavesstart'.@region, 9, 'Pick a Script', @menu);
				popen_inventory('wavesstart'.@region);
				
				bind('inventory_close', null, null, @e, @player = player(), @region) {
					if(player() == @player) {
						unbind(player().'click');
						unbind();
						delete_virtual_inventory('wavesstart'.@region);
					}
				}
				
				bind('inventory_click', array(id: player().'click'), array(player: player()), @e, @arena, @region, @world) {
					@item = @e['slotitem'];
					if(@item && @item['meta'] && @item['meta']['display']) {
						close_pinv(); // unbinds and deletes menu
						
						@name = replace(to_lower(@item['meta']['display']), ' ', '');

						array @waves;
						try {
							@waves = _waves_prepare(@name, @arena, @region, @world);
							_waves_start(@waves);
						} catch(Exception @ex) {
							console(@ex['classType'].': '.@ex['message'], false);
							foreach(@trace in @ex['stackTrace']) {
								console(split('LocalPackages', @trace['file'])[-1].':'.@trace['line'].' '.@trace['id'], false);
							}
							msg(color('red').@ex['message']);
							msg(color('yellow').'Cleaning up game...');
							_waves_end(@waves, false);
						}
					}
				}
				
			default:
				return(false);
		}
	}
));
