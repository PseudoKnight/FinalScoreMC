register_command('text', array(
	description: 'Creates and modifies text displays',
	usage: '/text <create|select|set|delete|align|linewidth|seethrough|shadow|opacity|brightness|billboard|viewrange|scale> [value]',
	permission: 'command.entity',
	tabcompleter: _create_tabcompleter(
		array('create', 'move', 'select', 'set', 'delete', 'align', 'linewidth', 'seethrough', 
			'shadow', 'opacity', 'brightness', 'billboard', 'viewrange', 'scale', 'bgcolor', 'copy'),
		array('<create|set': array('<text...>'),
			'<move': array('here', 'there'),
			'<align': array('center', 'left', 'right'),
			'<seethrough|shadow': array('true', 'false'),
			'<billboard': array('fixed', 'horizontal', 'vertical', 'center'),
			'<linewidth|viewrange': array('<num>'),
			'<opacity': array('<0-255>'),
			'<brightness': array('<0-15>'),
			'<scale': array('<x> [y]'),
			'<bgcolor': array('default', 'none', '<r> <g> <b> <a>'))
	),
	executor: closure(@alias, @player, @args) {
		if(!@args) {
			return(false);
		}
		@action = @args[0];
		@value = null;
		if(array_size(@args) > 1) {
			@value = @args[1];
		}
		@display = import(player().'textdisplay');
		if(!@display && @action !== 'create' && @action !== 'select') {
			die('Must first create or select a text display.');
		}
		switch(@action) {
			case 'create':
			case 'move':
			case 'copy':
				if(@action === 'move' && @value === 'here') {
					set_entity_loc(@display, entity_loc(puuid()));
					return(true);
				}
				@trace = ray_trace();
				if(!@trace['hitblock']) {
					die('Must face a block.');
				}
				@loc = @trace['location'];
				switch(@trace['hitface']) {
					case 'UP':
						@loc['yaw'] = @trace['origin']['yaw'] + 180;
						@loc['pitch'] = -90;
						@loc['y'] += 0.01;
					case 'DOWN':
						@loc['yaw'] = @trace['origin']['yaw'] + 180;
						@loc['pitch'] = 90;
						@loc['y'] -= 0.01;
					case 'WEST':
						@loc['yaw'] = 90.0;
						@loc['x'] -= 0.01;
					case 'EAST':
						@loc['yaw'] = 270.0;
						@loc['x'] += 0.01;
					case 'SOUTH':
						@loc['yaw'] = 0.0;
						@loc['z'] += 0.01;
					case 'NORTH':
						@loc['yaw'] = 180.0;
						@loc['z'] -= 0.01;
				}
				if(@action === 'create') {
					@display = spawn_entity('TEXT_DISPLAY', 1, @loc)[0];
					@text = array_implode(@args[1..]);
					@text = replace(@text, '\\n', '\n');
					set_entity_spec(@display, array(text: @text));
					export(player().'textdisplay', @display);
					msg('Created and selected text display for modification.');
				} else if(@action === 'copy') {
					@specData = entity_spec(@display);
					@displayData = get_display_entity(@display);
					@display = spawn_entity('TEXT_DISPLAY', 1, @loc)[0];
					set_entity_spec(@display, @specData);
					set_display_entity(@display, @displayData);
					export(player().'textdisplay', @display);
					msg('Copied text display and selected copy.');
				} else {
					set_entity_loc(@display, @loc);
				}
			case 'select':
				@displays = select_entities('@e[type=text_display,limit=1,sort=nearest]');
				if(!@displays) {
					die('Must be near a text display.');
				}
				@display = @displays[0];
				export(player().'textdisplay', @display);
				@loc = entity_loc(@display);
				@opacity = entity_spec(@display)['opacity'];
				set_entity_spec(@display, array(opacity: integer(@opacity / 2)));
				play_sound(@loc, array(sound: 'BLOCK_STONE_BUTTON_CLICK_ON', pitch: 2.0));
				set_timeout(250, closure(){
					set_entity_spec(@display, array(opacity: @opacity));
					set_timeout(250, closure(){
						set_entity_spec(@display, array(opacity: integer(@opacity / 2)));
						play_sound(@loc, array(sound: 'BLOCK_STONE_BUTTON_CLICK_ON', pitch: 2.0));
						set_timeout(250, closure(){
							set_entity_spec(@display, array(opacity: @opacity));
						});
					});
				});
				msg('Selected text display for modification.');
			case 'set':
				if(!@value) {
					die('Must specify any text. (Use \\n for new lines)');
				}
				@text = array_implode(@args[1..]);
				@text = replace(@text, '\\n', '\n');
				set_entity_spec(@display, array(text: colorize(@text)));
			case 'align':
				if(!@value) {
					die('Must specify text alignment: center, left, or right.');
				}
				set_entity_spec(@display, array(alignment: to_upper(@value)));
			case 'billboard':
				if(!@value) {
					die('Must specify how the entity rotates around player: fixed, horizontal, vertical, or center.');
				}
				set_display_entity(@display, array(billboard: to_upper(@value)));
			case 'linewidth':
				if(!@value) {
					die('Must specify an integer above zero. (default 200)');
				}
				set_entity_spec(@display, array(linewidth: integer(@value)));
			case 'opacity':
				if(!@value) {
					die('Must specify an integer from 0 - 255. (default 255) Values below 26 may be ignored.');
				}
				set_entity_spec(@display, array(opacity: integer(@value)));
			case 'brightness':
				if(!@value) {
					die('Must specify an integer from 0 - 15. (default 15)');
				}
				set_display_entity(@display, array(brightness: integer(@value)));
			case 'seethrough':
			case 'shadow':
				if(!@value || (@value !== 'true' && @value !== 'false')) {
					die('Must be true or false.');
				}
				@spec = associative_array();
				@spec[@action] = @value == 'true';
				set_entity_spec(@display, @spec);
			case 'viewrange':
				if(!@value) {
					die('Must specify a double that scales the viewable range. (1.0 is the default of 64 meters)');
				}
				set_display_entity(@display, array(viewrange: double(@value)));
			case 'scale':
				if(!@value) {
					die('Must give 1 or 2 doubles for xy scale of text. (1.0 1.0 is default)')
				}
				@x = double(@value);
				@y = @x;
				if(array_size(@args) > 2) {
					@y = double(@args[2]);
				}
				set_display_entity(@display, array(transformation: array(scale: array(x: @x, y: @y, z: 1.0))));
			case 'bgcolor':
				if(@value == 'default') {
					set_entity_spec(@display, array(bgcolor: null));
				} else if(@value == 'none') {
					set_entity_spec(@display, array(bgcolor: array(0, 0, 0, 0)));
				} else {
					if(array_size(@args) < 5) {
						die('Must be "default" or 4 values for red, green, blue, and alpha. (0-255)');
					}
					@r = integer(@args[1]);
					@g = integer(@args[2]);
					@b = integer(@args[3]);
					@a = integer(@args[4]);
					set_entity_spec(@display, array(bgcolor: array(r: @r, g: @g, b: @b, a: @a)));
				}
			case 'delete':
				entity_remove(@display);
				export(player().'textdisplay', null);
				msg('Deleted text display.');
			default:
				return(false);
		}
	}
));