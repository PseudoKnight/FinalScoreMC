proc _race_on_move(@player, @loc, @race) {}
proc _race_activate_item(@race, @player, @kart) {}

/**
 * Spawns a new kart.
 * Returns the array defining this kart object.
 */
array proc _kart_spawn(@loc, @player, @design = null, @camdist = 4.0) {
	string @engineBlock;
	string @color;
	string @wheels;
	if(@design) {
		@engineBlock = @design['engine'];
		@color = @design['color'];
		@wheels = @design['wheels'];
	} else {
		@engineBlock = array_get_rand(array('furnace', 'blast_furnace', 'smoker', 'copper_bulb',
				'exposed_copper_bulb', 'weathered_copper_bulb', 'oxidized_copper_bulb', 'redstone_lamp'));
		@color = string(array_get_rand(reflect_pull('enum', 'DyeColor')));
		@wheels = array_get_rand(array('BLACK_WOOL', 'BLACK_CONCRETE_POWDER'));
	}
	@kart = array(
		binds: array(),
		// kart design
		color: @color,
		engineBlock: @engineBlock,
		wheels: @wheels,
		// entity UUIDs
		collider: null,
		engine: null,
		frame: null,
		frontBumper: null,
		backBumper: null,
		frontAxle: null,
		backAxle: null,
		frontLeftTire: null,
		frontRightTire: null,
		backLeftTire: null,
		backRightTire: null,
		steeringColumn: null,
		steeringWheel: null,
		item: null,
		stand: null,
		mannequin: null,
		head: null,
		camera: null,
		// status
		loc: location_shift(@loc, 'up', 0),
		lastVelocity: array(x: 0, y: 0, z: 0, magnitude: 0.0),
		speed: 0.0,
		explode: false,
		camdist: @camdist,
		// previous inputs
		driftTurn: 0,
		// effects
		boost: array(strength: 0, ticks: 0),
	);

	// spawn entities
	@teleportduration = 2;
	@brightness = 15;
	@kart['collider'] = spawn_entity('ARMOR_STAND', 1, @loc, closure(@collider) {
		set_entity_saves_on_unload(@collider, false);
		set_entity_attribute_base(@collider, 'GENERIC_STEP_HEIGHT', 0.5);
		set_entity_spec(@collider, array(visible: false));
		set_entity_size(@collider, 1.5, 1.5);
		add_scoreboard_tag(@collider, 'kart_collider');
	})[0];
	@vehicle = spawn_entity('BLOCK_DISPLAY', 1, @loc, closure(@engineDisplay) {
		set_entity_saves_on_unload(@engineDisplay, false);
		set_entity_spec(@engineDisplay, array(blockdata: @engineBlock));
		set_display_entity(@engineDisplay, array(
			brightness: @brightness,
			teleportduration: @teleportduration,
			shadowradius: 0.6,
			transformation: array(
				translation: array(x: -0.39, y: 0.25, z: -0.56),
				scale: array(x: 0.78, y: 0.48, z: 0.34))));
	})[0];
	@kart['engine'] = @vehicle;

	@parts = array(
		frame: array(
			item: @color.'_SHULKER_BOX',
			translation: array(x: 0, y: 0.18, z: 0.275),
			scale: array(x: 0.9, y: 0.15, z: 1.85)),
		frontBumper: array(
			item: @color.'_SHULKER_BOX',
			translation: array(x: 0, y: 0.2, z: 1.275),
			scale: array(x: 1.44, y: 0.2, z: 0.15)),
		backBumper: array(
			item: @color.'_SHULKER_BOX',
			translation: array(x: 0, y: 0.2, z: -0.725),
			scale: array(x: 1.74, y: 0.2, z: 0.15)),
		frontAxle: array(
			block: 'GRAY_CONCRETE_POWDER',
			translation: array(x: -0.88, y: 0.2, z: 0.8),
			scale: array(x: 1.74, y: 0.1, z: 0.1)),
		backAxle: array(
			block: 'GRAY_CONCRETE_POWDER',
			translation: array(x: -0.92, y: 0.2, z: -0.4),
			scale: array(x: 1.84, y: 0.1, z: 0.1)),
		frontLeftTire: array(
			item: @wheels,
			translation: array(x: -0.72, y: 0.25, z: 0.85),
			scale: array(x: 0.2, y: 0.5, z: 0.5)),
		frontRightTire: array(
			item: @wheels,
			translation: array(x: 0.72, y: 0.25, z: 0.85),
			scale: array(x: 0.2, y: 0.5, z: 0.5)),
		backLeftTire: array(
			block: @wheels,
			translation: array(x: -0.87, y: 0.0, z: -0.6),
			scale: array(x: 0.25, y: 0.5, z: 0.5)),
		backRightTire: array(
			block: @wheels,
			translation: array(x: 0.62, y: 0.0, z: -0.6),
			scale: array(x: 0.25, y: 0.5, z: 0.5)),
		steeringColumn: array(
			block: 'GRAY_CONCRETE_POWDER',
			translation: array(x: -0.05, y: 0.569, z: 0.432),
			scale: array(x: 0.1, y: 0.1, z: 0.53),
			leftRotation: array(x: 0.347, y: 0.0, z: 0.0, w: 0.938)),
		steeringWheel: array(
			item: 'STRUCTURE_VOID',
			translation: array(x: 0, y: 0.62, z: 0.45),
			scale: array(x: 0.6, y: 0.6, z: 0.6),
			leftRotation: array(x: 0.347, y: 0.0, z: 0.0, w: 0.938)),
		item: array(
			item: 'AIR',
			translation: array(x: -0.7, y: 1.2, z: 0.0),
			scale: array(x: 0.9, y: 0.9, z: 0.9)),
	);
	foreach(@id: @data in @parts) {
		@type = if(array_index_exists(@data, 'item'), 'ITEM', 'BLOCK').'_DISPLAY';
		@kart[@id] = spawn_entity(@type, 1, @loc, closure(@entity){
			if(array_index_exists(@data, 'item')) {
				set_entity_spec(@entity, array(item: array(name: @data['item'])));
			} else {
				set_entity_spec(@entity, array(blockdata: @data['block']));
			}
			set_display_entity(@entity, array(
				brightness: @brightness,
				teleportduration: @teleportduration,
				transformation: @data,
			));
			set_entity_saves_on_unload(@entity, false);
		})[0];
		set_entity_rider(@vehicle, @kart[@id]);
	}

	// Rider
	@kart['stand'] = spawn_entity('ARMOR_STAND', 1, @loc, closure(@stand) {
		set_entity_saves_on_unload(@stand, false);
		set_entity_invulnerable(@stand, true);
		set_entity_attribute_base(@stand, 'GENERIC_SCALE', 0.3);
		set_entity_spec(@stand, array(smalL: true, visible: false));
	})[0];
	@kart['mannequin'] = spawn_entity('MANNEQUIN', 1, @loc, closure(@mannequin) {
		set_entity_saves_on_unload(@mannequin, false);
		set_entity_attribute_base(@mannequin, 'GENERIC_SCALE', 0.8);
	})[0];
	runas('~console', '/data modify entity '.@kart['mannequin'].' profile set value '.@player);
	set_entity_rider(@kart['stand'], @kart['mannequin']);
	set_entity_rider(@vehicle, @kart['stand']);
	@kart['head'] = spawn_entity('ITEM_DISPLAY', 1, @loc, closure(@head) {
		set_entity_saves_on_unload(@head, false);
		set_entity_spec(@head, array(item: array(name: 'PLAYER_HEAD', meta: array(owner: @player))));
		set_display_entity(@head, array(
			brightness: @brightness,
			teleportduration: @teleportduration,
			transformation: array(
				translation: array(x: 0.0, y: 0.26, z: 0.0),
				scale: array(x: 1.2, y: 1.2, z: 1.2),
				leftRotation: array(x: 0.0, y: 1.0, z: 0.0, w: 0.0))));
	})[0];
	set_entity_rider(@kart['mannequin'], @kart['head']);

	// Flag
	// set_entity_rider(@vehicle, spawn_entity('ITEM_DISPLAY', 1, @loc, closure(@flagpole) {
	// 	set_entity_spec(@flagpole, array(item: array(name: 'LIGHT_GRAY_CONCRETE_POWDER')));
	// 	set_display_entity(@flagpole, array(
	// 		brightness: @brightness,
	// 		teleportduration: @teleportduration,
	// 		transformation: array(
	// 			translation: array(x: -0.45, y: 1.1, z: -0.88),
	// 			scale: array(x: 0.04, y: 1.75, z: 0.04),
	// 			leftRotation: array(x: -0.1, y: 0.0, z: 0.0, w: 0.995))));
	// })[0]);
	// set_entity_rider(@vehicle, spawn_entity('ITEM_DISPLAY', 1, @loc, closure(@flag) {
	// 	set_entity_spec(@flag, array(item: array(name: @color.'_WOOL')));
	// 	set_display_entity(@flag, array(
	// 		brightness: @brightness,
	// 		teleportduration: @teleportduration,
	// 		transformation: array(
	// 			translation: array(x: -0.45, y: 1.78, z: -1.15),
	// 			scale: array(x: 0.03, y: 0.3, z: 0.3),
	// 			leftRotation: array(x: -0.1, y: 0.0, z: 0.0, w: 0.978))));
	// })[0]);

	@v = get_vector(@loc, @camdist);
	@cameraLoc = @loc[];
	@cameraLoc['x'] = @cameraLoc[0] - @v['x'];
	@cameraLoc['z'] = @cameraLoc[2] - @v['z'];
	@cameraLoc['y'] = @cameraLoc[1] + @camdist;
	@cameraLoc['world'] = @cameraLoc[3];
	@cameraLoc['yaw'] = @cameraLoc[4];
	@kart['camera'] = spawn_entity('BLOCK_DISPLAY', 1, @cameraLoc, closure(@camera){
		set_entity_saves_on_unload(@camera, false);
		set_display_entity(@camera, array(teleportduration: 2));
	})[0];
	@cameraLoc['pitch'] = get_pitch(@cameraLoc, @loc);
	set_entity_loc(puuid(@player), @cameraLoc);
	set_entity_rider(@kart['camera'], puuid(@player));
	set_peffect(@player, 'invisibility', 0, 1, true, false, false);
	set_pheld_slot(@player, 8);
	set_pinv(@player, 8, null);
	_kart_show_item(@player, @kart);
	@kart['binds'][] = bind('item_held', null, array(player: @player), @event) {
		cancel();
	}
	@kart['binds'][] = bind('entity_damage', null, array(id: puuid(@player), cause: 'SUFFOCATION'), @event) {
		cancel();
	}
	return(@kart);
}

proc _kart_remove(@player, @kart) {
	foreach(@bind in @kart['binds']) {
		unbind(@bind);
	}
	if(!entity_exists(@kart['engine'])) {
		return(); // already removed
	}
	foreach(@rider in get_entity_riders(@kart['engine'])) {
		entity_remove(@rider);
	}
	entity_remove(@kart['engine']);
	entity_remove(@kart['camera']);
	entity_remove(@kart['head']);
	entity_remove(@kart['mannequin']);
	try(entity_remove(@kart['stand'])) // may no longer be a rider
	try(entity_remove(@kart['collider'])) // may be destroyed
}

/**
 * Starts the kart interval tick.
 */
proc _kart_tick(@player, @kart, @race = null) {
	@driftAngle = 32.0;
	@minSpeed = 0.014;
	@maxSpeed = 1.5;

	@display = @kart['engine'];
	@collider = @kart['collider'];
	@engineBlock = @kart['engineBlock'];
	@leftTire = @kart['frontLeftTire'];
	@rightTire = @kart['frontRightTire'];
	@backLeftTire = @kart['backLeftTire'];
	@backRightTire = @kart['backRightTire'];
	@head = @kart['head'];
	@camera = @kart['camera'];

	set_interval(50, 0, closure(){
		if(!ponline(@player)) {
			clear_task();
			die();
		}
		if(pvehicle(@player) !== @camera) {
			try(_kart_remove(@player, @kart))
			clear_task();
			die();
		}
		if(!entity_exists(@display)) {
			clear_task();
			die();
		}
		
		if(@kart['explode'] || !entity_exists(@collider)) {
			clear_task();
			@components = get_entity_riders(@display);
			@components[] = @display;
			@loc = entity_loc(@display);
			set_display_entity(@display, array(teleportduration: 12));
			set_entity_loc(@display, location_shift(@loc, 'up', 1));
			@animationDurationTicks = 12;
			foreach(@entity in @components) {
				if(entity_type(@entity) !== 'ARMOR_STAND') {
					@translation = get_display_entity(@entity)['transformation']['translation'];
					set_display_entity(@entity, array(
						interpolationduration: @animationDurationTicks,
						startinterpolation: 0,
						transformation: array(
							translation: array(x: @translation['x'] * rand(4, 7), y: @translation['y'] * rand(4, 7), z: @translation['z'] * rand(4, 7)),
							leftRotation: array(x: rand() * 2 - 1, y: rand() * 2 - 1, z: rand() * 2 - 1, w: rand() * 2 - 1))));
				} else {
					set_entity_rider(null, @entity);
					@kart['lastVelocity']['y'] += 0.6;
					set_entity_velocity(@entity, @kart['lastVelocity']);
				}
			}
			spawn_particle(@loc, array(particle: 'EXPLOSION_HUGE'));
			play_sound(@loc, array(sound: 'ENTITY_GENERIC_EXPLODE', volume: @kart['camdist']));
			stop_sound(@player, 'ENTITY_BEE_LOOP');
			if(@race && get_block(location_shift(@loc, 'down')) !== 'AIR') {
				foreach(@otherplayer in array_keys(@race['players'])) {
					psend_block_change(@otherplayer, @loc, 'fire');
				}
			}
			set_timeout(@animationDurationTicks * 50, closure(){
				_kart_remove(@player, @kart);
				if(@race && array_index_exists(@race['players'], @player)) {
					_race_on_move(@player, @loc, @race);
				}
			});
			die();
		}

		@pfacing = pfacing(@player);
		set_peffect(@player, 'invisibility', 0, 1, true, false, false);

		// Get kart input
		@input = get_player_input(@player);
		@acceleration = 0;
		@turn = 0;
		if(@input['left'] && !@input['right']) {
			@turn = -1;
		} else if(@input['right']) {
			@turn = 1;
		}
		if(@input['forward'] && !@input['backward']) {
			@acceleration = 1;
		} else if(@input['backward']) {
			@acceleration = -1;
		}
		@drift = @input['sneak'];

		if(@race && @input['jump']) {
			_race_activate_item(@race, @player, @kart);
		}

		// Get location
		@age = get_entity_age(@collider);
		@loc = entity_loc(@collider);
		@pitch = entity_loc(@display)['pitch'];
		@currentVelocity = entity_velocity(@collider);

		// Interpolate pitch back to zero
		if(!equals_epsilon(@pitch, 0.0, 0.01)) {
			if(@pitch > 0) {
				@pitch *= 0.5;
			} else {
				@pitch *= 0.9;
			}
			if(equals_epsilon(@pitch, 0.0, 1.0)) {
				@pitch = 0.0;
			}
		}

		// Boost / reset yaw from drift turn
		if(!@drift && @acceleration > 0 && @kart['boost']['ticks'] > 40 && !@kart['boost']['strength']) {
			play_sound(@display, array(sound: 'BLOCK_RESPAWN_ANCHOR_DEPLETE', volume: @kart['camdist']));
			play_sound(@display, array(sound: 'ENTITY_GHAST_SHOOT', pitch: 0.5, volume: @kart['camdist']));
			@kart['boost'] = array(strength: 1, ticks: 20);
			set_entity_spec(@display, array(blockdata: @engineBlock.'[lit=true]'));
			@loc['yaw'] -= @kart['driftTurn'] * (@driftAngle / 2);
		} else if(@kart['driftTurn']) {
			@loc['yaw'] -= @kart['driftTurn'] * @driftAngle;
		}
		if(!@drift) {
			@kart['driftTurn'] = 0;
		} else {
			if(!@kart['driftTurn']) {
				@kart['driftTurn'] = @turn;
			}
		}

		// Handle velocity and yaw
		if(@kart['boost']['strength'] && @kart['boost']['ticks']) {
			@kart['boost']['ticks']--;
			if(!@kart['boost']['ticks']) {
				@kart['boost']['strength'] = 0;
				set_entity_spec(@display, array(blockdata: @engineBlock.'[lit=false]'));
			}
		} else if(@kart['driftTurn'] && @acceleration >= 1) {
			@kart['boost']['ticks']++;
		} else if(@kart['boost']['ticks']) {
			@kart['boost']['ticks']--;
		}
		if(@kart['boost']['strength']) {
			if(@kart['speed'] < @maxSpeed) {
				@kart['speed'] += 0.02 * @kart['boost']['strength'] * (@maxSpeed - @kart['speed']);
			}
		} else if(@acceleration > 0) {
			if(@kart['speed'] < 0.75 * @maxSpeed) {
				if(@drift) {
					@kart['speed'] += 0.007 * (0.75 * @maxSpeed - @kart['speed']);
				} else {
					@kart['speed'] += 0.014 * (0.75 * @maxSpeed - @kart['speed']);
				}
			}
		} else if(@acceleration < 0) {
			if(@kart['speed'] > -0.3) {
				if(@drift && @kart['speed'] > 0) {
					@kart['speed'] -= 0.04;
				} else {
					@kart['speed'] -= 0.02;
				}
			}
		} else {
			@kart['speed'] *= 0.97;
			if(abs(@kart['speed']) < @minSpeed) {
				@kart['speed'] = 0.0;
			}
		}
		if(@drift) {
			@loc['yaw'] += @turn + @kart['driftTurn'] * 2.4;
		} else if(@turn) {
			if(@kart['speed'] < 0) {
				@loc['yaw'] -= @turn * 2.4;
			} else {
				@loc['yaw'] += @turn * 2.4;
			}
		}
		if(@loc['yaw'] > 360) {
			@loc['yaw'] -= 360;
		} else if(@loc['yaw'] < 0) {
			@loc['yaw'] += 360;
		}
		play_sound(@display, array(
			sound: 'ENTITY_ARMADILLO_UNROLL_FINISH',
			pitch: 0.4 + @currentVelocity['magnitude'],
			volume: 1 - @currentVelocity['magnitude'],
			seed: 1));

		// Check collision
		@grounded = false;
		if(entity_grounded(@collider)) {
			@grounded = true;
			if(@currentVelocity['magnitude'] > 0.1 && !rand(20)) {
				play_sound(@display, array(
					sound: 'ENTITY_BEE_LOOP',
					pitch: 0.4 + @currentVelocity['magnitude'] * 1.2,
					volume: @kart['camdist'] / 1.8));
			}
			@lastVelocity = @kart['lastVelocity'];
			if(@currentVelocity['x'] == 0 && abs(@lastVelocity['x']) > 0.05) { // if velocity stopped on this axis
				if(abs(@kart['loc']['x'] - @loc['x']) < 0.01) { // if movement stopped on this axis
					@kart['lastVelocity'] = @currentVelocity;
					if(abs(@lastVelocity['x']) > abs(@lastVelocity['z'])) { // angle of collision
						if(abs(@lastVelocity['x']) > 0.3) { // magnitude of collision
							@kart['explode'] = true;
							@kart['lastVelocity'] = @lastVelocity;
						}
						stop_sound(@player, 'ENTITY_BEE_LOOP');
						@kart['speed'] = 0.0;
					} else { // still fast enough to deflect
						if(@lastVelocity['z'] > 0) {
							@loc['yaw'] = 0;
						} else if(@lastVelocity['z'] < 0) {
							@loc['yaw'] = 180;
						}
						@kart['speed'] *= 0.7;
					}
					play_named_sound(@display, array(
						sound: 'block.vault.break',
						pitch: 1.3 - @kart['speed'],
						volume: @kart['camdist'] / 3));
				}
			} else if(@currentVelocity['z'] == 0 && abs(@lastVelocity['z']) > 0.05) {
				if(abs(@kart['loc']['z'] - @loc['z']) < 0.01) {
					@kart['lastVelocity'] = @currentVelocity;
					if(abs(@lastVelocity['z']) > abs(@lastVelocity['x'])) {
						if(abs(@lastVelocity['z']) > 0.3) {
							@kart['explode'] = true;
							@kart['lastVelocity'] = @lastVelocity;
						}
						stop_sound(@player, 'ENTITY_BEE_LOOP');
						@kart['speed'] = 0.0;
					} else {
						if(@lastVelocity['x'] > 0) {
							@loc['yaw'] = 270;
						} else if(@lastVelocity['x'] < 0) {
							@loc['yaw'] = 90;
						}
						@kart['speed'] *= 0.7;
					}
					play_named_sound(@display, array(
						sound: 'block.vault.break',
						pitch: 1.3 - @kart['speed'],
						volume: @kart['camdist'] / 3));
				}
			} else {
				@kart['lastVelocity'] = @currentVelocity;
				if(@loc['y'] > @kart['loc']['y']) {
					@pitch = -(@loc['y'] - @kart['loc']['y']) * 35;
				}
			}
		} else {
			@pitch = @currentVelocity['y'] * 25 * if(@kart['speed'] > 0, -1, 1);
		}
		@loc['pitch'] = @pitch;
		@kart['loc'] = @loc[];

		// Get vector directions
		@forward = get_vector(array(yaw: @loc['yaw'], pitch: 0));
		@velocity = get_vector(array(yaw: @loc['yaw'], pitch: 0), @kart['speed']);
		@velocity['y'] = @currentVelocity['y'] * 0.9;
		@right = get_vector(array(yaw: @loc['yaw'] + 90, pitch: 0));

		// Move vehicle
		if(@drift) {
			@loc['yaw'] += @kart['driftTurn'] * @driftAngle;
		}
		set_display_entity(@leftTire, array(
			transformation: array(
				translation: array(x: -0.72, y: if(@age % 4 <= 1, 0.25, 0.23), z: 0.85),
				leftRotation: array(x: 0.0, y: -@turn * 0.1, z: 0.0, w: 1.0))));
		set_display_entity(@rightTire, array(
			transformation: array(
				translation: array(x: 0.72, y: if(@age % 4 <= 1, 0.25, 0.23), z: 0.85),
				leftRotation: array(x: 0.0, y: -@turn * 0.1, z: 0.0, w: 1.0))));
		set_entity_loc(@display, location_shift(@loc, 'up', if(@age % 4 <= 1, 0, 0.02)));
		set_entity_rotation(@collider, @loc['yaw']);
		set_entity_velocity(@collider, @velocity);

		// Rotate vehicle components
		@deltaYaw = @loc['yaw'] - @pfacing[0];
		if(@deltaYaw < -180) {
			@deltaYaw += 360;
		} else if(@deltaYaw > 180) {
			@deltaYaw -= 360;
		}
		set_entity_rotation(@head, @pfacing[0] + @deltaYaw / 1.8, 0);
		foreach(@rider in get_entity_riders(@display)) {
			set_entity_rotation(@rider, @loc['yaw'], @loc['pitch']);
		}

		// Spin tires
		if(@acceleration || !equals_epsilon(@kart['speed'], 0.0, @minSpeed)) {
			if(@acceleration && @age % 2 > 0 || !@acceleration && @age % 4 > 1) {
				set_display_entity(@backLeftTire, array(
					transformation: array(
						translation: array(x: -0.62, y: if(@age % 4 <= 1, 0, -0.02), z: -0.1),
						scale: array(x: -0.25, y: 0.5, z: -0.5))));
				set_display_entity(@backRightTire, array(
					transformation: array(
						translation: array(x: 0.87, y: if(@age % 4 <= 1, 0, -0.02), z: -0.1),
						scale: array(x: -0.25, y: 0.5, z: -0.5))));
			} else if(@acceleration && @age % 2 <= 0 || !@acceleration && @age % 4 <= 1) {
				set_display_entity(@backLeftTire, array(
					transformation: array(
						translation: array(x: -0.87, y: if(@age % 4 <= 1, 0, -0.02), z: -0.6),
						scale: array(x: 0.25, y: 0.5, z: 0.5))));
				set_display_entity(@backRightTire, array(
					transformation: array(
						translation: array(x: 0.62, y: if(@age % 4 <= 1, 0, -0.02), z: -0.6),
						scale: array(x: 0.25, y: 0.5, z: 0.5))));
			}
		} else {
			set_display_entity(@backLeftTire, array(
				transformation: array(
					translation: array(x: -0.87, y: if(@age % 4 <= 1, 0, -0.02), z: -0.6),
					scale: array(x: 0.25, y: 0.5, z: 0.5))));
			set_display_entity(@backRightTire, array(
				transformation: array(
					translation: array(x: 0.62, y: if(@age % 4 <= 1, 0, -0.02), z: -0.6),
					scale: array(x: 0.25, y: 0.5, z: 0.5))));
		}

		// Spawn rubber particles
		if(@grounded && @drift) {
			array @boostready = null;
			if(@kart['boost']['ticks'] > 40 && !@kart['boost']['strength']) {
				@boostready = array(
					particle: 'LAVA',
					count: 1,
					xoffset: 0.1,
					yoffset: 0.0,
					zoffset: 0.1);
				play_sound(@display, array(
					sound: 'BLOCK_FIRE_EXTINGUISH',
					pitch: 1 + rand(),
					volume: @kart['camdist'] / 6));
			}
			play_sound(@display, array(
				sound: 'BLOCK_COMPOSTER_READY',
				volume: @kart['camdist'] / 6,
				pitch: 1.5));
			@particle = array(
				particle: 'BLOCK_CRACK',
				block: 'GRAY_CONCRETE_POWDER',
				count: ceil(@kart['boost']['ticks'] / 10),
				xoffset: 0.25,
				yoffset: 0.0,
				zoffset: 0.25);
			@particle2 = array(particle: 'CAMPFIRE_SIGNAL_SMOKE');
			@particleLoc = @loc[];
			@right = get_vector(array(yaw: @loc['yaw'] + 90, pitch: 0));
			@particleLoc['x'] += @right['x'] * 0.77 - @forward['x'] * 0.5 - @velocity['x'] * 2;
			@particleLoc['z'] += @right['z'] * 0.77 - @forward['z'] * 0.5 - @velocity['z'] * 2;
			spawn_particle(@particleLoc, @particle);
			spawn_particle(@particleLoc, @particle2);
			if(@boostready) {
				spawn_particle(@particleLoc, @boostready);
			}
			@particleLoc['x'] -= @right['x'] * 1.54;
			@particleLoc['z'] -= @right['z'] * 1.54;
			spawn_particle(@particleLoc, @particle);
			spawn_particle(@particleLoc, @particle2);
			if(@boostready) {
				spawn_particle(@particleLoc, @boostready);
			}
		} else if(@grounded && (@acceleration < 0 || @acceleration > 0 && @currentVelocity['magnitude'] < 0.25)) {
			play_sound(@display, array(
				sound: 'BLOCK_COMPOSTER_READY',
				volume: @kart['camdist'] / 6));
			@particle1 = array(
				particle: 'BLOCK_CRACK',
				block: 'GRAY_CONCRETE_POWDER',
				count: 0,
				speed: 7,
				xoffset: -@forward['x'],
				yoffset: 1.0,
				zoffset: -@forward['z']);
			@particle2 = array(
				particle: 'FALLING_DUST',
				block: 'GRAY_CONCRETE_POWDER',
				count: 0);
			@particleLoc = @loc[];
			@right = get_vector(array(yaw: @loc['yaw'] + 90, pitch: 0));
			@r = rand() * 0.24 - 0.12;
			@particleLoc['x'] += @right['x'] * (0.77 + @r) - @forward['x'] * 0.5 - @velocity['x'] * 2;
			@particleLoc['z'] += @right['z'] * (0.77 + @r) - @forward['z'] * 0.5 - @velocity['z'] * 2;
			spawn_particle(@particleLoc, @particle1);
			spawn_particle(@particleLoc, @particle2);
			@particleLoc['x'] -= @right['x'] * (1.54 + @r * 2);
			@particleLoc['z'] -= @right['z'] * (1.54 + @r * 2);
			spawn_particle(@particleLoc, @particle1);
			spawn_particle(@particleLoc, @particle2);
		}

		// Spawn boost particles
		if(@kart['boost']['strength']) {
			@particle = array(
				particle: 'FLAME',
				speed: 0.03,
				xoffset: @kart['speed'] / 2,
				yoffset: 0.1,
				zoffset: @kart['speed'] / 2,
				count: 7 * @kart['boost']['strength']);
			@particleLoc = location_shift(@loc, 'up', 0.4);
			@particleLoc['x'] -= @velocity['x'] * 2 + @forward['x'] * 0.5;
			@particleLoc['z'] -= @velocity['z'] * 2 + @forward['z'] * 0.5;
			spawn_particle(@particleLoc, @particle);
			@particleLoc['x'] -= @velocity['x'] / 2;
			@particleLoc['z'] -= @velocity['z'] / 2;
			spawn_particle(@particleLoc, @particle);
			spawn_particle(@particleLoc, array(particle: 'CAMPFIRE_SIGNAL_SMOKE'));
		}

		// Update camera location
		@cameraLoc = location_shift(@loc, 'up');
		@cameraLoc['yaw'] = @pfacing[0] + 180;
		@cameraLoc['pitch'] = -35;
		@trace = ray_trace(@player, @cameraLoc, 2 + @kart['camdist'] + @kart['speed'] + if(@kart['boost'], 1, 0));
		set_entity_loc(@camera, location_shift(@trace['location'], @cameraLoc, 2, true));

		if(@race) {
			// Check movement on course
			_race_on_move(@player, @loc, @race);
		}
	});
}

proc _kart_show_item(@player, @kart) {
	@item = pinv(@player, 0);
	set_entity_spec(@kart['item'], array(item: @item));
	if(@item && @item['meta']) {
		action_msg(@player, color('bold').@item['meta']['display'].' [SPACE]');
	}
}