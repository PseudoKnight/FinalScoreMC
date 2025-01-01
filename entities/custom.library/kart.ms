/**
 * Spawns a new kart.
 * Returns the array defining this kart object.
 */
array proc _kart_spawn(@loc, @player, @design, @camdist = 4.0) {
	string @engine;
	string @color;
	if(@design) {
		@engine = @design['engine'];
		@color = @design['color'];
	} else {
		@color = to_lower(string(array_get_rand(reflect_pull('enum', 'DyeColor'))));
		@engine = array_get_rand(array('furnace', 'blast_furnace', 'smoker'));
	}
	@kart = array(
		// kart design
		color: @color,
		engine: @engine,
		// entity UUIDs
		base: null,
		camera: null,
		leftTire: null,
		rightTire: null,
		head: null,
		// status
		loc: null,
		velocity: 0.0,
		vertical: -0.1,
		explode: false,
		camdist: @camdist,
		// previous inputs
		boost: false,
		driftTurn: 0,
	);
	@teleportduration = 2;
	@brightness = 15;
	@vehicle = spawn_entity('BLOCK_DISPLAY', 1, @loc, closure(@engineDisplay) {
		set_entity_spec(@engineDisplay, array(blockdata: @engine));
		set_display_entity(@engineDisplay, array(
			brightness: @brightness,
			teleportduration: @teleportduration,
			shadowradius: 0.6,
			transformation: array(
				translation: array(x: -0.39, y: 0.25, z: -0.56),
				scale: array(x: 0.78, y: 0.48, z: 0.34))));
	})[0];
	@kart['base'] = @vehicle;
	set_entity_rider(@vehicle, spawn_entity('BLOCK_DISPLAY', 1, @loc, closure(@base) {
		set_entity_spec(@base, array(blockdata: @color.'_shulker_box'));
		set_display_entity(@base, array(
			brightness: @brightness,
			teleportduration: @teleportduration,
			transformation: array(
				translation: array(x: -0.45, y: 0.1, z: -0.65),
				scale: array(x: 0.9, y: 0.15, z: 1.85))));
	})[0]);
	@stand = spawn_entity('ARMOR_STAND', 1, @loc, closure(@stand) {
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
		set_entity_spec(@steeringcolumn, array(blockdata: 'gray_concrete_powder'));
		set_display_entity(@steeringcolumn, array(
			brightness: @brightness,
			teleportduration: @teleportduration,
			transformation: array(
				translation: array(x: -0.05, y: 0.5, z: 0.45),
				scale: array(x: 0.1, y: 0.1, z: 0.49),
				leftRotation: array(x: 0.281, y: 0.0, z: 0.0, w: 0.96))));
	})[0]);
	set_entity_rider(@vehicle, spawn_entity('BLOCK_DISPLAY', 1, @loc, closure(@frontbumper) {
		set_entity_spec(@frontbumper, array(blockdata: @color.'_shulker_box'));
		set_display_entity(@frontbumper, array(
			brightness: @brightness,
			teleportduration: @teleportduration,
			transformation: array(
				translation: array(x: -0.72, y: 0.1, z: 1.2),
				scale: array(x: 1.44, y: 0.2, z: 0.15))));
	})[0]);
	set_entity_rider(@vehicle, spawn_entity('BLOCK_DISPLAY', 1, @loc, closure(@backbumper) {
		set_entity_spec(@backbumper, array(blockdata: @color.'_shulker_box'));
		set_display_entity(@backbumper, array(
			brightness: @brightness,
			teleportduration: @teleportduration,
			transformation: array(
				translation: array(x: -0.87, y: 0.1, z: -0.80),
				scale: array(x: 1.74, y: 0.2, z: 0.15))));
	})[0]);
	set_entity_rider(@vehicle, spawn_entity('BLOCK_DISPLAY', 1, @loc, closure(@frontaxle) {
		set_entity_spec(@frontaxle, array(blockdata: 'gray_concrete_powder'));
		set_display_entity(@frontaxle, array(
			brightness: @brightness,
			teleportduration: @teleportduration,
			transformation: array(
				translation: array(x: -0.88, y: 0.2, z: 0.8),
				scale: array(x: 1.74, y: 0.1, z: 0.1))));
	})[0]);
	@frontrighttire = spawn_entity('ITEM_DISPLAY', 1, @loc, closure(@frontrighttire) {
		set_entity_spec(@frontrighttire, array(item: array(name: 'BLACK_CONCRETE_POWDER')));
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
		set_entity_spec(@frontlefttire, array(item: array(name: 'BLACK_CONCRETE_POWDER')));
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
		set_entity_spec(@backaxle, array(blockdata: 'gray_concrete_powder'));
		set_display_entity(@backaxle, array(
			brightness: @brightness,
			teleportduration: @teleportduration,
			transformation: array(
				translation: array(x: -0.92, y: 0.2, z: -0.4),
				scale: array(x: 1.84, y: 0.1, z: 0.1))));
	})[0]);
	set_entity_rider(@vehicle, spawn_entity('BLOCK_DISPLAY', 1, @loc, closure(@backrighttire) {
		set_entity_spec(@backrighttire, array(blockdata: 'black_concrete_powder'));
		set_display_entity(@backrighttire, array(
			brightness: @brightness,
			teleportduration: @teleportduration,
			transformation: array(
				translation: array(x: 0.62, y: 0.0, z: -0.6),
				scale: array(x: 0.25, y: 0.5, z: 0.5))));
	})[0]);
	set_entity_rider(@vehicle, spawn_entity('BLOCK_DISPLAY', 1, @loc, closure(@backlefttire) {
		set_entity_spec(@backlefttire, array(blockdata: 'black_concrete_powder'));
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
		set_display_entity(@camera, array(teleportduration: 2));
	})[0];
	@cameraLoc['pitch'] = get_pitch(@cameraLoc, @loc);
	set_entity_loc(puuid(@player), @cameraLoc);
	set_entity_rider(@kart['camera'], puuid(@player));
	set_peffect(@player, 'invisibility', 1, -1, true, false, false);
	set_entity_invulnerable(puuid(@player), true);
	set_pexp(@player, 0);
	try(create_bar(@player.'kart', array(style: 'SEGMENTED_10', percent: 0.0)))
	bar_add_player(@player.'kart', @player);
	return(@kart);
}

proc _kart_remove(@player, @kart) {
	if(ponline(@player)) {
		// double check if they have not switched to new kart
		@vehicle = pvehicle(@player);
		if(!@vehicle || @vehicle === @kart['camera'] || entity_type(@vehicle) !== 'BLOCK_DISPLAY') {
			clear_peffects(@player);
			set_entity_invulnerable(puuid(@player), false);
			remove_bar(@player.'kart');
		}
	} else {
		remove_bar(@player.'kart');
	}
	foreach(@rider in get_entity_riders(@kart['base'])) {
		entity_remove(@rider);
	}
	entity_remove(@kart['base']);
	entity_remove(@kart['camera']);
	entity_remove(@kart['head']);
}

/**
 * Starts the kart interval tick.
 */
proc _kart_tick(@player, @kart, @race) {
	@driftAngle = 32.0;
	set_interval(50, 0, closure(){
		if(!ponline(@player)) {
			clear_task();
			die();
		}
		if(pvehicle(@player) !== @kart['camera']) {
			try(_kart_remove(@player, @kart))
			clear_task();
			die();
		}
		@vehicle = @kart['base'];
		@pfacing = pfacing(@player);

		if(!entity_exists(@vehicle)) {
			clear_task();
			die();
		}

		// Get location
		@loc = @kart['loc'];
		if(!@loc) {
			@loc = entity_loc(@vehicle);
			foreach(@i in range(6)) {
				array_remove(@loc, @i);
			}
			@kart['loc'] = @loc;
		}
		@from = @loc[];

		// Interpolate pitch back to zero
		if(!equals_epsilon(@loc['pitch'], 0.0, 0.01)) {
			@loc['pitch'] = @loc['pitch'] * 0.7;
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
		if(!@drift && pexp(@player) == 99 && @acceleration > 0) {
			play_sound(@vehicle, array(sound: 'BLOCK_RESPAWN_ANCHOR_DEPLETE', volume: @kart['camdist']));
			play_sound(@vehicle, array(sound: 'ENTITY_GHAST_SHOOT', pitch: 0.5, volume: @kart['camdist']));
			@kart['boost'] = true;
			set_entity_spec(@vehicle, array(blockdata: @kart['engine'].'[lit=true]'));
			@loc['yaw'] -= @kart['driftTurn'] * (@driftAngle / 2);
		} else if(@kart['driftTurn']) {
			@loc['yaw'] -= @kart['driftTurn'] * @driftAngle;
		}
		if(!@drift) {
			@kart['driftTurn'] = 0;
		}

		// Handle velocity and yaw
		@xp = pexp(@player);
		if(@kart['boost']) {
			set_pexp(@player, max(0, @xp - 4));
			if(@xp == 0) {
				@kart['boost'] = false;
				set_entity_spec(@vehicle, array(blockdata: @kart['engine'].'[lit=false]'));
			}
		} else if(@drift && @acceleration == 1) {
			set_pexp(@player, min(99, @xp + 3));
		} else if(@xp > 3) {
			set_pexp(@player, @xp - 4);
		}
		if(@kart['boost']) {
			if(@kart['velocity'] < 1.0) {
				@kart['velocity'] += 0.02 * (1.0 - @kart['velocity']);
			}
		} else if(@acceleration > 0) {
			if(@kart['velocity'] < 0.8) {
				if(@drift) {
					@kart['velocity'] += 0.01 * (0.8 - @kart['velocity']);
				} else {
					@kart['velocity'] += 0.02 * (0.8 - @kart['velocity']);
				}
			}
		} else if(@acceleration < 0) {
			if(@kart['velocity'] > -0.3) {
				if(@drift && @kart['velocity'] > 0) {
					@kart['velocity'] -= 0.04;
				} else {
					@kart['velocity'] -= 0.02;
				}
			}
		} else {
			@kart['velocity'] *= 0.97;
			if(abs(@kart['velocity']) < 0.01) {
				@kart['velocity'] = 0.0;
			}
		}
		if(@drift) {
			@loc['yaw'] += @turn + @kart['driftTurn'] * 2;
		} else if(@turn) {
			if(@kart['velocity'] < 0) {
				@loc['yaw'] -= @turn * 2;
			} else {
				@loc['yaw'] += @turn * 2;
			}
		}
		if(@loc['yaw'] > 360) {
			@loc['yaw'] -= 360;
		} else if(@loc['yaw'] < 0) {
			@loc['yaw'] += 360;
		}
		if(@acceleration > 0 || !rand(20)) {
			play_sound(@vehicle, array(
				sound: 'ENTITY_BEE_LOOP',
				pitch: 0.5 + @kart['velocity'] * 1.5,
				volume: @kart['camdist'] / 1.8));
		}

		// Get vector directions
		@forward = get_vector(array(yaw: @loc['yaw'], pitch: 0));
		@velocity = get_vector(array(yaw: @loc['yaw'], pitch: 0), @kart['velocity']);
		@right = get_vector(array(yaw: @loc['yaw'] + 90, pitch: 0));

		// Check collision
		if(@kart['velocity']) {
			@vertical = @kart['vertical'];
			@normalizedVelocity = get_vector(array(yaw: @loc['yaw'] + if(@kart['velocity'] < 0, 180, 0), pitch: 0));
			@dist2bumper = if(@kart['velocity'] > 0, 1.35, 0.8);
			@origin = @loc[];
			@origin['y'] += 0.6; // step height is 0.5
			@origin['pitch'] = 90;
			@origin['x'] += @normalizedVelocity['x'] * @dist2bumper;
			@origin['z'] += @normalizedVelocity['z'] * @dist2bumper;
			@origin['x'] -= @right['x'] * 0.5;
			@origin['z'] -= @right['z'] * 0.5;
			@trace = ray_trace(@player, @origin, 0.6 - @vertical, 0.225);
			@hit = @trace['location'];
			if(@trace['entities']) {
				@entity = @trace['entities'][0]['uuid'];
				@entityYaw = get_yaw(@loc, entity_loc(@entity));
				set_entity_velocity(@trace['entities'][0]['uuid'], get_vector(array(yaw: @entityYaw, pitch: -10), @kart['velocity']));
				@kart['velocity'] *= 0.9;
			}
			@isLeft = true;
			if(@hit['y'] + 0.001 <= @loc['y']) {
				@isLeft = false;
				@origin['x'] += @right['x'];
				@origin['z'] += @right['z'];
				@trace = ray_trace(@player, @origin, 0.6 - @vertical, 0.225);
				@hit = @trace['location'];
				if(@trace['entities']) {
					@entity = @trace['entities'][0]['uuid'];
					@entityYaw = get_yaw(@loc, entity_loc(@entity));
					set_entity_velocity(@trace['entities'][0]['uuid'], get_vector(array(yaw: @entityYaw, pitch: -10), @kart['velocity']));
					@kart['velocity'] *= 0.9;
				}
			}
			if(@hit['y'] > @loc['y']) {
				@magnitude = abs(@kart['velocity']);
				@loc['pitch'] = if(@magnitude < 0.03, 0, get_pitch(@loc, @hit) * if(@kart['velocity'] > 0, 1, -0.3));
				if(@hit['y'] > @loc['y'] + 0.501) {
					@origin['x'] -= @normalizedVelocity['x'] * @dist2bumper;
					@origin['y'] -= 0.6;
					@origin['z'] -= @normalizedVelocity['z'] * @dist2bumper;
					@origin['pitch'] = 0;
					@collision = ray_trace(@origin, @dist2bumper);
					@collisionLoc = @collision['location'];
					@dist2collision = min(@magnitude, @dist2bumper - distance(@origin, @collisionLoc));
					if(@magnitude > 0.2) {
						@blockType = get_block(@hit);
						if(@blockType !== 'AIR') {
							spawn_particle(@collisionLoc, array(
								particle: 'BLOCK_CRACK',
								block: @blockType,
								speed: @kart['velocity'] * 2,
								count: 15,
								xoffset: 0.3,
								yoffset: 0.15,
								zoffset: 0.3));
						}
						play_named_sound(@vehicle, array(
							sound: 'block.vault.break',
							pitch: 1.3 - @kart['velocity'],
							volume: @kart['camdist'] / 3));
					}
					if(@dist2collision < 0.0625 && @magnitude < 0.03) {
						@velocity = array(x: 0, y: 0, z: 0);
						@kart['velocity'] = 0.0;
					} else {
						@face = @collision['hitface'];
						@yaw = @loc['yaw'];
						// Handles all acute angle wall collisions
						if(@isLeft && @face === 'WEST' && @loc['yaw'] > 325.0
						|| !@isLeft && @face === 'EAST' && @loc['yaw'] < 35.0) {
							@loc['yaw'] = 0.0;
						} else if(@isLeft && @face === 'EAST' && @loc['yaw'] > 145.0 && @loc['yaw'] < 180.0
						|| !@isLeft && @face === 'WEST' && @loc['yaw'] < 215.0 && @loc['yaw'] > 180.0) {
							@loc['yaw'] = 180.0;
						} else if(@isLeft && @face === 'SOUTH' && @loc['yaw'] > 235.0 && @loc['yaw'] < 270.0
						|| !@isLeft && @face === 'NORTH' && @loc['yaw'] < 305.0 && @loc['yaw'] > 270.0) {
							@loc['yaw'] = 270.0;
						} else if(@isLeft && @face === 'NORTH' && @loc['yaw'] > 55.0 && @loc['yaw'] < 90.0
						|| !@isLeft && @face === 'SOUTH' && @loc['yaw'] < 125.0 && @loc['yaw'] > 90.0) {
							@loc['yaw'] = 90.0;
						}
						if(@yaw == @loc['yaw']) {
							if(@magnitude > 0.6) {
								@kart['explode'] = true;
							}
							@velocity = get_vector(array(yaw: @loc['yaw'], pitch: 0), if(@kart['velocity'] > 0, @dist2collision, -@dist2collision));
							@kart['velocity'] = -(@kart['velocity'] * 0.25);
						} else {
							@velocity = get_vector(array(yaw: @loc['yaw'], pitch: 0), if(@kart['velocity'] > 0, @dist2collision, -@dist2collision));
							@kart['velocity'] *= 0.67;
						}
					}
				} else {
					@loc['y'] = @hit['y'] + 0.001;
				}
			} else if(@hit['y'] < @loc['y'] - 0.001) {
				@origin['x'] -= @normalizedVelocity['x'];
				@origin['z'] -= @normalizedVelocity['z'];
				@origin['x'] -= @right['x'];
				@origin['z'] -= @right['z'];
				@hitLeft = ray_trace(@origin, 0.6 - @vertical)['location'];
				if(@hitLeft['y'] < @loc['y'] - 0.001) {
					@origin['x'] += @right['x'];
					@origin['z'] += @right['z'];
					@hitRight = ray_trace(@origin, 0.6 - @vertical)['location'];
					if(@hitLeft['y'] > @hitRight['y']) {
						@loc['y'] = @hitLeft['y'] + 0.001;
					} else if(@hitRight['y'] < @loc['y'] - 0.001) {
						@loc['pitch'] = min(15, get_pitch(@loc, @hitRight));
						@loc['y'] = @hitRight['y'] + 0.001;
						@vertical = @vertical * 0.95 - 0.038; // minecart gravity
					} else {
						@loc['y'] = @hitRight['y'] + 0.001;
					}
				}
			} else {
				@loc['y'] = @hit['y'] + 0.001;
			}
			if(!equals_epsilon(@vertical, @kart['vertical'], 0.001)) {
				@kart['vertical'] = @vertical;
			} else if(@vertical < -0.038) {
				if(@vertical < -0.25) { // fell more than half a block
					play_named_sound(@vehicle, array(
							sound: 'block.vault.break',
							pitch: 1.2 + @vertical,
							volume: @kart['camdist']));
				}
				@kart['vertical'] = -0.038;
			}
		}

		// Move vehicle
		@loc['x'] += @velocity['x'];
		@loc['z'] += @velocity['z'];
		if(@drift) {
			if(!@kart['driftTurn']) {
				@kart['driftTurn'] = @turn;
			}
			@loc['yaw'] += @kart['driftTurn'] * @driftAngle;
		}
		set_display_entity(@kart['leftTire'], array(transformation: array(
			leftRotation: array(x: 0.0, y: -@turn * 0.1, z: 0.0, w: 1.0))));
		set_display_entity(@kart['rightTire'], array(transformation: array(
			leftRotation: array(x: 0.0, y: -@turn * 0.1, z: 0.0, w: 1.0))));
		set_entity_loc(@vehicle, @loc);

		// Rotate vehicle components
		@deltaYaw = @loc['yaw'] - @pfacing[0];
		if(@deltaYaw < -180) {
			@deltaYaw += 360;
		} else if(@deltaYaw > 180) {
			@deltaYaw -= 360;
		}
		set_entity_rotation(@kart['head'], @pfacing[0] + @deltaYaw / 1.8, 0);
		foreach(@rider in get_entity_riders(@vehicle)) {
			set_entity_rotation(@rider, @loc['yaw'], @loc['pitch']);
		}

		// Spawn rubber particles
		if(@drift) {
			array @boostready = null;
			if(pexp(@player) == 99) {
				@boostready = array(
					particle: 'LAVA',
					count: 1,
					xoffset: 0.1,
					yoffset: 0.0,
					zoffset: 0.1);
				play_sound(@vehicle, array(
					sound: 'BLOCK_FIRE_EXTINGUISH',
					pitch: 1 + rand(),
					volume: @kart['camdist'] / 6));
			}
			play_sound(@vehicle, array(
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
			@particleLoc = @from[];
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
		} else if(@acceleration == 1 && @kart['velocity'] < 0.35) {
			play_sound(@vehicle, array(
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
			@particleLoc = @from[];
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
				xoffset: @kart['velocity'] / 2,
				yoffset: 0.1,
				zoffset: @kart['velocity'] / 2,
				count: 7);
			@particleLoc = @from[];
			@particleLoc['x'] -= @velocity['x'] + @forward['x'] * 0.5;
			@particleLoc['y'] += 0.4;
			@particleLoc['z'] -= @velocity['z'] + @forward['z'] * 0.5;
			spawn_particle(@particleLoc, @particle);
			@particleLoc['x'] -= @velocity['x'] / 2;
			@particleLoc['z'] -= @velocity['z'] / 2;
			spawn_particle(@particleLoc, @particle);
			spawn_particle(@particleLoc, array(particle: 'CAMPFIRE_SIGNAL_SMOKE'));
		}

		// Update camera location
		@camera = pvehicle(@player);
		@cameraOffset = get_vector(array(yaw: @pfacing[0], pitch: 0), @kart['camdist'] + @kart['velocity'] + if(@kart['boost'], 1, 0));
		@cameraLoc = @loc[];
		@cameraLoc['x'] -= @cameraOffset['x'];
		@cameraLoc['y'] += @kart['camdist'];
		@cameraLoc['z'] -= @cameraOffset['z'];
		set_entity_loc(@camera, @cameraLoc);

		try {
			update_bar(@player.'kart', array(
				percent: abs(@kart['velocity']),
				color: if(@kart['velocity'] < 0.0, 'RED', if(@kart['velocity'] > 0.7975, 'YELLOW', 'WHITE')),
				title: 'Speed: '.round(@kart['velocity'] * 20, 1).' m/s'));
		} catch(NotFoundException @ex) {
			create_bar(@player.'kart', array(style: 'SEGMENTED_10', percent: 0.0));
			bar_add_player(@player.'kart', @player);
		}

		if(@kart['explode']) {
			clear_task();
			@components = get_entity_riders(@vehicle);
			@components[] = @vehicle;
			set_display_entity(@vehicle, array(teleportduration: 12));
			set_entity_loc(@vehicle, location_shift(@loc, 'up', 2));
			foreach(@entity in @components) {
				if(entity_type(@entity) !== 'ARMOR_STAND') {
					@display = get_display_entity(@entity);
					@translation = @display['transformation']['translation'];
					set_display_entity(@entity, array(
						interpolationduration: 12,
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
			set_timeout(600, closure(){
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