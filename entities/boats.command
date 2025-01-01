register_command('boats', array(
	description: 'Boats!',
	usage: '/boats <tower|spiral|spin> [height]',
	permission: 'command.boats',
	tabcompleter: closure(return(array())),
	executor: closure(@alias, @sender, @args, @info) {
		if(@args[0] == 'tower') {
			@target = get_command_block();
			if(!@target) {
				@target = ploc();
			}
			@world = @target['world'];
			@radius = 4;
			@circle = array();
			@height = integer(array_get(@args, 1, 15));
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
					spawn_entity('OAK_BOAT', 1, @circle[@i[0]], closure(@e) {
						set_entity_saves_on_unload(@e, false);
					});
					@i[0]++;
				} else {
					clear_task();
				}
			});
		} else if(@args[0] == 'spiral') {
			@target = get_command_block();
			if(!@target) {
				@target = ploc();
			}
			@world = @target['world'];
			@radius = 10;
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
					spawn_entity('OAK_BOAT', 1, @circle[@i[0]], closure(@e) {
						set_entity_saves_on_unload(@e, false);
					});
					spawn_entity('OAK_BOAT', 1, @circle[@i[0] + 1], closure(@e) {
						set_entity_saves_on_unload(@e, false);
					});
					spawn_entity('OAK_BOAT', 1, @circle[@i[0] + 2], closure(@e) {
						set_entity_saves_on_unload(@e, false);
					});
					@i[0] += 3;
				} else {
					clear_task();
				}
			});
		} else if(@args[0] == 'spin') {
			@target = get_command_block();
			if(!@target) {
				@target = ptarget_space();
			} else {
				@target = _relative_coords(@target, @args[2], @args[3], @args[4]);
			}
			@boats = array();
			@stands = array();
			@size = integer(array_get(@args, 1, 15));
			@previous = null;
			@i = @size;
			do {
				@boat = spawn_entity('OAK_BOAT', 1, @target, closure(@e) {
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
		}
	}
));
