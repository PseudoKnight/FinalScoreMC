execute(iclosure(){
	proc _portal(@color, @portals) {
		if(pworld() != 'dev' || pmode() != 'ADVENTURE') {
			return(false);
		}

		proc _rotate_exit(@portals, @color, @yaw, @pitch) {
			@entrance = @portals[@color]['exit'];
			@exit = @portals[if(@color == 'blue', 'orange', 'blue')]['exit'];
			if(!is_null(@entrance['yaw']) && !is_null(@exit['yaw'])) {
				@yaw += @exit['yaw'] - @entrance['yaw'] + 180;
			}
			if(!is_null(@entrance['pitch']) && @entrance['pitch'] == @exit['pitch']) {
				@pitch = neg(@pitch);
			}
			return(array(@exit['x'], @exit['y'], @exit['z'], @exit['world'], @yaw, @pitch));
		}

		if(!has_bind('portalgun'.player())) {
			bind('player_move', array(id: 'portalgun'.player()), array(player: player(), threshold: 0), @event, @portals) {
				@from = @event['from'];
				@to = @event['to'];
				if(@to['world'] != 'dev' || pmode() != 'ADVENTURE') {
					set_timeout(1, closure(unbind())); // syncs to work around concurrency exception
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
						@newLoc = _rotate_exit(@portals, @color, @to['yaw'], @to['pitch']);
						relative_teleport(@newLoc);
						play_sound(@newLoc, array(sound: 'ENTITY_ILLUSIONER_MIRROR_MOVE', volume: 0.3));
						play_sound(@newLoc, array(sound: 'ENTITY_ILLUSIONER_CAST_SPELL', volume: 0.3));
						@v = get_vector(@portals[if(@color == 'orange', 'blue', 'orange')]['exit'], @dist);
						set_pvelocity(@v);
						set_timeout(1, closure(set_pvelocity(@v)));
						die();
					}
				}
			}
		}

		@trace = ray_trace(48);

		if(!@trace['hitblock']) {
			play_sound(ploc(), array(sound: 'ENTITY_SHULKER_CLOSE'));
			return(true);
		}

		@block = @trace['block'];
		if(get_block(@block) != 'WHITE_CONCRETE') {
			play_sound(ploc(), array(sound: 'ENTITY_SHULKER_CLOSE'));
			return(true);
		}

		@origin = location_shift(@trace['origin'], 'down', 0.3);
		@loc = @trace['location'];
		@face = @trace['hitface'];

		@portal = @block[];

		@portal['x'] += 0.5;
		@portal['z'] += 0.5;

		@extension = null;
		if(@face != 'UP' && @face != 'DOWN') {
			@portal = location_shift(@portal, @face);
			if(round(@loc['y']) == floor(@loc['y'])) {
				@extension = @block;
				@block = location_shift(@block, 'down');
				@portal['y'] -= 1;
			} else {
				@extension = location_shift(@block, 'up');
			}
		} else if(@face == 'UP') {
			@portal['y'] += 1;
		} else if(@face == 'DOWN') {
			@portal['y'] -= 2;
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
		@maxParticles = min(ceil(@distance), 20);
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
				item: array(name: 'FILLED_MAP', meta: array(mapid: if(@color == 'orange', 1314, 1317))),
				visible: false,
			));
			set_hanging_direction(@e, @face);
			@portals[@color]['entities'][] = @e;
		}
		spawn_entity('ITEM_FRAME', 1, location_shift(@block, @face), @modify);
		if(@extension) {
			spawn_entity('ITEM_FRAME', 1, location_shift(@extension, @face), @modify);
		}

		// special case if they shoot right below a player
		if(@face == 'UP') {
			@otherColor = if(@color == 'orange', 'blue', 'orange');
			if(@portals[@otherColor]) {
				foreach(@p in players_in_radius(@portal, 0.7)) {
					@ploc = ploc();
					@newLoc = _rotate_exit(@portals, @color, @ploc['yaw'], @ploc['pitch']);
					relative_teleport(@newLoc);
					play_sound(@newLoc, array(sound: 'ENTITY_ILLUSIONER_MIRROR_MOVE', volume: 0.3));
					play_sound(@newLoc, array(sound: 'ENTITY_ILLUSIONER_CAST_SPELL', volume: 0.3));
					@v = get_vector(@portals[@otherColor]['exit'], 0.15);
					set_pvelocity(@v);
					set_timeout(1, closure(set_pvelocity(@v)));
				}
			}
		}

		return(true);
	}

	@portals = array(
		'orange': null,
		'blue': null,
	);

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