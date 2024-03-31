proc _get_custom_entities() {
	@custom = import('customEntities');
	if(is_null(@custom)) {
		@custom = yml_decode(read('custom.yml'));
		export('customEntities', @custom);
	}
	return(@custom);
}

register_command('entity', array(
	description: 'Custom entity management commands',
	usage: '/entity <list|info|set|delete|spawn|patrol|reload> [entity_name] [...]',
	permission: 'command.entity',
	tabcompleter: _create_tabcompleter(
		array('list', 'info', 'set', 'delete', 'spawn', 'patrol', 'reload'),
		array('<info|set|delete|spawn|patrol': array_keys(_get_custom_entities())),
		array('<<set|delete': array('type', 'name', 'age', 'health', 'lifetime', 'onfire', 'targetnear',
					'ai', 'tame', 'glowing', 'invulnerable', 'gravity', 'silent', 'gear', 'droprate', 'effect', 'tags',
					'attributes', 'rider', 'explode', 'scoreboardtags', 'velocity')),
		array('<type|rider': reflect_pull('enum', 'EntityType')),
	),
	executor: closure(@alias, @sender, @args) {
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
						@strength = integer(@args[4]) - 1;
						@duration = double(@args[5]);
						@found = false;
						foreach(@index: @effect in @entity['effects']) {
							if(@effect['id'] == @effectid) {
								@found = true;
								if(@duration == 0) {
									array_remove(@entity['effects'], @index);
									msg(color('green').'Effect removed');
								} else {
									@entity['effects'][@index]['strength'] = @strength;
									@entity['effects'][@index]['seconds'] = @duration;
									msg(color('green').'Effect modified');
								}
								break();
							}
						}
						if(!@found) {
							@entity['effects'][] = array(
								'id': @effectid,
								'strength': @strength,
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
						if(@args[3][0] == '{') {
							@entity['rider'] = json_decode(@args[3]);
						} else {
							@entity['rider'] = @args[3];
						}
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
							die(color('gold').'That explosion is too big. Yes, that is a thing.');
						}
						@entity['explode'] = array(integer(@duration), integer(@strength));
						msg(color('green').'Set entity to explode after '.@duration.' seconds with strength of '.@strength);

					case 'scoreboardtags':
						@tags = split(',', @args[3]);
						@entity['scoreboardtags'] = @tags;
						msg(color('green').'Set entity scoreboard tags to '.@tags);

					case 'velocity':
						if(array_size(@args) < 6) {
							die(color('gold').'Must give three numbers (x y z)')
						}
						@entity['velocity'] = array(double(@args[3]), double(@args[4]), double(@args[5]));
						msg(color('green').'Set velocity to '.@entity['velocity']);

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
					die('Spawn takes the following arguments:\n'
					. '- Entity type or custom entity (e.g. minecart or badsnowman)\n'
					. '- JSON (optional) to modify the entity with additional data\n'
					. '- Count (required if commandblock)\n'
					. '- Relative coords (required if commandblock)\n'
					. 'Example: /entity spawn minecart {"velocity":[0,1,0]} 1 ~ ~2 ~');
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
				@loc = _center(@loc, 0.0);
				while(@entityCount > 0) {
					_spawn_entity(@id, @loc);
					@entityCount--;
				}

			case 'patrol':
				if(array_size(@args) < 6) {
					return(false);
				}
				@loc = get_command_block();
				if(!@loc) {
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

				@loc = _relative_coords(@loc, @args[2 + @offset], @args[3 + @offset], @args[4 + @offset]);
				@directions = @args[cslice(5 + @offset, -1)];

				@loc = _center(@loc, 0.0);
				@entity = _spawn_entity(@id, @loc, null, closure(@e) {
					if(is_entity_living(@e)) {
						set_entity_ai(@e, false);
					}
				});
				@speed = 0.1
				@living = is_entity_living(@entity);
				if(@living) {
					@speed = entity_attribute_value(@entity, 'GENERIC_MOVEMENT_SPEED') / 2.1585; // meters/tick
				}

				@target = @loc[];
				@target['w'] = 0;
				set_interval(50, closure(){
					try {
						if(@target['w'] > 0) {
							@target['w'] -= 1;
							return();
						}
						@loc = entity_loc(@entity);
						@distance = distance(@loc, @target);
						if(@living) {
							@yaw = get_yaw(@loc, @target);
							if(@yaw != 'NaN') {
								@loc['yaw'] = @yaw;
							}
						}
						set_entity_loc(@entity, location_shift(@loc, @target, min(@distance, @speed)));
						if(@distance <= @speed) {
							// if target was within reach in this tick, queue any remaining directions
							if(!@directions) {
								clear_task();
								foreach(@ent in get_entity_riders(@entity)) {
									try(entity_remove(@ent));
								}
								entity_remove(@entity);
								return();
							}
							@next = array_remove(@directions, 0);
							foreach(@axis in split(',', @next)) {
								@coord = @axis[0];
								@target[@coord] += @axis[1..-1];
							}
						}
					} catch(Exception @ex) {
						if(@ex['classType'] != 'com.commandhelper.BadEntityException') {
							console(@ex['message']);
						}
						clear_task();
					}
				});

			case 'list':
				@custom = _get_custom_entities();
				msg(color('gray').'CUSTOM ENTITIES: '.color('r').array_implode(array_keys(@custom)));

			case 'reload':
				export('customEntities', null);
				_get_custom_entities();
				msg(color('green').'Reloaded custom entities from YML configuration.');

			default:
				msg('/entity list '.color('gray').'Lists all custom entities');
				msg('/entity info <entity> '.color('gray').'Displays information about custom entity');
				msg('/entity set <entity> <setting> <value> '.color('gray').'Sets a value to the custom entity');
				msg('/entity delete <entity> [setting] '.color('gray').'Deletes entity or setting');
				msg('/entity spawn <entity> '.color('gray').'Spawns entity where you are looking');
				msg('/entity patrol <entity> <~x ~y ~z> <directions...>'.color('gray').'Spawns temporary entity and directs it');
				msg('/entity reload '.color('gray').'Reloads custom entities from YML configuration.');

		}
	}
));
