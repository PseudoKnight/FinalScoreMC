register_command('boats', array(
	'description': 'Boats!',
	'usage': '/boats [tower]',
	'permission': 'command.boats',
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		return(array());
	},
	'executor': closure(@alias, @sender, @args, @info) {
		@target = ploc();
		@world = pworld();
		if(@args[0] == 'tower') {
			@radius = 4;
			@circle = array();
			@height = integer(@args[1]);
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
					spawn_entity('BOAT', 1, @circle[@i[0]]);
					@i[0]++;
				} else {
					clear_task();
				}
			});
		} else if(@args[0] == 'spiral') {
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
					spawn_entity('BOAT', 1, @circle[@i[0]]);
					spawn_entity('BOAT', 1, @circle[@i[0] + 1]);
					spawn_entity('BOAT', 1, @circle[@i[0] + 2]);
					@i[0] += 3;
				} else {
					clear_task();
				}
			});
		} else if(@args[0] == 'spin') {
			@loc = ptarget_space();
			@previous = spawn_entity('BOAT', 1, @loc)[0];
			@boats = array(@previous);
			@stands = array();
			@size = integer(@args[1]);
			@i = @size;
			while(@i > 0) {
				@loc = location_shift(@loc, 'up');
				@boat = spawn_entity('BOAT', 1, @loc)[0];
				@stand = spawn_entity('ARMOR_STAND', 1, @loc)[0];
				set_entity_spec(@stand, array('small': true, 'visible': false));
				set_entity_rider(@previous, @boat);
				set_entity_rider(@boat, @stand);
				@boats[] = @boat;
				@stands[] = @stand;
				@previous = @stand;
				@i--;
			}
			
			set_interval(50, closure(){
				try {
					@add = 1;
					foreach(@boat in @boats) {
						if(@add == 1) {
							@add = -1;
						} else {
							@add = 1;
						}
						set_entity_rotation(@boat, entity_loc(@boat)['yaw'] + @add, 0);
					}
				} catch(BadEntityException @ex) {
					clear_task();
					foreach(@e in array_merge(@boats, @stands)) {
						try(entity_remove(@e));
					}
				}
			});
		}
	}
));
