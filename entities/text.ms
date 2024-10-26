register_command('text', array(
	description: 'Creates and modifies text displays',
	usage: '/text <create|select|set|delete> [key] [value]',
	permission: 'command.entity',
	tabcompleter: _create_tabcompleter(
		array('create', 'move', 'select', 'set', 'delete'),
		array('<set': array('text', 'align', 'linewidth', 'seethrough', 'shadow', 'opacity',
			'brightness', 'billboard', 'viewrange', 'scale')),
		array('<<set': array('<align': array('center', 'left', 'right'),
			'<seethrough|shadow': array('true', 'false'),
			'<billboard': array('fixed', 'horizontal', 'vertical', 'center')))
	),
	executor: closure(@alias, @player, @args) {
		if(!@args) {
			return(false);
		}
		@cmd = @args[0];
		switch(@cmd) {
			case 'create':
			case 'move':
				@trace = ray_trace();
				if(!@trace['hitblock']) {
					die('Must face a block.');
				}
				@loc = @trace['location'];
				switch(@trace['hitface']) {
					case 'UP':
						@loc['y'] -= 0.5;
						@loc['yaw'] = @trace['origin']['yaw'];
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
				if(@cmd === 'create') {
					@display = spawn_entity('TEXT_DISPLAY', 1, @loc)[0];
					set_entity_spec(@display, array(text: array_implode(@args[1..])));
					export(player().'textdisplay', @display);
					msg('Created and selected text display. Can delete it or set values.');
				} else {
					@display = import(player().'textdisplay');
					if(!@display) {
						die('Must first select a text display.');
					}
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
				msg('Selected text display. Can delete it or set values.');
			case 'set':
				if(array_size(@args) < 2) {
					msg('Insufficient arguments.');
					return(false);
				}
				@display = import(player().'textdisplay');
				if(!@display) {
					die('Must first select a text display.');
				}
				@key = @args[1];
				@value = null;
				if(array_size(@args) > 2) {
					@value = @args[2];
				}
				switch(@key) {
					case 'text':
						if(!@value) {
							die('Must specify any text. (Use \\n for new lines)');
						}
						@text = array_implode(@args[2..]);
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
						@spec = associative_array();
						@spec[@key] = integer(@value);
						set_entity_spec(@display, @spec);
					case 'opacity':
						if(!@value) {
							die('Must specify an integer from 0 - 255. (default 255) Values below 26 may be ignored.');
						}
						@spec = associative_array();
						@spec[@key] = integer(@value);
						set_entity_spec(@display, @spec);
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
						@spec[@key] = @value == 'true';
						set_entity_spec(@display, @spec);
					case 'viewrange':
						if(!@value) {
							die('Must specify a double that scales the viewable range. (1.0 is the default of 64 meters)');
						}
						set_display_entity(@display, array(viewrange: double(@value)));
					case 'scale':
						if(array_size(@args) < 5) {
							die('Must give 3 doubles for scale of text. (1.0 1.0 1.0 is default)')
						}
						set_display_entity(@display, array(transformation: array(
							scale: array(x: double(@args[2]), y: double(@args[3]), z: double(@args[4])))));
				}
				msg("Updated @key for text display.");
			case 'delete':
				@display = import(player().'textdisplay');
				if(!@display) {
					die('Must first select a text display.');
				}
				entity_remove(@display);
				msg('Deleted text display.');
		}
	}
));