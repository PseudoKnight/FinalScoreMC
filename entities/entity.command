register_command('entity', array(
	'description': 'Custom entity management commands',
	'usage': '/entity <list|info|set|delete|spawn|reload> [entity_name] [setting] [value(s)]',
	'permission': 'command.entity',
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		if(array_size(@args) == 1) {
			return(_strings_start_with_ic(array('list', 'info', 'set', 'delete', 'spawn', 'reload'), @args[-1]));
		} else if(array_size(@args) == 3) {
			return(_strings_start_with_ic(array('type', 'name', 'age', 'health', 'lifetime', 'onfire', 'targetnear',
					'ai', 'tame', 'glowing', 'invulnerable', 'gravity', 'silent', 'gear', 'droprate', 'effect', 'tags',
					'attributes', 'rider', 'explode', 'scripts'), @args[-1]));
		}
		return(array());
	},
	'executor': closure(@alias, @sender, @args, @info) {
		if(!@args) {
			return(false);
		}
		switch(@args[0]) {
			case 'set':
				if(array_size(@args) < 3) {
					return(false);
				}
				@id = @args[1];
				@setting = @args[2];
				@custom = _get_custom_entities();
				if(!array_index_exists(@custom, @id)) {
					@custom[@id] = associative_array();
				}
				@entity = @custom[@id];
				switch(@setting) {
					case 'type':
						if(array_size(@args) == 3) {
							return(false);
						}
						@type = @args[3];
						if(!_get_entity(@type)) {
							die(color('gold').'Unknown entity type.');
						}
						@entity['type'] = @type;
						msg(color('green').'Type set to '.@type);

					case 'name':
						if(array_size(@args) == 3) {
							return(false);
						}
						@name = @args[3];
						if(length(@name) > 64) {
							die(color('gold').'Name is too long.');
						}
						@entity['name'] = colorize(@name);
						msg(color('green').'Name set to '.@entity['name']);

					// Single integer values
					case 'age':
					case 'health':
					case 'lifetime':
					case 'onfire':
					case 'targetnear':
						if(array_size(@args) == 3) {
							return(false);
						}
						@int = @args[3];
						if(!is_integral(@int)) {
							die(color('gold').'Must be an integer.');
						}
						@entity[@setting] = integer(@int);
						msg(color('green').to_upper(@setting).' set to '.@entity[@setting]);

					// Single boolean
					case 'ai':
					case 'tame':
					case 'glowing':
					case 'invulnerable':
					case 'gravity':
					case 'silent':
						if(array_size(@args) == 3) {
							return(false);
						}
						@boolean = @args[3];
						@entity[@setting] = (@boolean == 'true');
						msg(color('green').to_upper(@setting).' set to '.@entity[@setting]);

					case 'gear':
						@entity['gear'] = array(
							'WEAPON': pinv(player(), 0),
							'OFF_HAND': pinv(player(), -106),
							'HELMET': pinv(player(), 103),
							'CHESTPLATE': pinv(player(), 102),
							'LEGGINGS': pinv(player(), 101),
							'BOOTS': pinv(player(), 100)
						);
						msg(color('green').'Gear set.');

					case 'droprate':
						if(array_size(@args) == 4) {
							@entity['droprate'] = array(
								'WEAPON': double(@args[3]),
								'OFF_HAND': double(@args[3]),
								'BOOTS': double(@args[3]),
								'LEGGINGS': double(@args[3]),
								'CHESTPLATE': double(@args[3]),
								'HELMET': double(@args[3])
							);
						} else if(array_size(@args) == 9) {
							@entity['droprate'] = array(
								'WEAPON': double(@args[3]),
								'OFF_HAND': double(@args[4]),
								'BOOTS': double(@args[5]),
								'LEGGINGS': double(@args[6]),
								'CHESTPLATE': double(@args[7]),
								'HELMET': double(@args[8]),
							);
						} else {
							return(false);
						}
						msg(color('green').'Droprate set.');

					case 'effect':
						if(array_size(@args) < 6) {
							return(false);
						}
						if(!is_numeric(@args[3])) {
							die('Must be numeric');
						}
						@effectid = integer(@args[3]);
						if(!array_index_exists(@entity, 'effects')) {
							@entity['effects'] = array();
						}
						@duration = integer(@args[5]);
						if(@duration == 0) {
							foreach(@index: @effect in @entity['effects']) {
								if(@effect['id'] == @effectid) {
									array_remove(@entity['effects'], @index);
									msg(color('green').'Effect removed');
									break();
								}
							}
						} else {
							@entity['effects'][] = array(
								'id': @effectid,
								'strength': @args[4] - 1,
								'seconds': @duration
							);
							msg(color('green').'Effect added');
						}

					# associative arrays
					case 'tags':
					case 'attributes':
						if(array_size(@args) == 3) {
							return(false);
						}
						@entity[@setting] = json_decode(array_implode(@args[3..-1]));
						msg(color('green').'Set '.@setting.' to '.@entity[@setting]);

					case 'rider':
						if(array_size(@args) == 3) {
							return(false);
						}
						@entity['rider'] = @args[3];
						msg(color('green').'Set entity rider to '.@entity['rider']);

					case 'explode':
						if(array_size(@args) < 5) {
							die(color('gold').'Must give two numbers: seconds till explode, explosion strength')
						}
						@duration = @args[3];
						if(!is_numeric(@duration)) {
							die(color('gold').'Must give a number in seconds for the entity to explode.');
						}
						@strength = @args[4];
						if(!is_numeric(@strength)) {
							die(color('gold').'Must give a number for the strength of explosion.');
						}
						if(@strength > 8) {
							die(color('gold').'That explosion is too big. Yes, that\'s a thing.');
						}
						@entity['explode'] = array(integer(@duration), integer(@strength));
						msg(color('green').'Set entity to explode after '.@duration.' seconds with strength of '.@strength);

					case 'scripts':
						if(array_size(@args) == 3) {
							return(false);
						}
						@entity['scripts'] = split(',', @args[3]);
						msg(color('green').'Set entity scripts to '. @entity['scripts']);

					default:
						die(color('yellow').'Invalid setting.');
				}
				write_file('custom.yml', yml_encode(@custom, true), 'OVERWRITE');

			case 'delete':
				if(array_size(@args) < 2) {
					return(false);
				}
				@id = @args[1];
				if(array_size(@args) > 2) {
					@setting = @args[2];
					@custom = _get_custom_entities();
					if(!array_index_exists(@custom, @id)) {
						@custom[@id] = associative_array();
					}
					@entity = @custom[@id];
					if(@setting === 'effect') {
						@setting = 'effects';
					}
					array_remove(@entity, @setting);
					write_file('custom.yml', yml_encode(@custom, true), 'OVERWRITE');
					msg(color('green').@setting.' deleted from '.@id);
				} else {
					@custom = _get_custom_entities();
					if(array_index_exists(@custom, @id)) {
						array_remove(@custom, @id);
					}
					write_file('custom.yml', yml_encode(@custom, true), 'OVERWRITE');
					msg(color('green').'Custom entity deleted.');
				}

			case 'info':
				if(array_size(@args) < 2) {
					return(false);
				}
				@id = @args[1];
				@custom = _get_custom_entities();
				if(!array_index_exists(@custom, @id)) {
					die(color('red').'Entity does not exist.');
				}
				@entity = @custom[@id];
				foreach(@setting: @value in @entity) {
					msg(color('gray').@setting.' '.color('r').@value);
				}

			case 'spawn':
				if(array_size(@args) < 2) {
					return(false);
				}
				@id = @args[1];
				@data = array_get(@args, 2, null);
				@offset = 0;
				if(string_starts_with(@id, '{')) {
					@id = json_decode(@id);
				} else if(@data && string_starts_with(@data, '{'))  {
					@data = json_decode(@data);
					@data['type'] = @id;
					@id = @data;
					@offset = 1;
				}
				@entityCount = 1;
				if(array_size(@args) > 2 + @offset) {
					@entityCount = integer(@args[2 + @offset]);
				}
				@loc = get_command_block();
				if(@loc == null) {
					@loc = ptarget_space();
				} else {
					@loc = _relative_coords(@loc, @args[3 + @offset], @args[4 + @offset], @args[5 + @offset]);
					if(array_size(@args) > 6 + @offset) {
						@loc['yaw'] = @args[6 + @offset];
					}
				}
				@loc['x'] += 0.5;
				@loc['z'] += 0.5;
				while(@entityCount > 0) {
					_spawn_entity(@id, @loc, player());
					@entityCount--;
				}

			case 'list':
				@custom = _get_custom_entities();
				msg(color('gray').'CUSTOM ENTITIES: '.color('r').array_implode(array_keys(@custom)));

			case 'reload':
				export('customEntities', null);
				msg(color('green').'Reloaded custom entities from YML configuration.');

			default:
				msg('/entity set <entity> <setting> <value> '.color('gray').'Sets a value to the custom entity');
				msg('/entity delete <entity> [setting] '.color('gray').'Deletes entity or setting');
				msg('/entity info <entity> '.color('gray').'Displays information about custom entity');
				msg('/entity spawn <entity> '.color('gray').'Spawns entity where you\'re looking');
				msg('/entity list '.color('gray').'Lists all custom entities');
				msg('/entity reload '.color('gray').'Reloads custom entities from YML configuration.');

		}
	}
));
