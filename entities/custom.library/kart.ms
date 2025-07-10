/**
 * Spawns a new kart.
 * Returns the array defining this kart object.
 */
array proc _kart_spawn(@loc, @player, @design, @camdist = 4.0) {
	string @engineBlock;
	string @color;
	string @wheels;
	if(@design) {
		@engineBlock = @design['engine'];
		@color = @design['color'];
		@wheels = @design['wheels'];
	} else {
		@engineBlock = array_get_rand(array('furnace', 'blast_furnace', 'smoker', 'copper_bulb', 'redstone_lamp'));
		@color = string(array_get_rand(reflect_pull('enum', 'DyeColor')));
		@wheels = array_get_rand(array('BLACK_CONCRETE', 'BLACK_CONCRETE_POWDER'));
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
		camera: null,
		leftTire: null,
		rightTire: null,
		head: null,
		// status
		loc: location_shift(@loc, 'up', 0),
		lastVelocity: array(x: 0, y: 0, z: 0, magnitude: 0.0),
		speed: 0.0,
		explode: false,
		camdist: @camdist,
		// previous inputs
		boost: false,
		driftTurn: 0,
	);
	@teleportduration = 2;
	@brightness = 15;
	@collider = spawn_entity('ARMOR_STAND', 1, @loc, closure(@collider) {
		set_entity_saves_on_unload(@collider, false);
		set_entity_attribute_base(@collider, 'GENERIC_STEP_HEIGHT', 0.5);
		set_entity_invulnerable(@collider, true);
		set_entity_spec(@collider, array(visible: false));
		set_entity_size(@collider, 1.2, 1.2);
	})[0];
	@kart['collider'] = @collider;
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
	set_entity_rider(@vehicle, spawn_entity('ITEM_DISPLAY', 1, @loc, closure(@engine) {
		set_entity_saves_on_unload(@engine, false);
		set_entity_spec(@engine, array(item: array(name: @color.'_SHULKER_BOX')));
		set_display_entity(@engine, array(
			brightness: @brightness,
			teleportduration: @teleportduration,
			transformation: array(
				translation: array(x: 0, y: 0.18, z: 0.275),
				scale: array(x: 0.9, y: 0.15, z: 1.85))));
	})[0]);
	@stand = spawn_entity('ARMOR_STAND', 1, @loc, closure(@stand) {
		set_entity_saves_on_unload(@stand, false);
		set_entity_spec(@stand, array(
			baseplate: false,
			smalL: true,
			arms: true,
			poses: array(
				poseLegLeft: array(-1.54, -0.32, -0.02),
				poseLegRight: array(-1.45, 0.39, 0.0),
				poseArmLeft: array(-1.55, 0.0, -0.01),
				poseArmRight: array(-1.58, -0.09, -0.01))));
		set_mob_equipment(@stand, array(
			CHESTPLATE: array(name: 'LEATHER_CHESTPLATE', meta: array(color: array(255,0,0))),
			LEGGINGS: array(name: 'LEATHER_LEGGINGS', meta: array(color: array(255,0,0))),
			BOOTS: array(name: 'LEATHER_BOOTS', meta: array(color: array(255,0,0))),
		));
	})[0];
	set_entity_rider(@vehicle, @stand);
	set_entity_invulnerable(@stand, true);
	@head = spawn_entity('ITEM_DISPLAY', 1, @loc, closure(@head) {
		set_entity_saves_on_unload(@head, false);
		set_entity_spec(@head, array(item: array(name: 'PLAYER_HEAD', meta: array(owner: @player))));
		set_display_entity(@head, array(
			brightness: @brightness,
			teleportduration: @teleportduration,
			transformation: array(
				translation: array(x: 0.0, y: 0.42, z: 0.0),
				scale: array(x: 1.2, y: 1.2, z: 1.2),
				leftRotation: array(x: 0.0, y: 1.0, z: 0.0, w: 0.0))));
	})[0];
	@kart['head'] = @head;
	set_entity_rider(@stand, @head);
	set_entity_rider(@vehicle, spawn_entity('ITEM_DISPLAY', 1, @loc, closure(@steeringwheel) {
		set_entity_saves_on_unload(@steeringwheel, false);
		set_entity_spec(@steeringwheel, array(item: array(name: 'MUSIC_DISC_STAL')));
		set_display_entity(@steeringwheel, array(
			brightness: @brightness,
			teleportduration: @teleportduration,
			transformation: array(
				translation: array(x: 0, y: 0.6, z: 0.5),
				scale: array(x: 0.6, y: 0.6, z: 0.6),
				leftRotation: array(x: 0.259, y: 0.0, z: 0.0, w: 0.966))));
	})[0]);
	set_entity_rider(@vehicle, spawn_entity('BLOCK_DISPLAY', 1, @loc, closure(@steeringcolumn) {
		set_entity_saves_on_unload(@steeringcolumn, false);
		set_entity_spec(@steeringcolumn, array(blockdata: 'gray_concrete_powder'));
		set_display_entity(@steeringcolumn, array(
			brightness: @brightness,
			teleportduration: @teleportduration,
			transformation: array(
				translation: array(x: -0.05, y: 0.5, z: 0.45),
				scale: array(x: 0.1, y: 0.1, z: 0.49),
				leftRotation: array(x: 0.281, y: 0.0, z: 0.0, w: 0.96))));
	})[0]);
	set_entity_rider(@vehicle, spawn_entity('ITEM_DISPLAY', 1, @loc, closure(@frontbumper) {
		set_entity_saves_on_unload(@frontbumper, false);
		set_entity_spec(@frontbumper, array(item: array(name: @color.'_SHULKER_BOX')));
		set_display_entity(@frontbumper, array(
			brightness: @brightness,
			teleportduration: @teleportduration,
			transformation: array(
				translation: array(x: 0, y: 0.2, z: 1.275),
				scale: array(x: 1.44, y: 0.2, z: 0.15))));
	})[0]);
	set_entity_rider(@vehicle, spawn_entity('ITEM_DISPLAY', 1, @loc, closure(@backbumper) {
		set_entity_saves_on_unload(@backbumper, false);
		set_entity_spec(@backbumper, array(item: array(name: @color.'_SHULKER_BOX')));
		set_display_entity(@backbumper, array(
			brightness: @brightness,
			teleportduration: @teleportduration,
			transformation: array(
				translation: array(x: 0, y: 0.2, z: -0.725),
				scale: array(x: 1.74, y: 0.2, z: 0.15))));
	})[0]);
	set_entity_rider(@vehicle, spawn_entity('BLOCK_DISPLAY', 1, @loc, closure(@frontaxle) {
		set_entity_saves_on_unload(@frontaxle, false);
		set_entity_spec(@frontaxle, array(blockdata: 'gray_concrete_powder'));
		set_display_entity(@frontaxle, array(
			brightness: @brightness,
			teleportduration: @teleportduration,
			transformation: array(
				translation: array(x: -0.88, y: 0.2, z: 0.8),
				scale: array(x: 1.74, y: 0.1, z: 0.1))));
	})[0]);
	@frontrighttire = spawn_entity('ITEM_DISPLAY', 1, @loc, closure(@frontrighttire) {
		set_entity_saves_on_unload(@frontrighttire, false);
		set_entity_spec(@frontrighttire, array(item: array(name: @wheels)));
		set_display_entity(@frontrighttire, array(
			brightness: @brightness,
			teleportduration: @teleportduration,
			transformation: array(
				translation: array(x: 0.72, y: 0.25, z: 0.85),
				scale: array(x: 0.2, y: 0.5, z: 0.5))));
	})[0];
	@kart['rightTire'] = @frontrighttire;
	set_entity_rider(@vehicle, @frontrighttire);
	@frontlefttire = spawn_entity('ITEM_DISPLAY', 1, @loc, closure(@frontlefttire) {
		set_entity_saves_on_unload(@frontlefttire, false);
		set_entity_spec(@frontlefttire, array(item: array(name: @wheels)));
		set_display_entity(@frontlefttire, array(
			brightness: @brightness,
			teleportduration: @teleportduration,
			transformation: array(
				translation: array(x: -0.72, y: 0.25, z: 0.85),
				scale: array(x: 0.2, y: 0.5, z: 0.5))));
	})[0];
	@kart['leftTire'] = @frontlefttire;
	set_entity_rider(@vehicle, @frontlefttire);
	set_entity_rider(@vehicle, spawn_entity('BLOCK_DISPLAY', 1, @loc, closure(@backaxle) {
		set_entity_saves_on_unload(@backaxle, false);
		set_entity_spec(@backaxle, array(blockdata: 'gray_concrete_powder'));
		set_display_entity(@backaxle, array(
			brightness: @brightness,
			teleportduration: @teleportduration,
			transformation: array(
				translation: array(x: -0.92, y: 0.2, z: -0.4),
				scale: array(x: 1.84, y: 0.1, z: 0.1))));
	})[0]);
	set_entity_rider(@vehicle, spawn_entity('BLOCK_DISPLAY', 1, @loc, closure(@backrighttire) {
		set_entity_saves_on_unload(@backrighttire, false);
		set_entity_spec(@backrighttire, array(blockdata: @wheels));
		set_display_entity(@backrighttire, array(
			brightness: @brightness,
			teleportduration: @teleportduration,
			transformation: array(
				translation: array(x: 0.62, y: 0.0, z: -0.6),
				scale: array(x: 0.25, y: 0.5, z: 0.5))));
	})[0]);
	set_entity_rider(@vehicle, spawn_entity('BLOCK_DISPLAY', 1, @loc, closure(@backlefttire) {
		set_entity_saves_on_unload(@backlefttire, false);
		set_entity_spec(@backlefttire, array(blockdata: @wheels));
		set_display_entity(@backlefttire, array(
			brightness: @brightness,
			teleportduration: @teleportduration,
			transformation: array(
				translation: array(x: -0.87, y: 0.0, z: -0.6),
				scale: array(x: 0.25, y: 0.5, z: 0.5))));
	})[0]);
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
	set_pexp(@player, 0);
	try(create_bar(@player.'kart', array(style: 'SEGMENTED_20', percent: 0.0)))
	bar_add_player(@player.'kart', @player);
	set_pheld_slot(@player, 8);
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
	if(ponline(@player)) {
		// double check if they have not switched to new kart
		@vehicle = pvehicle(@player);
		if(!@vehicle || @vehicle === @kart['camera'] || entity_type(@vehicle) !== 'BLOCK_DISPLAY') {
			remove_bar(@player.'kart');
		}
	} else {
		remove_bar(@player.'kart');
	}
	foreach(@rider in get_entity_riders(@kart['engine'])) {
		entity_remove(@rider);
	}
	entity_remove(@kart['engine']);
	entity_remove(@kart['camera']);
	entity_remove(@kart['head']);
	entity_remove(@kart['collider']);
}

/**
 * Starts the kart interval tick.
 */
proc _kart_tick(@player, @kart, @race) {
	@driftAngle = 32.0;
	@maxSpeed = 1.5;

	@display = @kart['engine'];
	@collider = @kart['collider'];
	@leftTire = @kart['leftTire'];
	@rightTire = @kart['rightTire'];
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

		@pfacing = pfacing(@player);
		set_peffect(@player, 'invisibility', 0, 1, true, false, false);

		// Get location
		@loc = entity_loc(@collider);
		@currentVelocity = entity_velocity(@collider);

		// Interpolate pitch back to zero
		if(!equals_epsilon(@loc['pitch'], 0.0, 0.01)) {
			if(@loc['pitch'] > 0) {
				@loc['pitch'] *= 0.5;
			} else {
				@loc['pitch'] *= 0.9;
			}
			if(equals_epsilon(@loc['pitch'], 0.0, 1.0)) {
				@loc['pitch'] = 0.0;
			}
		}

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

		// Boost / reset yaw from drift turn
		if(!@drift && pexp(@player) >= 99 && @acceleration > 0) {
			play_sound(@display, array(sound: 'BLOCK_RESPAWN_ANCHOR_DEPLETE', volume: @kart['camdist']));
			play_sound(@display, array(sound: 'ENTITY_GHAST_SHOOT', pitch: 0.5, volume: @kart['camdist']));
			@kart['boost'] = true;
			set_entity_spec(@display, array(blockdata: @kart['engineBlock'].'[lit=true]'));
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
		@xp = pexp(@player);
		if(@kart['boost']) {
			set_pexp(@player, max(0, @xp - 4));
			if(@xp <= 0) {
				@kart['boost'] = false;
				set_entity_spec(@display, array(blockdata: @kart['engineBlock'].'[lit=false]'));
			}
		} else if(@kart['driftTurn'] && @acceleration >= 1) {
			set_pexp(@player, min(99, @xp + 3));
		} else if(@xp > 3) {
			set_pexp(@player, @xp - 4);
		}
		if(@kart['boost']) {
			if(@kart['speed'] < @maxSpeed) {
				@kart['speed'] += 0.02 * (@maxSpeed - @kart['speed']);
			}
		} else if(@acceleration > 0) {
			if(@kart['speed'] < 0.75 * @maxSpeed) {
				if(@drift) {
					@kart['speed'] += 0.01 * (0.75 * @maxSpeed - @kart['speed']);
				} else {
					@kart['speed'] += 0.02 * (0.75 * @maxSpeed - @kart['speed']);
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
			if(abs(@kart['speed']) < 0.01) {
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
		if(@acceleration > 0 || !rand(20)) {
			play_sound(@display, array(
				sound: 'ENTITY_BEE_LOOP',
				pitch: 0.5 + @kart['speed'] * 1.5,
				volume: @kart['camdist'] / 1.8));
		}

		// Check collision
		if(entity_grounded(@collider)) {
			@lastVelocity = @kart['lastVelocity'];
			if(@currentVelocity['x'] == 0 && abs(@lastVelocity['x']) > 0.04) { // if velocity stopped on this axis
				if(abs(@kart['loc']['x'] - @loc['x']) < 0.01) { // if movement stopped on this axis
					if(abs(@lastVelocity['x']) > 0.3 // speed of collision
					&& abs(@lastVelocity['x']) > abs(@lastVelocity['z'])) { // angle of collision
						@kart['explode'] = true;
					} else if(@lastVelocity['x'] > 0.1) { // still fast enough to deflect
						if(@lastVelocity['z'] > 0) {
							@loc['yaw'] = 0;
						} else if(@lastVelocity['z'] < 0) {
							@loc['yaw'] = 180;
						}
						@kart['speed'] *= 0.7;
					} else { // going too slow, so just stop
						@kart['speed'] = 0.0;
					}
					@kart['lastVelocity'] = @currentVelocity;
					play_named_sound(@display, array(
						sound: 'block.vault.break',
						pitch: 1.3 - @kart['speed'],
						volume: @kart['camdist'] / 3));
				}
			} else if(@currentVelocity['z'] == 0 && abs(@lastVelocity['z']) > 0.04) {
				if(abs(@kart['loc']['z'] - @loc['z']) < 0.01) {
					if(abs(@lastVelocity['z']) > 0.3
					&& abs(@lastVelocity['z']) > abs(@lastVelocity['x'])) {
						@kart['explode'] = true;
					} else if(@lastVelocity['z'] > 0.1) {
						if(@lastVelocity['x'] > 0) {
							@loc['yaw'] = 270;
						} else if(@lastVelocity['x'] < 0) {
							@loc['yaw'] = 90;
						}
						@kart['speed'] *= 0.7;
					} else {
						@kart['speed'] = 0.0;
					}
					@kart['lastVelocity'] = @currentVelocity;
					play_named_sound(@display, array(
						sound: 'block.vault.break',
						pitch: 1.3 - @kart['speed'],
						volume: @kart['camdist'] / 3));
				}
			} else {
				@kart['lastVelocity'] = @currentVelocity;
				if(@loc['y'] > @kart['loc']['y']) {
					@loc['pitch'] = -(@loc['y'] - @kart['loc']['y']) * 35;
				}
			}
		} else {
			@loc['pitch'] = @currentVelocity['y'] * 25 * if(@kart['speed'] > 0, -1, 1);
		}
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
		set_display_entity(@leftTire, array(transformation: array(
			leftRotation: array(x: 0.0, y: -@turn * 0.1, z: 0.0, w: 1.0))));
		set_display_entity(@rightTire, array(transformation: array(
			leftRotation: array(x: 0.0, y: -@turn * 0.1, z: 0.0, w: 1.0))));
		set_entity_loc(@display, @loc);
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

		// Spawn rubber particles
		if(@drift) {
			array @boostready = null;
			if(pexp(@player) >= 99) {
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
				count: ceil(@xp / 10),
				xoffset: 0.25,
				yoffset: 0.0,
				zoffset: 0.25);
			@particle2 = array(particle: 'CAMPFIRE_SIGNAL_SMOKE');
			@particleLoc = @loc[];
			@right = get_vector(array(yaw: @loc['yaw'] + 90, pitch: 0));
			@particleLoc['x'] += @right['x'] * 0.77 - @forward['x'] * 0.5 - @velocity['x'];
			@particleLoc['z'] += @right['z'] * 0.77 - @forward['z'] * 0.5 - @velocity['z'];
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
		} else if(@acceleration >= 1 && @kart['speed'] < 0.3) {
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
			@particleLoc['x'] += @right['x'] * (0.77 + @r) - @forward['x'] * 0.5 - @velocity['x'];
			@particleLoc['z'] += @right['z'] * (0.77 + @r) - @forward['z'] * 0.5 - @velocity['z'];
			spawn_particle(@particleLoc, @particle1);
			spawn_particle(@particleLoc, @particle2);
			@particleLoc['x'] -= @right['x'] * (1.54 + @r * 2);
			@particleLoc['z'] -= @right['z'] * (1.54 + @r * 2);
			spawn_particle(@particleLoc, @particle1);
			spawn_particle(@particleLoc, @particle2);
		}

		// Spawn boost particles
		if(@kart['boost']) {
			@particle = array(
				particle: 'FLAME',
				speed: 0.03,
				xoffset: @kart['speed'] / 2,
				yoffset: 0.1,
				zoffset: @kart['speed'] / 2,
				count: 7);
			@particleLoc = location_shift(@loc, 'up', 0.4);
			@particleLoc['x'] -= @velocity['x'] + @forward['x'] * 0.5;
			@particleLoc['z'] -= @velocity['z'] + @forward['z'] * 0.5;
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

		try {
			update_bar(@player.'kart', array(
				percent: clamp(abs(@kart['speed']) / @maxSpeed, 0.0, 1.0),
				color: if(@kart['speed'] > 1.0, 'RED', if(@kart['speed'] > 0.7975 * @maxSpeed, 'YELLOW', 'WHITE'))));
		} catch(NotFoundException @ex) {
			create_bar(@player.'kart', array(style: 'SEGMENTED_20', percent: 0.0));
			bar_add_player(@player.'kart', @player);
		}

		if(@kart['explode']) {
			clear_task();
			@components = get_entity_riders(@display);
			@components[] = @display;
			set_display_entity(@display, array(teleportduration: 12));
			set_entity_loc(@display, location_shift(@loc, 'up', 2));
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
					set_entity_spec(@entity, array(
						poses: array(
							poseLegLeft: array(-0.03, 0.0, -0.57),
							poseLegRight: array(0.0, 0.0, 0.5),
							poseArmLeft: array(-0.27, 0.0, -1.57),
							poseArmRight: array(-0.12, 0.0, 1.57))));
				}
			}
			spawn_particle(@loc, array(particle: 'EXPLOSION_HUGE'));
			play_sound(@loc, array(sound: 'ENTITY_GENERIC_EXPLODE', volume: @kart['camdist']));
			if(@race) {
				foreach(@otherplayer in array_keys(@race['players'])) {
					psend_block_change(@otherplayer, @loc, 'fire');
				}
			}
			set_timeout(@animationDurationTicks * 50, closure(){
				_kart_remove(@player, @kart);
				if(@race) {
					call_proc(@race['onMove'], @player, @loc, @race);
				}
			});
		} else if(@race) {
			// Check movement on course
			call_proc(@race['onMove'], @player, @loc, @race);
		}
	});
}