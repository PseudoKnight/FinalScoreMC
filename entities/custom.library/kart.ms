/**
 * Spawns a new kart.
 * Returns the array defining this kart object.
 */
array proc _kart_spawn(@loc, @player, @design) {
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
		// previous inputs
		boost: false,
		drift: 0,
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
				translation: array(x: 0.0, y: 0.45, z: 0.0),
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
	@v = get_vector(@loc, 10.0);
	@cameraLoc = @loc[];
	@cameraLoc['x'] = @cameraLoc[0] - @v['x'];
	@cameraLoc['z'] = @cameraLoc[2] - @v['z'];
	@cameraLoc['y'] = @cameraLoc[1] + 10;
	@cameraLoc['world'] = @cameraLoc[3];
	@cameraLoc['yaw'] = @cameraLoc[4];
	@kart['camera'] = spawn_entity('BLOCK_DISPLAY', 1, @cameraLoc, closure(@camera){
		set_display_entity(@camera, array(teleportduration: 2));
	})[0];
	set_entity_rider(@kart['camera'], puuid(@player));
	set_peffect(@player, 'invisibility', 1, -1, true, false, false);
	set_entity_invulnerable(puuid(@player), true);
	set_pexp(@player, 0);
	return(@kart);
}

proc _kart_remove(@player, @kart) {
	if(ponline(@player)) {
		clear_peffects(@player);
		set_entity_invulnerable(puuid(@player), false);
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
		if(!ponline(@player) || pvehicle(@player) !== @kart['camera']) {
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

		// Consume inputs
		@drift = @kart['drift'] && !@kart['boost'] && @kart['velocity'] > 0.4;
		@kart['drift'] = max(0, @kart['drift'] - 1); // drift key actuates for 2 ticks to smooth input gaps

		// Interpolate pitch back to zero
		if(!equals_epsilon(@loc['pitch'], 0.0, 0.01)) {
			@loc['pitch'] = @loc['pitch'] * 0.7;
			if(equals_epsilon(@loc['pitch'], 0.0, 1.0)) {
				@loc['pitch'] = 0.0;
			}
		}

		// Initialize new input
		@acceleration = 0;
		@turn = 0;

		// Get input
		// The player velocity vector while riding a vehicle can be interpreted as directional
		// movement (e.g. WASD) by translating it relative to the player's yaw
		@input = pvelocity(@player);
		if(@input['x'] || @input['z']) {
			@inputYaw = get_yaw(array(0, 0, 0), @input);
			@deltaYaw = @inputYaw - @pfacing[0];
			if(@deltaYaw < -180) {
				@deltaYaw += 360;
			} else if(@deltaYaw > 180) {
				@deltaYaw -= 360;
			}
			if(abs(@deltaYaw) < 60) {
				@acceleration = 1;
			} else if(abs(@deltaYaw) > 120) {
				@acceleration = -1;
			}
			if(@deltaYaw > 30 && @deltaYaw < 150) {
				@turn = 1;
			} else if(@deltaYaw < -30 && @deltaYaw > -150) {
				@turn = -1;
			}
		}

		// Boost / reset yaw
		if(!@drift && pexp(@player) == 99 && @acceleration > 0) {
			play_sound(@vehicle, array(sound: 'ENTITY_GHAST_SHOOT', pitch: 0.5, volume: 2));
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
		if(!@drift) {
			@xp = max(0, pexp(@player) - 4);
			set_pexp(@player, @xp);
			if(@xp == 0) {
				@kart['boost'] = false;
				set_entity_spec(@vehicle, array(blockdata: @kart['engine'].'[lit=false]'));
			}
		} else if(!@kart['boost']) {
			if(@acceleration < 1) {
				set_pexp(@player, max(0, pexp(@player) - 4));
			} else {
				set_pexp(@player, min(99, pexp(@player) + 3));
			}
		}
		if(@kart['boost']) {
			@kart['velocity'] = min(1.0, @kart['velocity'] + 0.03);
		} else if(@acceleration > 0) {
			if(@kart['velocity'] < 0.8) {
				if(@kart['velocity'] < 0) {
					@kart['velocity'] = @kart['velocity'] + 0.02;
				} else {
					@kart['velocity'] = @kart['velocity'] + 0.01;
				}
			}
		} else if(@acceleration < 0) {
			@kart['velocity'] = max(@kart['velocity'] - 0.02, -0.3);
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
		if(@acceleration || !rand(20)) {
			play_sound(@vehicle, array(
				sound: 'ENTITY_BEE_LOOP',
				pitch: 0.5 + @kart['velocity'] * 1.5,
				volume: 4 + @acceleration));
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
			@hit = ray_trace(@origin, 0.6 - @vertical)['location'];
			@isLeft = true;
			if(@hit['y'] + 0.001 <= @loc['y']) {
				@isLeft = false;
				@origin['x'] += @right['x'];
				@origin['z'] += @right['z'];
				@hit = ray_trace(@origin, 0.6 - @vertical)['location'];
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
						play_named_sound(@loc, array(
							sound: 'block.vault.break',
							pitch: 1.3 - @kart['velocity'],
							volume: 4));
					}
					if(@dist2collision < 0.0625 && @magnitude < 0.03) {
						@velocity = array(x: 0, y: 0, z: 0);
						@kart['velocity'] = 0.0;
					} else {
						@face = @collision['hitface'];
						@yaw = @loc['yaw'];
						// Handles all acute angle wall collisions, but some corner cases still send the kart in the wrong direction
						if(@isLeft && @face === 'WEST' && @loc['yaw'] > 325.0 || !@isLeft && @face === 'EAST' && @loc['yaw'] < 35.0) {
							@loc['yaw'] = 0.0;
						} else if(@isLeft && @face === 'EAST' && @loc['yaw'] > 135.0 || !@isLeft && @face === 'WEST' && @loc['yaw'] < 215.0) {
							@loc['yaw'] = 180.0;
						} else if(@isLeft && @face === 'SOUTH' && @loc['yaw'] > 235.0 || !@isLeft && @face === 'NORTH' && @loc['yaw'] < 305.0) {
							@loc['yaw'] = 270.0;
						} else if(@isLeft && @face === 'NORTH' && @loc['yaw'] > 55.0 || !@isLeft && @face === 'SOUTH' && @loc['yaw'] < 125.0) {
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
							@kart['velocity'] *= 0.5;
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
						@vertical -= 0.09;
					} else {
						@loc['y'] = @hitRight['y'] + 0.001;
					}
				}
			} else {
				@loc['y'] = @hit['y'] + 0.001;
			}
			if(!equals_epsilon(@vertical, @kart['vertical'], 0.001)) {
				@kart['vertical'] = @vertical;
			} else if(@vertical < -0.1) {
				play_named_sound(@loc, array(
						sound: 'block.vault.break',
						pitch: 1.2 + @vertical,
						volume: 3));
				@kart['vertical'] = -0.1;
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
			set_display_entity(@kart['leftTire'], array(transformation: array(
				leftRotation: array(x: 0.0, y: @turn * 0.2, z: 0.0, w: 0.98))));
			set_display_entity(@kart['rightTire'], array(transformation: array(
				leftRotation: array(x: 0.0, y: @turn * 0.2, z: 0.0, w: 0.98))));
		} else {
			set_display_entity(@kart['leftTire'], array(transformation: array(
				leftRotation: array(x: 0.0, y: -@turn * 0.1, z: 0.0, w: 1.0))));
			set_display_entity(@kart['rightTire'], array(transformation: array(
				leftRotation: array(x: 0.0, y: -@turn * 0.1, z: 0.0, w: 1.0))));
		}
		set_entity_loc(@vehicle, @loc);

		// Rotate vehicle components
		@deltaYaw = @loc['yaw'] -  @pfacing[0];
		if(@deltaYaw < -180) {
			@deltaYaw += 360;
		} else if(@deltaYaw > 180) {
			@deltaYaw -= 360;
		}
		set_entity_rotation(@kart['head'], @pfacing[0] + @deltaYaw / 2, 0);
		foreach(@rider in get_entity_riders(@vehicle)) {
			set_entity_rotation(@rider, @loc['yaw'], @loc['pitch']);
		}

		// Spawn rubber particles
		if(@drift || @acceleration == 1 && @kart['velocity'] < 0.3) {
			@particle = array(
				particle: 'BLOCK_CRACK',
				block: 'BLACK_CONCRETE_POWDER',
				count: ceil(abs(@kart['velocity'] - 0.3) * 10),
				xoffset: 0.25,
				yoffset: 0.0,
				zoffset: 0.25);
			@particleLoc = @from[];
			@right = get_vector(array(yaw: @loc['yaw'] + 90, pitch: 0));
			@particleLoc['x'] += @right['x'] * 0.85 - @forward['x'] * 0.5 - @velocity['x'];
			@particleLoc['z'] += @right['z'] * 0.85 - @forward['z'] * 0.5 - @velocity['z'];
			spawn_particle(@particleLoc, @particle);
			@particleLoc['x'] -= @right['x'] * 1.7;
			@particleLoc['z'] -= @right['z'] * 1.7;
			spawn_particle(@particleLoc, @particle);
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
		}

		// Update camera location
		@camera = pvehicle(@player);
		@cameraOffset = get_vector(array(yaw: @pfacing[0], pitch: @pfacing[1]), 10 + @kart['velocity'] + if(@kart['boost'], 1, 0));
		@cameraLoc = @loc[];
		@cameraLoc['x'] -= @cameraOffset['x'];
		@cameraLoc['y'] += 10.0;
		@cameraLoc['z'] -= @cameraOffset['z'];
		set_entity_loc(@camera, @cameraLoc);

		// Check movement on course
		if(@race) {
			call_proc(@race['onMove'], @player, @loc, @race);
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
							translation: array(x: @translation['x'] * 4, y: @translation['y'] * 4, z: @translation['z'] * 4),
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
			play_sound(@loc, array(sound: 'ENTITY_GENERIC_EXPLODE', volume: 2));
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
		}
	});
}