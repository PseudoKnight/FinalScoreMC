execute(iclosure(){
	proc _opposite_portal(@portals, @color) {
		return(@portals[if(@color == 'orange', 'blue', 'orange')]);
	}

	proc _map_id(@color) {
		return(if(@color == 'orange', 1314, 1317));
	}

	proc _portal_to(@portals, @color, @ploc, @dist) {
		@yaw = @ploc['yaw'];
		@pitch = @ploc['pitch'];
		@entrance = @portals[@color]['exit'];
		@exit = _opposite_portal(@portals, @color)['exit'];
		if(!is_null(@entrance['yaw']) && !is_null(@exit['yaw'])) {
			@yaw += @exit['yaw'] - @entrance['yaw'] + 180;
		}
		if(!is_null(@entrance['pitch']) && @entrance['pitch'] == @exit['pitch']) {
			@pitch = neg(@pitch);
		}
		@newLoc = array(@exit['x'], @exit['y'], @exit['z'], @exit['world'], @yaw, @pitch);
		if(@entrance['pitch'] == -90.0 || @exit['pitch'] == -90.0) {
			set_ploc(location_shift(@newLoc, 'down'));
		} else {
			relative_teleport(@newLoc);
		}
		play_sound(@newLoc, array(sound: 'ENTITY_ILLUSIONER_MIRROR_MOVE', volume: 0.3));
		play_sound(@newLoc, array(sound: 'ENTITY_ILLUSIONER_CAST_SPELL', volume: 0.3));
		@v = get_vector(@exit, @dist);
		set_pvelocity(@v);
		set_timeout(10, closure(set_pvelocity(@v)));
	}

	proc _portal(@color, @portals) {
		if(pworld() != 'dev' || pmode() != 'ADVENTURE') {
			return(false);
		}

		if(!has_bind('portalgun'.player())) {
			bind('player_move', array(id: 'portalgun'.player()), array(player: player(), threshold: 0), @event, @portals) {
				@from = @event['from'];
				@to = @event['to'];
				if(@to['world'] != 'dev' || pmode() != 'ADVENTURE') {
					set_timeout(1, iclosure(unbind())); // syncs to work around concurrency exception
					foreach(@color in array('orange', 'blue')) {
						if(is_null(@portals[@color])) {
							continue();
						}
						foreach(@e in @portals[@color]['entities']) {
							if(entity_exists(@e)) {
								entity_remove(@e);
							}
						}
						@portals[@color] = null;
					}
					die();
				}
				if(!@portals['orange'] || !@portals['blue']) {
					die();
				}
				set_entity_fall_distance(puuid(), 0);
				@dist = distance(@from, @to);
				if(@dist > 2) {
					// Problem: I think a player_move event is called when teleporting.
					// Die here to avoid loops.
					// Could use better detection to allow higher velocities.
					die();
				}
				@loc = @to[];
				@loc['yaw'] = get_yaw(@from, @to);
				@loc['pitch'] = get_pitch(@from, @to);
				if(@loc['yaw'] == math_const('NaN')) {
					@loc['yaw'] = @to['yaw']; // fallback to old yaw
				}
				@trace = ray_trace(@loc, @dist * 2 + 0.5);
				if(!@trace['hitblock']) {
					die();
				}
				@block = @trace['block'];
				foreach(@color in array('orange', 'blue')) {
					@b = @portals[@color]['blocks'][0];
					if(is_array(@b) && array_subset_of(@block, @b)) {
						_portal_to(@portals, @color, @to, @dist);
						die();
					}
				}
			}
		}

		// visual range is 48 for item frames.
		// consider limiting it to this distance,
		// or have a fallback to fake blocks when players wander outside of range.
		@trace = ray_trace(72);

		if(!@trace['hitblock']) {
			play_sound(ploc(), array(sound: 'ENTITY_SHULKER_CLOSE'));
			return(true);
		}

		@block = @trace['block'];
		@origin = location_shift(@trace['origin'], 'down', 0.3);
		@loc = @trace['location'];
		@face = @trace['hitface'];

		@portal = @block[];

		@portal['x'] += 0.5;
		@portal['z'] += 0.5;

		@extension = null;
		if(@face != 'UP' && @face != 'DOWN') {
			@portal = location_shift(@portal, @face);
			if(round(@loc['y']) == floor(@loc['y']) && get_block(location_shift(@portal, 'down')) == 'AIR') {
				@extension = location_shift(@block, 'down', 0); // consistent arrays
				@block = location_shift(@block, 'down');
				@portal['y'] -= 1;
			} else if(get_block(location_shift(@portal, 'up')) == 'AIR') {
				@block = location_shift(@block, 'down', 0); // consistent arrays
				@extension = location_shift(@block, 'up');
			} else {
				play_sound(ploc(), array(sound: 'ENTITY_SHULKER_CLOSE'));
				return(true);
			}
		} else if(@face == 'UP') {
			@portal['y'] += 1;
		} else if(@face == 'DOWN') {
			@portal['y'] -= 2;
		}

		if(get_block(@block) != 'WHITE_CONCRETE' || @extension && get_block(@extension) != 'WHITE_CONCRETE') {
			play_sound(ploc(), array(sound: 'ENTITY_SHULKER_CLOSE'));
			return(true);
		}

		switch(@face) {
			case 'NORTH':
				@portal['yaw'] = 180;
				@portal['pitch'] = null;
			case 'SOUTH':
				@portal['yaw'] = 0;
				@portal['pitch'] = null;
			case 'EAST':
				@portal['yaw'] = 270;
				@portal['pitch'] = null;
			case 'WEST':
				@portal['yaw'] = 90;
				@portal['pitch'] = null;
			case 'UP':
				@portal['yaw'] = null;
				@portal['pitch'] = -90;
			case 'DOWN':
				@portal['yaw'] = null;
				@portal['pitch'] = 90;
		}

		@oppositePortal = _opposite_portal(@portals, @color);
		if(@oppositePortal) {
			if(@oppositePortal['exit']['yaw'] == @portal['yaw'] && @oppositePortal['exit']['pitch'] == @portal['pitch']) {
				foreach(@b in @oppositePortal['blocks']) {
					if(@b && (array_subset_of(@b, @block) || @extension && array_subset_of(@b, @extension))) {
						play_sound(ploc(), array(sound: 'ENTITY_SHULKER_CLOSE'));
						return(true);
					}
				}
			}
		}

		// clean up old portal frames before modifying the portals array
		if(@portals[@color]) {
			foreach(@e in @portals[@color]['entities']) {
				if(entity_exists(@e)) {
					entity_remove(@e);
				}
			}
		}

		@portals[@color] = array(exit: @portal, blocks: array(@block, @extension), entities: array());

		// play effects
		play_sound(@loc, array(sound: 'ENTITY_SHULKER_SHOOT', pitch: 1.3, volume: 3));
		@particleLoc = location_shift(@block, @face, 0.55);
		@particleLoc['x'] += 0.5;
		@particleLoc['y'] += 0.5;
		@particleLoc['z'] += 0.5;
		spawn_particle(@particleLoc, array(
			particle: 'BLOCK_DUST', 
			count: 20, 
			xoffset: if(@face != 'EAST' && @face != 'WEST', 0.7, 0.0),
			zoffset: if(@face != 'NORTH' && @face != 'SOUTH', 0.7, 0.0),
			yoffset: if(@face != 'UP' && @face != 'DOWN', 0.7, 0.0),
			block: @color.'_concrete'
		));

		// render particle trail
		@distance = distance(@origin, @loc);
		@maxParticles = min(ceil(@distance * 2), 48);
		@distance /= @maxParticles;
		@particles = 0;
		while(@particles++ <= @maxParticles) {
			@origin = location_shift(@origin, @loc, @distance);
			spawn_particle(@origin, array(particle: 'FALLING_DUST', block: @color.'_concrete'));
		}

		// set new portal frames
		@modify = closure(@e){
			set_entity_spec(@e, array(
				fixed: true,
				item: array(name: 'FILLED_MAP', meta: array(mapid: _map_id(@color))),
			));
			set_hanging_direction(@e, @face);
			@portals[@color]['entities'][] = @e;
		}

		@itemFrame = spawn_entity('ITEM_FRAME', 1, location_shift(@block, @face), @modify)[0];
		set_entity_glowing(@itemFrame, true);
		team_add_player(@color, @itemFrame);
		if(@extension) {
			@itemFrame = spawn_entity('ITEM_FRAME', 1, location_shift(@extension, @face), @modify)[0];
			set_entity_glowing(@itemFrame, true);
			team_add_player(@color, @itemFrame);
		}

		// special case if they shoot right below a player
		if(@face == 'UP') {
			@otherPortal = _opposite_portal(@portals, @color);
			if(@otherPortal && distance(location_shift(ploc(), 'up'), @portal)  < 0.5) {
				_portal_to(@portals, @color, ploc(), 0.15);
			}
		}

		@edges = array();
		@loc = location_shift(@block, @face, 0.05);
		if(@face == 'UP' || @face == 'DOWN') {
			if(@face == 'UP') {
				@loc['y'] += 1.0;
			}
			@loc['dir'] = 'south';
			@edges[] = @loc[];
			@loc['x'] += 1.0;
			@edges[] = @loc[];
			@loc['dir'] = 'east';
			@loc['x'] -= 1.0;
			@edges[] = @loc[];
			@loc['z'] += 1.0;
			@edges[] = @loc[];
		} else {
			if(@face == 'EAST') {
				@loc['x'] += 1.0;
			} else if(@face == 'SOUTH') {
				@loc['z'] += 1.0;
			}
			@loc['dir'] = 'up';
			@edges[] = @loc[];
			@loc['y'] += 1;
			@edges[] = @loc[];
			if(@face == 'EAST' || @face == 'WEST') {
				@loc['z'] += 1;
				@edges[] = @loc[];
				@loc['y'] -= 1;
				@edges[] = @loc[];
				@loc['z'] -= 1;
				@loc['dir'] = 'south';
			} else {
				@loc['x'] += 1;
				@edges[] = @loc[];
				@loc['y'] -= 1;
				@edges[] = @loc[];
				@loc['x'] -= 1;
				@loc['dir'] = 'east';
			}
			@edges[] = @loc[];
			@loc['y'] += 2;
			@edges[] = @loc[];
		}
		set_interval(50, closure(){
			if(!entity_exists(@itemFrame)) {
				clear_task();
			} else {
				foreach(@edge in @edges) {
					@loc = location_shift(@edge, @edge['dir'], rand());
					spawn_particle(@loc, array(particle: 'REDSTONE', color: @color));
				}
			}
		});


		return(true);
	}

	@portals = array(
		'orange': null,
		'blue': null,
	);

	if(!array_index_exists(get_teams(), 'orange')) {
		create_team('orange');
		create_team('blue');
		set_team_display('orange', array(color: 'GOLD'));
		set_team_display('blue', array(color: 'BLUE'));
	}

	bind('player_interact', array(priority: 'LOW'), array(itemname: 'LANTERN'), @event, @portals) {
		if(!pcooldown('LANTERN')) {
			if(_portal('orange', @portals)) {
				set_pcooldown('LANTERN', 5);
			}
		}
	}

	bind('player_interact', array(priority: 'LOW'), array(itemname: 'SOUL_LANTERN'), @event, @portals) {
		if(!pcooldown('SOUL_LANTERN')) {
			if(_portal('blue', @portals)) {
				set_pcooldown('SOUL_LANTERN', 5);
			}
		}
	}

});