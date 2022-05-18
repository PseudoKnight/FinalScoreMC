register_command('tornado', array(
	description: 'Creates an entity tornado',
	usage: '/tornado [radius=16]',
	permission: 'command.tornado',
	tabcompleter: closure(return(array())),
	executor: closure(@alias, @sender, @args, @info) {
		@radius = integer(array_get(@args, 0, 16));
		@loc = ptarget_space();
		@arc = to_radians(5);
		@oldEntities = array();

		set_interval(50, closure(){
			if(!players_in_radius(@loc, 64)) {
				clear_task();
				foreach(@e in @oldEntities) {
					try(set_entity_gravity(@e, true))
				}
				die();
			}

			@loc = location_shift(@loc, 'up', @radius / 2);
			@entities = entities_in_radius(@loc, @radius);

			if(array_size(@entities) < @radius) {
				@blockLoc = array(
					@loc['x'] + rand(5) - 2,
					@loc['y'] + rand(3) - 1 - @radius / 2, // ground level +-1
					@loc['z'] + rand(5) - 2,
					@loc['world']
				);
				@block = get_block(@blockLoc);
				if(@block != 'AIR' && get_block(location_shift(@blockLoc, 'up')) == 'AIR') {
					@droppedItem = drop_item(location_shift(@blockLoc, 'up'), array(name: @block, meta: array(display: time())), true);
					set_entity_spec(@droppedItem, array(pickupdelay: 6001));
					@oldEntities[] = @droppedItem;
				}
			}

			foreach(@i: @e in @oldEntities) {
				if(!array_contains(@entities, @e)) {
					try(set_entity_gravity(@e, true))
					array_remove(@oldEntities, @i);
				}
			}

			foreach(@e in @entities) {
				@eLoc = entity_loc(@e);
				@type = entity_type(@e);
				@pull = -0.0;
				if(@type == 'PLAYER') {
					@dist = distance(@loc, @eLoc);
					@grounded = entity_grounded(@e);
					if(@dist > @radius / 3) {
						@pull = -0.1;
					}
					play_sound(@eLoc, array(sound: 'ITEM_ELYTRA_FLYING', pitch: 2.0, volume: 0.05), @e);
					if(pflying(@e) || psneaking(@e)) {
						if(@grounded || @dist > @radius - 2) {
							stop_sound(@e, 'ITEM_ELYTRA_FLYING');
						}
						continue();
					}
					if(entity_grounded(@e)) {
						play_sound(@eLoc, array(sound: 'ITEM_ELYTRA_FLYING', volume: 0.4), @e);
					}
				} else if(@type == 'DROPPED_ITEM') {
					if(!array_contains(@oldEntities, @e)) {
						@oldEntities[] = @e;
					}
					@dist = distance(@loc, @eLoc);
					if(@dist < @radius - 1) {
						set_entity_gravity(@e, false);
					} else {
						set_entity_gravity(@e, true);
					}
					@item = entity_spec(@e)['itemstack'];
					if(material_info(@item['name'], 'isBlock')) {
						spawn_particle(@eLoc, array(particle: 'FALLING_DUST', block: @item['name']));
					}
				} else if(@type == 'FALLING_BLOCK') {
					if(!array_contains(@oldEntities, @e)) {
						@oldEntities[] = @e;
					}
					@dist = distance(@loc, @eLoc);
					if(@dist > @radius - 1) {
						entity_remove(@e);
						continue();
					} else {
						set_entity_gravity(@e, false);
					}
					spawn_particle(@eLoc, array(particle: 'FALLING_DUST', block: entity_spec(@e)['block']));
					@eLoc['y'] -= 6;
					@pull = 0.06;
				} else if(is_entity_living(@e)) {
					spawn_particle(@eLoc, 'CLOUD');
				} else {
					continue();
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

		});
	}
));
