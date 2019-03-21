register_command('tornado', array(
	'description': 'Creates an entity tornado',
	'usage': '/tornado <centerHeight> <radius>',
	'permission': 'command.tornado',
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		return(array());
	},
	'executor': closure(@alias, @sender, @args, @info) {
		if(!pisop() || array_size(@args) < 2) {
			die();
		}
		@centerHeight = integer(@args[0]);
		@radius = integer(@args[1]);

		@loc = get_command_block();
		if(!all_players(@loc['world'])) {
			die();
		}

		@loc = location_shift(@loc, 'up', @centerHeight);
		@arc = to_radians(5);
		@entities = entities_in_radius(@loc, @radius);

		if(array_size(@entities) < 16) {
			@blockLoc = array(
				@loc['x'] + rand(5) - 2,
				@loc['y'] + rand(5) - @centerHeight, // starts at origin y
				@loc['z'] + rand(5) - 2,
				@loc['world']
			);
			@block = get_block(@blockLoc);
			if(@block != 'AIR' && get_block(location_shift(@blockLoc, 'up')) == 'AIR') {
				spawn_falling_block(location_shift(@blockLoc, 'up'), @block, array(0, 0.1, 0));
			}
		}

		foreach(@e in @entities) {
			@eLoc = entity_loc(@e);
			@type = entity_type(@e);
			@pull = -0.0;
			if(@type == 'PLAYER') {
				@dist = distance(@loc, @eLoc);
				if(@dist > @radius / 3) {
					@pull = -0.1;
				}
				play_sound(@eLoc, array('sound': 'ENTITY_HORSE_BREATHE', 'pitch': 2.0, 'volume': 0.05), @e);
				if(pinfo(@e, 18) || psneaking(@e)) {
					if(entity_grounded(@e) || @dist > @radius - 2) {
						stop_sound(@e, 'ITEM_ELYTRA_FLYING');
					}
					continue();
				}
				if(entity_grounded(@e)) {
					play_sound(@eLoc, array('sound': 'ITEM_ELYTRA_FLYING', 'volume': 0.4), @e);
				}
			} else if(@type == 'DROPPED_ITEM') {
				@dist = distance(@loc, @eLoc);
				if(@dist < @radius - 1) {
					set_entity_gravity(@e, false);
				} else {
					set_entity_gravity(@e, true);
				}
				@item = entity_spec(@e)['itemstack'];
				if(material_info(@item['name'], 'isBlock')) {
					spawn_particle(@eLoc, array('particle': 'FALLING_DUST', 'block': @item['name']));
				}
			} else if(@type == 'FALLING_BLOCK') {
				@dist = distance(@loc, @eLoc);
				if(@dist > @radius - 1) {
					entity_remove(@e);
					continue();
				} else {
					set_entity_gravity(@e, false);
				}
				spawn_particle(@eLoc, array('particle': 'FALLING_DUST', 'block': entity_spec(@e)['block']));
				@eLoc['y'] -= 6;
				@pull = 0.06;
			} else {
				spawn_particle(@eLoc, 'CLOUD');
			}
			@height = @loc['y'] - @eLoc['y'];
			@eLoc['y'] = @loc['y'];
			@dist = distance(@loc, @eLoc) + @pull;
			@yaw = to_radians(get_yaw(@loc, @eLoc) + 90);
			@vector = array(
				@dist * cos(@yaw + @arc) + @loc['x'] - @eLoc['x'],
				(@height + @dist - @radius) / 32,
				@dist * sin(@yaw + @arc) + @loc['z'] - @eLoc['z'],
			);
			set_entity_velocity(@e, @vector);
		}
	}
));
