proc _get_custom_entities() {
	@custom = import('customEntities');
	if(is_null(@custom)) {
		@custom = yml_decode(read('custom.yml'));
		export('customEntities', @custom);
	}
	return(@custom);
}

@entityTypes =  reflect_pull('enum', 'EntityType');
foreach(@index: @type in @entityTypes) {
	@type = to_lower(string(@type));
	if(@type !== 'player' && @type !== 'fishing_hook' && @type !== 'unknown') {
		@entityTypes[@index] = @type;
	} else {
		array_remove(@entityTypes, @index);
	}
}

@attributes = reflect_pull('enum', 'Attribute');
foreach(@index: @attribute in @attributes) {
	@attribute = to_lower(string(@attribute));
	if(!string_starts_with(@attribute, 'player_')
	&& @attribute !== 'generic_luck') {
		@attributes[@index] = replace(@attribute, 'generic_', '');
	} else {
		array_remove(@attributes, @index);
	}
}

@effects = reflect_pull('enum', 'PotionEffectType');
foreach(@index: @effect in @effects) {
	@effect = to_lower(string(@effect));
	if(@effect !== 'instant_damage' && @effect !== 'instant_health') {
		@effects[@index] = @effect;
	}
}

proc _entity_tabcompleter(@typeCompletions = @entityTypes, @attributeCompletions = @attributes, @effectCompletions = @effects) {
	@typeOrCustomCompletions = array_merge(array_keys(_get_custom_entities()), @typeCompletions);
	return _create_tabcompleter(
		array('list', 'info', 'createcustom', 'setcustom', 'modify', 'deletecustom', 'remove', 'spawn', 'patrol', 'reload'),
		array('<info|setcustom|deletecustom': array_keys(_get_custom_entities()),
			'<modify|remove': @typeCompletions,
			'<spawn|patrol': @typeOrCustomCompletions),
		array('<<setcustom|modify|deletecustom': array('type', 'name', 'age', 'health', 'lifetime', 'onfire', 'targetnear',
					'ai', 'tame', 'glowing', 'invulnerable', 'gravity', 'silent', 'gear', 'droprate', 'effect', 'tags',
					'attribute', 'rider', 'explode', 'scoreboardtags', 'velocity'),
			'<<createcustom': @typeCompletions,
			'<<remove': array('[range]')),
		array('<type': @typeCompletions,
			'<attribute': @attributeCompletions,
			'<effect': @effectCompletions,
			'<rider': @typeOrCustomCompletions,
			'<age': array('<ticks>'),
			'<health|droprate': array('<double>'),
			'<lifetime|onfire|explode': array('<seconds>'),
			'<ai|tame|glowing|invulnerable|gravity|silent': array('true', 'false'),
			'<velocity': array('<x>'),
			'<tags': array(
				'<<axolotl|frog|mushroom_cow|painting|rabbit|salmon': array('type'),
				'<<magma_cube|phantom|pufferfish|slime': array('size'),
				'<<area_effect_cloud': array('duration', 'durationonuse', 'particle', 'radius', 'radiusonuse',
					'radiuspertick', 'reapplicationdelay', 'waittime', 'color', 'potionmeta', 'source'),
				'<<arrow': array('critical', 'damage', 'piercelevel', 'pickup', 'potionmeta'),
				'<<armor_stand': array('arms', 'baseplate', 'marker', 'small', 'visible', 'poses'),
				'<<bee': array('anger', 'nector', 'stung'),
				'<<block_display': array('blockdata'),
				'<<cat|parrot': array('type', 'sitting'),
				'<<creeper': array('powered', 'maxfuseticks', 'explosionradius'),
				'<<donkey|mule': array('chest', 'domestication', 'jump', 'maxdomestication'),
				'<<dropped_item': array('pickupdelay', 'despawn', 'itemstack', 'owner', 'thrower'),
				'<<ender_crystal': array('base', 'beamtarget'),
				'<<ender_dragon': array('phase'),
				'<<ender_eye': array('despawnticks', 'drop', 'item', 'target'),
				'<<enderman': array('carried'),
				'<<experience_orb': array('amount'),
				'<<evoker_fangs': array('source'),
				'<<falling_block': array('dropitem', 'damage'),
				'<<fireball|dragon_fireball|small_fireball': array('direction'),
				'<<firework': array('strength', 'angled', 'effects'),
				'<<fox': array('sitting', 'crouching', 'type'),
				'<<goat': array('screaming'),
				'<<horse': array('color', 'jump', 'domestication', 'maxdomestication', 'style', 'saddle'),
				'<<interaction': array('width', 'height', 'response'),
				'<<iron_golem': array('playercreated'),
				'<<item_display': array('itemdisplay', 'item'),
				'<<item_frame|glow_item_frame': array('fixed', 'rotation', 'visible', 'item'),
				'<<llama|trader_llama': array('chest', 'domestication', 'maxdomestication', 'color', 'saddle'),
				'<<mannequin': array('immovable'),
				'<<minecart|minecart_furnace|minecart_hopper|minecart_mob_spawner|minecart_tnt': array('block', 'offset'),
				'<<minecart_command': array('block', 'offset', 'command', 'commandname'),
				'<<ominous_item_spawner': array('delay', 'item'),
				'<<panda': array('maingene', 'hiddengene', 'eating', 'onback', 'rolling', 'sneezing'),
				'<<pig|strider': array('saddled'),
				'<<piglin': array('baby', 'zombificationimmune'),
				'<<primed_tnt': array('fuseticks', 'source'),
				'<<sheep': array('color', 'sheared'),
				'<<shulker': array('color'),
				'<<shulker_bullet': array('target'),
				'<<skeleton_horse|zombie_horse': array('domestication', 'jump', 'maxdomestication', 'saddle'),
				'<<snowman': array('derp'),
				'<<spectral_arrow': array('critical', 'damage', 'glowingticks'),
				'<<splash_potion|lingering_potion': array('item'),
				'<<text_display': array('alignment', 'text', 'linewidth', 'shadow', 'seethrough', 'opacity', 'bgcolor'),
				'<<trident': array('critical', 'damage'),
				'<<tropical_fish': array('color', 'patterncolor', 'pattern'),
				'<<vex': array('charging'),
				'<<villager': array('profession', 'experience', 'level'),
				'<<wither_skull': array('charged', 'direction'),
				'<<wolf': array('angry', 'color', 'interested', 'sitting', 'type'),
				'<<zoglin': array('baby'),
				'<<zombie|drowned|husk': array('baby', 'breakdoors'),
				'<<zombie_villager': array('baby', 'profession', 'breakdoors'),
				'<<zombified_piglin ': array('anger', 'angry', 'baby', 'breakdoors'))),
		array('<<attribute': array('reset', '<value>'),
			'<<effect|explode': array('<strength>'),
			'<<velocity': array('<y>'),
			'<<tags': array(
				'<size|piercelevel|anger|explosionradius|domestication|maxdomestication|amount|strength|offset|experience|level': array('<int>'),
				'<duration|durationonuse|reapplicationdelay|waittime|maxfusetick|spickupdelay|despawnticks|delay|fuseticks': array('<ticks>'),
				'<radiuspertick|radius|radiusonuse|jump|width|height': array('<double>'),
				'<critical|arms|baseplate|marker|small|visible|nector|stung|sitting|powered|chest|despawn|base|drop|dropitem': array('true', 'false'),
				'<angled|crouching|screaming|playercreated|fixed|immovable|eating|onback|rolling|sneezing|saddled|baby': array('true', 'false'),
				'<zombificationimmune|sheared|derp|charging|charged|angry|interested|breakdoors': array('true', 'false'),
				null: array('<value>'))),
		array('<<<effect': array('[seconds]'),
			'<<<velocity': array('<z>'))
	);
}

register_command('entity', array(
	description: 'Custom entity management commands',
	usage: '/entity <action> [entity] [data...]',
	permission: 'command.entity',
	tabcompleter: _entity_tabcompleter(),
	executor: closure(@alias, @sender, @args) {
		if(!@args) {
			return(false);
		}
		switch(@args[0]) {
			case 'createcustom':
				if(array_size(@args) < 3) {
					die(color('gold').'Expected custom id and entity type.');
				}
				@id = @args[1];
				@type = @args[2];
				@custom = _get_custom_entities();
				if(array_index_exists(@custom, @id)) {
					die(color('red').'Custom entity already exists by the name: '.@id);
				}
				if(!array_contains_ic(@entityTypes, @type)) {
					die(color('red').'Unknown entity type: '.@type);
				}
				@custom[@id] = array(type: to_lower(@type));
				write_file('custom.yml', yml_encode(@custom, true), 'OVERWRITE');
				msg(color('green').'Created new custom '.@type.' entity called "'.@args[1].'".');
				set_tabcompleter('entity', _entity_tabcompleter());

			case 'setcustom':
			case 'modify':
				if(array_size(@args) < 3) {
					return(false);
				}
				@id = @args[1];
				@setting = @args[2];
				@custom = null;
				@entity = associative_array();
				@closestEntity = null;
				if(@args[0] === 'setcustom') {
					@custom = _get_custom_entities();
					if(!array_index_exists(@custom, @id)) {
						die(color('red').'Custom entity must be created first.');
					}
					@entity = @custom[@id];
				} else if(@args[0] === 'modify') {
					if(!array_contains_ic(@entityTypes, @id)) {
						die(color('red').'Unknown entity type: '.@id);
					}
					@loc = entity_loc(puuid());
					@closestDistance = 8;
					foreach(@e in entities_in_radius(@loc, 8, @id)) {
						@distance = distance(entity_loc(@e), @loc);
						if(@distance < @closestDistance) {
							@closestDistance = @distance;
							@closestEntity = @e;
						}
					}
					if(!@closestEntity) {
						die(color('gold').'Must be within 8 meters of a '.@id);
					}
				}
				switch(@setting) {
					case 'type':
						if(array_size(@args) == 3) {
							return(false);
						}
						@type = @args[3];
						if(!array_contains_ic(@entityTypes, @type)) {
							die(color('red').'Unknown entity type: '.@type);
						}
						if(@args[0] === 'modify') {
							die(color('red').'Cannot modify the type of a spawned in entity.');
						}
						@entity['type'] = to_lower(@type);
						msg(color('green').'Entity type set to: '.@type);

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
						msg(color('green').'Set '.@setting.' to '.@entity[@setting]);

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
						msg(color('green').'Set '.@setting.' to '.@entity[@setting]);

					case 'gear':
						@entity['gear'] = array(
							weapon: pinv(player(), 0),
							off_hand: pinv(player(), -106),
							helmet: pinv(player(), 103),
							chestplate: pinv(player(), 102),
							leggings: pinv(player(), 101),
							boots: pinv(player(), 100)
						);
						msg(color('green').'Gear set.');

					case 'droprate':
						if(array_size(@args) == 4) {
							@entity['droprate'] = array(
								weapon: double(@args[3]),
								off_hand: double(@args[3]),
								boots: double(@args[3]),
								leggings: double(@args[3]),
								chestplate: double(@args[3]),
								helmet: double(@args[3])
							);
						} else if(array_size(@args) == 9) {
							@entity['droprate'] = array(
								weapon: double(@args[3]),
								off_hand: double(@args[4]),
								boots: double(@args[5]),
								leggings: double(@args[6]),
								chestplate: double(@args[7]),
								helmet: double(@args[8]),
							);
						} else {
							return(false);
						}
						msg(color('green').'Droprate set.');

					case 'effect':
						if(array_size(@args) < 5) {
							return(false);
						}
						@effectid = @args[3];
						if(!array_index_exists(@entity, 'effects')) {
							@entity['effects'] = associative_array();
						}
						@strength = integer(@args[4]) - 1;
						@duration = -1.0;
						if(array_size(@args) > 5) {
							@duration = double(@args[5]);
						}
						if(array_index_exists(@entity['effects'], @effectid)) {
							if(@duration == 0) {
								array_remove(@entity['effects'], @effectid);
								msg(color('green').'Effect removed');
							} else {
								@entity['effects'][@effectid]['strength'] = @strength;
								@entity['effects'][@effectid]['seconds'] = @duration;
								msg(color('green').'Effect modified');
							}
						} else {
							@entity['effects'][@effectid] = array(
								strength: @strength,
								seconds: @duration
							);
							msg(color('green').'Effect added');
						}

					case 'tags':
						if(array_size(@args) < 4) {
							return(false);
						}
						@entry = @args[3];
						if(@entry[0] == '{') {
							@entity[@setting] = json_decode(array_implode(@args[3..-1]));
							msg(color('green').'Set '.@setting.' to '.@entity[@setting]);
						} else {
							if(!array_index_exists(@entity, 'tags')) {
								@entity['tags'] = associative_array();
							}
							@argument = @args[4];
							if(array_size(@args) > 5) {
								@argument = array_implode(@args[4..-1]);
							}
							@value = json_decode(@argument);
							if(is_null(@argument)) { // simple string
								@value = @argument;
							}
							@entity['tags'][@entry] = @value;
							msg(color('green').'Set '.@entry.' in tags to '.@value);
						}

					case 'attribute':
						if(array_size(@args) < 5) {
							return(false);
						}
						@attribute = @args[3];
						@value = @args[4];
						if(!array_index_exists(@entity, 'attributes')) {
							@entity['attributes'] = associative_array();
						}
						switch(@attribute) {
							case 'zombie_spawn_reinforcements':
							case 'tempt_range':
							case 'camera_distance':
							case 'waypoint_transmit_range':
							case 'waypoint_receive_range':
								noop();
							default:
								@attribute = 'generic_'.@attribute;
						}
						if(@value === 'reset') {
							if(@args[0] === 'setcustom') {
								array_remove(@entity['attributes'], to_upper(@attribute));
							} else {
								reset_entity_attribute_base(@closestEntity, to_upper(@attribute));
							}
							msg(color('green').'Reset '.@attribute);
						} else {
							@entity['attributes'][to_upper(@attribute)] = @value;
							msg(color('green').'Set attribute '.@attribute.' to '.@value);
						}

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
				if(@args[0] === 'setcustom') {
					write_file('custom.yml', yml_encode(@custom, true), 'OVERWRITE');
				} else {
					_modify_entity(@closestEntity, @entity, entity_loc(@closestEntity));
				}

			case 'deletecustom':
				if(array_size(@args) < 2) {
					return(false);
				}
				@id = @args[1];
				@custom = _get_custom_entities();
				if(!array_index_exists(@custom, @id)) {
					die(color('yellow').'Custom entity does not exist: '.@id);
				}
				if(array_size(@args) > 3) {
					@setting = @args[2];
					@key = @args[3];
					@entity = @custom[@id];
					if(!array_index_exists(@entity, @setting)) {
						die(color('yellow').'No data exists for '.@setting);
					}
					switch(@setting) {
						case 'effect':
							@setting .= 's';
							if(!array_index_exists(@entity[@setting], @key)) {
								die(color('gold').'Custom attribute setting did not exist: '.@key);
							}
							array_remove(@entity[@setting], @key);
							msg(color('green').'Removed '.@key.' from entity attributes.');
						case 'attribute':
							@setting .= 's';
							switch(@key) {
								case 'zombie_spawn_reinforcements':
								case 'tempt_range':
								case 'camera_distance':
								case 'waypoint_transmit_range':
								case 'waypoint_receive_range':
									noop();
								default:
									@key = 'generic_'.@key;
							}
							@key = to_upper(@key);
							if(!array_index_exists(@entity[@setting], @key)) {
								die(color('gold').'Custom attribute setting did not exist: '.@key);
							}
							array_remove(@entity[@setting], @key);
							msg(color('green').'Removed '.@key.' from entity attributes.');
						default:
							die(color('gold').'Too many arguments for '.@setting);
					}
					if(!@entity[@setting]) {
						array_remove(@entity, @setting);
						msg(color('green').@setting.' deleted from '.@id);
					}
					write_file('custom.yml', yml_encode(@custom, true), 'OVERWRITE');
				} else if(array_size(@args) > 2) {
					@setting = @args[2];
					@entity = @custom[@id];
					if(@setting === 'effect' || @setting === 'attribute') {
						@setting .= 's';
					}
					array_remove(@entity, @setting);
					write_file('custom.yml', yml_encode(@custom, true), 'OVERWRITE');
					msg(color('green').@setting.' deleted from '.@id);
				} else {
					array_remove(@custom, @id);
					write_file('custom.yml', yml_encode(@custom, true), 'OVERWRITE');
					msg(color('green').'Custom entity deleted.');
					set_tabcompleter('entity', _entity_tabcompleter());
				}

			case 'info':
				if(array_size(@args) < 2) {
					return(false);
				}
				@id = @args[1];
				@custom = _get_custom_entities();
				if(!array_index_exists(@custom, @id)) {
					die(color('red').'Custom entity does not exist.');
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

			case 'remove':
				if(array_size(@args) < 2) {
					die(color('yellow').'Requires an entity type to remove the closest one.'
						.' If a range is provided, all entities matching the type within range will be removed.');
				}
				@id = @args[1];
				if(!array_contains_ic(@entityTypes, @id)) {
					die(color('red').'Unknown entity type: '.@id);
				}
				@loc = entity_loc(puuid());
				if(array_size(@args) > 2) {
					@range = integer(@args[2]);
					@count = 0;
					foreach(@e in entities_in_radius(@loc, @range, @id)) {
						entity_remove(@e);
						@count++;
					}
					msg(color('green').'Removed '.@count.' entities within '.@range.' meters');
				} else {
					@closestEntity = null;
					@closestDistance = 8;
					foreach(@e in entities_in_radius(@loc, 8, @id)) {
						@distance = distance(entity_loc(@e), @loc);
						if(@distance < @closestDistance) {
							@closestDistance = @distance;
							@closestEntity = @e;
						}
					}
					if(!@closestEntity) {
						die(color('gold').'Must be within 8 meters of a '.@id);
					}
					entity_remove(@closestEntity);
					msg(color('green').'Removed entity.');
				}

			case 'patrol':
				if(array_size(@args) < 3) {
					die('Takes an entity type (with optional json) or a vanilla entity selector, followed by relative coords.'
						.' Directions are space separated relative coordinate directions and distances to target location.'
						.' They start with a coordinate followed by a number, and can be combined with commas.'
						.' For example: "x2,z-2 z1 x-2 z1".'
						.' In addition you can use "w20" to wait 20 ticks, or "s1.0" to change the speed to 1.0 m/s.');
				}
				@loc = get_command_block();
				if(!@loc) {
					return(false);
				}
				@id = @args[1];
				@data = array_get(@args, 2, null);
				@offset = 0;
				@entity = null;
				@directions = null;
				if(@id[0] === '@') {
					@entities = select_entities(@id);
					if(!@entities) {
						die();
					}
					@entity = @entities[0];
					@loc = entity_loc(@entity);
					@directions = @args[cslice(2, -1)];
				} else {
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
				}

				@speed = 0.1
				@living = is_entity_living(@entity);
				if(@living) {
					@speed = entity_attribute_value(@entity, 'GENERIC_MOVEMENT_SPEED') / 2.1585; // meters/tick
				}

				@target = @loc[];
				@target['w'] = 0;
				@target['s'] = @speed;
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
						set_entity_loc(@entity, location_shift(@loc, @target, min(@distance, @target['s'])));
						if(@distance <= @target['s']) {
							// if target was within reach in this tick, queue any remaining directions
							if(!@directions) {
								clear_task();
								if(is_array(@id) || @id[0] !== '@') {
									foreach(@ent in get_entity_riders(@entity)) {
										try(entity_remove(@ent));
									}
									entity_remove(@entity);
								}
								return();
							}
							@next = array_remove(@directions, 0);
							foreach(@axis in split(',', @next)) {
								@coord = @axis[0];
								if(@coord === 's') {
									@target[@coord] = @axis[1..-1];
								} else {
									@target[@coord] += @axis[1..-1];
								}
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
				msg('/entity spawn <entity> [json]'.color('gray').'Spawns entity where you are looking');
				msg('/entity patrol <entity [~x ~y ~z]|selector> <directions...>'.color('gray').'Direct a new or existing entity');
				msg('/entity reload '.color('gray').'Reloads custom entities from YML configuration.');

		}
	}
));
