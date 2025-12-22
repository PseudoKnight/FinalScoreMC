register_command('boats', array(
	description: 'Boats!',
	usage: '/boats <type> <carousel|spin|spiral|tower> [data]',
	permission: 'command.boats',
	tabcompleter: _create_tabcompleter(
		array('acacia', 'birch', 'cherry', 'dark_oak', 'jungle', 'mangrove', 'oak', 'pale_oak', 'random', 'spruce'),
		array('carousel', 'spin', 'spiral', 'tower'),
		array('<tower': array('[radius:4]'),
			'<spiral': array('[radius:10]'),
			'<carousel': array('[radius:8]'),
			'<spin': array('[size:15')),
		array('<<tower': array('[height:15]'))
	),
	executor: closure(@alias, @sender, @args, @info) {
		@type = to_upper(@args[0]);
		if(@type === 'RANDOM') {
			@type = array_get_rand(array('ACACIA', 'BIRCH', 'CHERRY', 'DARK_OAK', 'JUNGLE',
					'MANGROVE', 'OAK', 'PALE_OAK', 'SPRUCE'));
		}
		if(@args[1] === 'tower') {
			@target = get_command_block();
			if(!@target) {
				@target = ploc();
			}
			@world = @target['world'];
			@radius = integer(array_get(@args, 2, 4));
			@circle = array();
			@height = integer(array_get(@args, 3, 15));
			@h = 1;
			@offset = 0;
			for(@j = 1, @j < @height, @j++) {
				if(@offset == 0.35) {
					@offset = 0;
				} else {
					@offset = 0.35;
				}
				for(@angle = 0, @angle < 6.28, @angle += 0.7) {
					@circle[] = array(
						@radius * cos(@angle + @offset) + @target['x'],
						@target['y'] + @h,
						@radius * sin(@angle + @offset) + @target['z'],
						@world,
						to_degrees(@angle + @offset),
						0.0,
					);
				}
				@h++;
			}
			@i = array(0);
			set_interval(50, closure(){
				if(array_index_exists(@circle, @i[0])) {
					spawn_entity(@type.'_BOAT', 1, @circle[@i[0]], closure(@e) {
						set_entity_saves_on_unload(@e, false);
					});
					@i[0]++;
				} else {
					clear_task();
				}
			});
		} else if(@args[1] === 'spiral') {
			@target = get_command_block();
			if(!@target) {
				@target = ploc();
			}
			@world = @target['world'];
			@radius = integer(array_get(@args, 2, 10));
			@circle = array();
			@height = 0;
			for(@j = 1, @j < 3, @j++) {
				for(@angle = 0, @angle < 6.28, @angle += 0.1) {
					@circle[] = array(
						@radius * cos(@angle) + @target['x'],
						@target['y'] + @height,
						@radius * sin(@angle) + @target['z'],
						@world,
						to_degrees(@angle),
						0.0,
					);
					@angle2 = @angle + 2.1;
					@circle[] = array(
						@radius * cos(@angle2) + @target['x'],
						@target['y'] + @height,
						@radius * sin(@angle2) + @target['z'],
						@world,
						to_degrees(@angle2),
						0.0,
					);
					@angle3 = @angle2 + 2.1;
					@circle[] = array(
						@radius * cos(@angle3) + @target['x'],
						@target['y'] + @height,
						@radius * sin(@angle3) + @target['z'],
						@world,
						to_degrees(@angle3),
						0.0,
					);
					@height++;
					@radius -= 0.07;
					@radius = max(1, @radius);
				}
			}
			@i = array(0);
			set_interval(100, closure(){
				if(array_index_exists(@circle, @i[0])) {
					spawn_entity(@type.'_BOAT', 1, @circle[@i[0]], closure(@e) {
						set_entity_saves_on_unload(@e, false);
					});
					spawn_entity(@type.'_BOAT', 1, @circle[@i[0] + 1], closure(@e) {
						set_entity_saves_on_unload(@e, false);
					});
					spawn_entity(@type.'_BOAT', 1, @circle[@i[0] + 2], closure(@e) {
						set_entity_saves_on_unload(@e, false);
					});
					@i[0] += 3;
				} else {
					clear_task();
				}
			});
		} else if(@args[1] === 'spin') {
			@target = get_command_block();
			if(!@target) {
				@target = ptarget_space();
			} else {
				@target = _relative_coords(@target, @args[3], @args[4], @args[5]);
			}
			@boats = array();
			@stands = array();
			@size = integer(array_get(@args, 2, 15));
			@previous = null;
			@i = @size;
			do {
				@boat = spawn_entity(@type.'_BOAT', 1, @target, closure(@e) {
					set_entity_saves_on_unload(@e, false);
				})[0];
				if(@i > 1) {
					@stand = spawn_entity('ARMOR_STAND', 1, @target)[0];
					@stand2 = spawn_entity('ARMOR_STAND', 1, @target)[0];
					set_entity_spec(@stand, array('small': true, visible: false));
					set_entity_spec(@stand2, array('small': true, visible: false));
					add_scoreboard_tag(@stand, 'remove');
					add_scoreboard_tag(@stand2, 'remove');
					set_entity_rider(@boat, @stand);
					set_entity_rider(@boat, @stand2);
					@stands[] = @stand;
					@stands[] = @stand2;
					if(@previous) {
						set_entity_rider(@previous, @boat);
					}
					@previous = @stand2;
				} else if(@previous) {
					set_entity_rider(@previous, @boat);
				}
				@boats[] = @boat;
				@target = location_shift(@target, 'up');
			} while(--@i > 0)
			if(get_command_block()) {
				set_entity_rider(@boats[-1], puuid(_get_nearby_player(get_command_block(), 5)));
			}
			@segments = ceil(@size / 4);
			set_interval(50, closure(){
				try {
					@rotation = 1;
					@i = 0;
					@yaw = null;
					foreach(@boat in @boats) {
						@yaw = entity_loc(@boat)['yaw'];
						set_entity_rotation(@boat, @yaw + @rotation * integer(@i / @segments + 1), 0);
						if(++@i % @segments == 0) {
							@rotation = -@rotation;
						}
					}
				} catch(Exception @ex) {
					clear_task();
					foreach(@e in array_merge(@boats, @stands)) {
						try(entity_remove(@e))
					}
				}
			});
		} else if(@args[1] === 'carousel') {
			@target = get_command_block();
			@owner = null;
			if(!@target) {
				@target = location_shift(ploc(), 'up');
				@owner = player();
			} else {
				@target = _center(_relative_coords(@target, @args[3], @args[4], @args[5]), 0);
				@owner = players_in_radius(@target, 32)[0];
			}
			@world = @target['world'];
			@radius = integer(array_get(@args, 2, 8));
			@circle = array();
			for(@angle = 0, @angle < 6.28, @angle += 0.35) {
				@circle[] = array(
					@target['x'] + @radius * cos(@angle),
					@target['y'] + 6.9375,
					@target['z'] + @radius * sin(@angle),
					@world,
					to_degrees(@angle),
					0.0,
				);
			}
			@holders = array();
			@boats = array();
			@animals = array();
			foreach(@index: @point in @circle) {
				if(@index % 2) {
					continue();
				}
				@holder = spawn_entity('ITEM_DISPLAY', 1, @point, closure(@e) {
					set_entity_spec(@e, array(item: array(name: 'HEAVY_CORE')));
					set_entity_saves_on_unload(@e, false);
					set_display_entity(@e, array(teleportduration: 8));
				})[0];
				@boat = spawn_entity(@type.'_CHEST_BOAT', 1, location_shift(@point, 'down', 5.9375), closure(@e) {
					set_entity_saves_on_unload(@e, false);
				})[0];
				@animal = null;
				if(rand(2)) {
					@animal = spawn_entity('LLAMA', 1, location_shift(@point, 'down', 5.9375), closure(@e){
						set_entity_ai(@e, false);
						set_entity_silent(@e, true);
						set_mob_owner(@e, @owner);
						set_entity_saves_on_unload(@e, false);
						@color = array_get_rand(reflect_pull('enum', 'DyeColor'));
						set_mob_equipment(@e, array(body: array(name: @color.'_CARPET')));
					})[0];
				} else if(rand(2)) {
					@animal = spawn_entity('PIG', 1, location_shift(@point, 'down', 5.9375), closure(@e){
						set_entity_ai(@e, false);
						set_entity_silent(@e, true);
						set_entity_saves_on_unload(@e, false);
						set_mob_equipment(@e, array(saddle: array(name: 'SADDLE')));
					})[0];
				} else {
					@animal = spawn_entity('STRIDER', 1, location_shift(@point, 'down', 5.9375), closure(@e){
						set_entity_ai(@e, false);
						set_entity_silent(@e, true);
						set_entity_saves_on_unload(@e, false);
						set_mob_equipment(@e, array(saddle: array(name: 'SADDLE')));
					})[0];
				}
				set_entity_rider(@boat, @animal);
				set_leashholder(@boat, @holder);
				@holders[] = @holder;
				@boats[] = @boat;
				@animals[] = @animal;
			}
			@p = array(0);
			set_interval(400, closure(){
				try {
					@p[0]++;
					for(@i = 0, @i < array_size(@holders), @i++) {
						@holder = @holders[@i];
						@point = @circle[(@i * 2 + @p[0]) % array_size(@circle)];
						set_entity_loc(@holder, @point);
					}
				} catch(BadEntityException @ex) {
					clear_task();
					foreach(@entity in @boats) {
						try {
							set_leashholder(@entity, null);
							entity_remove(@entity);
						} catch(BadEntityException @ignore) {}
					}
					foreach(@entity in @animals) {
						try {
							entity_remove(@entity);
						} catch(BadEntityException @ignore) {}
					}
					foreach(@holder in @holders) {
						try(entity_remove(@holder))
					}
				}
			});
		}
	}
));
