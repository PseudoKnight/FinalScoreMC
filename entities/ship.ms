bind('entity_damage', null, array(type: 'INTERACTION'), @event) {
	if(has_scoreboard_tag(@event['id'], 'ship')) {
		try(entity_remove(get_entity_rider(@event['id'])))
		entity_remove(@event['id']);
	}
}

bind('player_interact_entity', null, array(clicked: 'INTERACTION', hand: 'main_hand'), @event) {
	@startTime = nano_time();
	if(!has_scoreboard_tag(@event['id'], 'ship') || pinv(player(), null)) {
		die();
	}

	@uuid = puuid();
	@spawnLocation = ploc();
	@world = pworld();

	@interactionLoc = entity_loc(@event['id']);
	@scale = get_display_entity(get_entity_rider(@event['id']))['transformation']['scale'];

	@height = @scale['y'];
	@widthX = @scale['x'];
	@widthZ = @scale['z'];
	@minY = integer(@interactionLoc['y']);
	@minX = integer(@interactionLoc['x'] - @widthX / 2);
	@minZ = integer(@interactionLoc['z'] - @widthZ / 2);

	@centerHeight = @height / 2;
	@maxWidth = max(@widthX, @widthZ);

	@colliderLoc = array(
		x: @interactionLoc['x'],
		y: @minY,
		z: @interactionLoc['z'],
		world: @world,
		yaw: 0,
		pitch: 0);
	@displayLoc = location_shift(@colliderLoc, 'up', @centerHeight);
	@exitOffset = array(
		x: @spawnLocation['x'] - @colliderLoc['x'],
		y: @spawnLocation['y'] - @colliderLoc['y'] + 1,
		z: @spawnLocation['z'] - @colliderLoc['z'],
		world: @spawnLocation['world']
	);
	@colliderLoc['y'] += @height;

	@primaryGuns = array();
	@boosters = array();
	@rotation = 0;
	@frames = array();
	foreach(@entity in select_entities('@e[x='.(@minX - 1).',y='.@minY.',z='.(@minZ - 1)
			.',dx='.(@widthX + 1).',dy='.(@height).',dz='.(@widthZ + 1).']')) {
		@type = entity_type(@entity);
		if(@type === 'GLOW_ITEM_FRAME') {
			@frameLoc = entity_loc(@entity);
			@yaw = @frameLoc['yaw'] + 180;
			if(@yaw > 360) {
				@yaw -= 360.0;
			}
			@colliderLoc['yaw'] = @yaw;
			@rotation = @yaw;
			@offset = 0;
			@axis = 'x';
			if(@rotation == 90 || @rotation == 270) {
				@offset = @frameLoc['z'] - @displayLoc['z'];
			} else {
				@offset = @frameLoc['x'] - @displayLoc['x'];
				@axis = 'z';
			}
			@boosters[] = array(
				widthOffset: @offset,
				heightOffset: @frameLoc['y'] - @displayLoc['y'],
				lengthOffset: @displayLoc[@axis] - @frameLoc[@axis]);
		} else if(@type === 'ITEM_FRAME') {
			@frames[] = @entity;
		}
	}
	@reverse = @rotation + 180;
	if(@reverse >= 360) {
		@reverse -= 360;
	}
	@length = 0;
	if(@rotation == 90 || @rotation == 270) {
		@length = @widthX;
	} else {
		@length = @widthZ;
	}
	foreach(@entity in @frames) {
		@frameLoc = entity_loc(@entity);
		if(@frameLoc['pitch'] == @reverse) {
			@offset = 0;
			@axis = 'x';
			if(@rotation == 90 || @rotation == 270) {
				@offset = @frameLoc['z'] - @displayLoc['z'];
			} else {
				@offset = @frameLoc['x'] - @displayLoc['x'];
				@axis = 'z';
			}
			@primaryGuns[] = array(
				widthOffset: @offset,
				heightOffset: @frameLoc['y'] - @displayLoc['y'],
				lengthOffset: @displayLoc[@axis] - @frameLoc[@axis]);
		}
	}
	@frames = null; // free

	@animateToShipTicks = 20;
	@vehicle = spawn_entity('ITEM_DISPLAY', 1, @displayLoc, closure(@e){
		set_entity_saves_on_unload(@e, false);
		set_display_entity(@e, array(
			width: @maxWidth,
			height: @height,
			teleportduration: @animateToShipTicks));
	})[0];
	@camera = spawn_entity('ITEM_DISPLAY', 1, location_shift(@spawnLocation, 'up', 2.5), closure(@e){
		set_entity_saves_on_unload(@e, false);
		set_display_entity(@e, array(teleportduration: @animateToShipTicks));
	})[0];
	@cameraInteraction = spawn_entity('INTERACTION', 1, @spawnLocation, closure(@e) {
		set_entity_saves_on_unload(@e, false);
		set_entity_spec(@e, array(width: 2, height: 3));
		add_scoreboard_tag(@e, 'ship-controls');
	})[0];
	set_entity_rider(@camera, @cameraInteraction);

	@blocks = array();
	for(@y = @minY, @y <= @minY + @height - 1, @y++) {
		queue_push(closure(){
			if(!entity_exists(@vehicle)) {
				die();
			}
			for(@x = @minX, @x <= @minX + @widthX - 1, @x++) {
				for(@z = @minZ, @z <= @minZ + @widthZ - 1, @z++) {
					@blockdata = get_blockdata(array(@x, @y, @z, @world));
					if(@blockdata['block'] !== 'air') {
						@block = spawn_entity('BLOCK_DISPLAY', 1, @displayLoc, closure(@e) {
							set_entity_saves_on_unload(@e, false);
							set_entity_spec(@e, array(blockdata: @blockdata));
							set_display_entity(@e, array(
								width: @maxWidth,
								height: @height,
								teleportduration: 2,
								interpolationduration: 2,
								transformation: array(
									translation: array(x: @x - @displayLoc['x'], y: @y - @displayLoc['y'], z: @z - @displayLoc['z']))));
						})[0];
						set_entity_rider(@vehicle, @block);
						@blocks[] = @block;
					}
				}
			}
		}, 'ship');
	}

	@mode = pmode();
	set_pmode('SPECTATOR');
	set_pexp(1);
	set_pspectator_target(@uuid, @camera);

	@speed = array(0.0);
	@colliders = array();
	@lastVelocity = array(x: 0, y: 0, z: 0, magnitude: 0);
	@ticksLived = array(0);

	set_interval(50, closure(){
		if(@ticksLived[0] > @animateToShipTicks && !entity_exists(@colliders[0])
		|| !ponline(player())
		|| pvehicle() !== @camera && (pmode() !== 'SPECTATOR' || pspectator_target(@uuid) !== @camera)) {
			clear_task();
			unbind(player().'ship');
			foreach(@entity in @blocks) {
				entity_remove(@entity);
			}
			entity_remove(@vehicle);
			entity_remove(@cameraInteraction);
			entity_remove(@camera);
			if(ponline(player())) {
				set_pmode(@mode);
				if(@mode === 'CREATIVE') {
					set_pflying(true);
				}
				if(@colliders && entity_exists(@colliders[0])) {
					// exiting vehicle
					@disembarkLoc = @colliderLoc[];
					@facing = pfacing();
					@disembarkLoc['x'] += @exitOffset['x'];
					@disembarkLoc['z'] += @exitOffset['z'];
					@disembarkLoc['yaw'] = @facing[0];
					@disembarkLoc['pitch'] = @facing[1];
					set_entity_loc(@uuid, @disembarkLoc);
				}
			}
			try(entity_remove(@colliders[0]))
			die();
		}

		++@ticksLived[0];
		set_peffect(player(), 'INVISIBILITY', 1, 1, true, false, false);

		if(@ticksLived[0] <= @animateToShipTicks) {
			@cameraVectorBack = get_vector(array(yaw: @reverse, pitch: 0), (@length + 1) / 2);
			@cameraVectorSwing = get_vector(array(yaw: @reverse, pitch: -45), hypot(@height, @height));
			@cameraLoc = array(
				x: @colliderLoc['x'] + @cameraVectorBack['x'] + @cameraVectorSwing['x'],
				y: @colliderLoc['y'] + @cameraVectorSwing['y'] + 1.5,
				z: @colliderLoc['z'] + @cameraVectorBack['z'] + @cameraVectorSwing['z'],
				world: @world,
				yaw: @rotation,
				pitch: 0);

			play_sound(@vehicle, array(sound: 'BLOCK_FIRE_EXTINGUISH', pitch: 0.5 + rand(), volume: @animateToShipTicks - @ticksLived[0] / @animateToShipTicks));
			@count = 0;
			@particleLoc = location_shift(@interactionLoc, 'down', 0.5);
			while(@count++ < @maxWidth) {
				spawn_particle(@particleLoc, array(particle: 'CLOUD', count: 0, speed: 0.3, xoffset: @widthX - rand() * @widthX * 2, yoffset: 0, zoffset: @widthZ - rand() * @widthZ * 2));
			}
			if(@ticksLived[0] < 2) {
				set_entity_loc(@uuid, @cameraLoc);
				set_entity_loc(@camera, @cameraLoc);
				set_entity_loc(@vehicle, location_shift(@colliderLoc, 'up', @centerHeight));
			} else if(@ticksLived[0] >= @animateToShipTicks) {
				set_pmode('ADVENTURE');
				set_entity_rider(@camera, @uuid);
				play_sound(@uuid, array(sound: 'ITEM_ARMOR_EQUIP_GENERIC', pitch: 0), player());
				@colliders[] = spawn_entity('ARMOR_STAND', 1, @colliderLoc, closure(@e){
					add_scoreboard_tag(@e, 'ship');
					set_entity_saves_on_unload(@e, false);
					set_entity_hidden_by_default(@e, true);
					set_entity_size(@e, min(@widthX, @widthZ) - 1, @height - 1);
					set_entity_attribute_base(@e, 'GENERIC_GRAVITY', 0.0);
				})[0];
				set_display_entity(@camera, array(teleportduration: 2));
				set_display_entity(@vehicle, array(teleportduration: 2));
			}
			die();
		}

		@velocity = entity_velocity(@colliders[0]);
		if(@velocity['x'] == 0 && abs(@lastVelocity['x']) > 0.4
		|| @velocity['y'] == 0 && abs(@lastVelocity['y']) > 0.4
		|| @velocity['z'] == 0 && abs(@lastVelocity['z']) > 0.4) {
			@loc = location_shift(@colliderLoc, 'up', @centerHeight);
			spawn_particle(@loc, array(particle: 'EXPLOSION_HUGE'));
			play_sound(@loc, array(sound: 'ENTITY_GENERIC_EXPLODE', pitch: 0.5, volume: 5));
			@forward = get_vector(@colliderLoc);
			@loc['x'] += @forward['x'] * ((@widthX / 2) - 1);
			@loc['y'] += @forward['y'] * (@centerHeight - 1);
			@loc['z'] += @forward['z'] * ((@widthZ / 2) - 1);
			@count = array_size(@blocks);
			spawn_particle(@loc, array(
				particle: 'EXPLOSION_LARGE',
				count: 0,
				force: true,
				speed: @maxWidth,
				xoffset: @maxWidth));
			spawn_particle(@loc, array(
				particle: 'CAMPFIRE_COSY_SMOKE',
				force: true,
				count: @count,
				speed: 0.01,
				xoffset: if(@velocity['x'] == 0 && abs(@lastVelocity['x']) > 0.4, 0, @widthX),
				yoffset: @height,
				zoffset: if(@velocity['z'] == 0 && abs(@lastVelocity['z']) > 0.4, 0, @widthZ)));
			spawn_particle(@loc, array(
				particle: 'CAMPFIRE_COSY_SMOKE',
				force: true,
				count: @count,
				speed: 0.1,
				xoffset: if(@velocity['x'] == 0 && abs(@lastVelocity['x']) > 0.4, 0, 1),
				yoffset: 0.5,
				zoffset: if(@velocity['z'] == 0 && abs(@lastVelocity['z']) > 0.4, 0, 1)));
			entity_remove(@colliders[0]);
			die();
		} else if(@velocity['x'] == 0 && abs(@lastVelocity['x']) > 0.1
		|| @velocity['y'] == 0 && abs(@lastVelocity['y']) > 0.1
		|| @velocity['z'] == 0 && abs(@lastVelocity['z']) > 0.1) {
			play_sound(@colliderLoc, array(
				sound: 'BLOCK_NETHERITE_BLOCK_BREAK',
				pitch: 0.5,
				volume: 3));
			play_sound(@colliderLoc, array(
				sound: 'BLOCK_COPPER_GRATE_BREAK',
				pitch: 0.5,
				volume: 3));
		}
		@lastVelocity['x'] = @velocity['x'];
		@lastVelocity['y'] = @velocity['y'];
		@lastVelocity['z'] = @velocity['z'];
		@lastVelocity['magnitude'] = @velocity['magnitude'];

		@input = get_player_input();
		@pfacing = pfacing();
		@diffYaw = @pfacing[0] - @colliderLoc['yaw'];
		if(abs(@diffYaw) > 180) {
			if(@diffYaw < 0) {
				@diffYaw += 360;
			} else {
				@diffYaw -= 360;
			}
		}

		if(!@input['sprint']) {
			@minAngle = 1.40625; // 1.40625 is 1/256 (byte) of 360 degrees
			@maxAngle = 1.40625;
			if(!@input['forward']) {
				@maxAngle *= 2;
			}
			if(@diffYaw < -@minAngle) {
				if(@diffYaw < -@maxAngle) {
					@colliderLoc['yaw'] -= @maxAngle;
				} else {
					@colliderLoc['yaw'] -= @minAngle;
				}
				if(@colliderLoc['yaw'] < 0.0) {
					@colliderLoc['yaw'] += 360.0;
				}
			} else if(@diffYaw > @minAngle) {
				if(@diffYaw > @maxAngle) {
					@colliderLoc['yaw'] += @maxAngle;
				} else {
					@colliderLoc['yaw'] += @minAngle;
				}
				if(@colliderLoc['yaw'] >= 360.0) {
					@colliderLoc['yaw'] -= 360.0;
				}
			}

			@diffPitch = @pfacing[1] - @colliderLoc['pitch'];
			if(@diffPitch < -@minAngle) {
				@colliderLoc['pitch'] = min(90, @colliderLoc['pitch'] -@minAngle);
			} else if(@diffPitch > @minAngle) {
				@colliderLoc['pitch'] = max(-90, @colliderLoc['pitch'] + @minAngle);
			}
		}

		play_sound(@vehicle, array(sound: 'ENTITY_BREEZE_IDLE_GROUND', pitch: @speed[0], volume: ((@height + @maxWidth / 2) / 16) * @speed[0]), player());

		@forward = get_vector(@colliderLoc);
		if(@input['forward']) {
			play_sound(@vehicle, array(sound: 'ENTITY_ARMADILLO_LAND', pitch: 0, volume: 3));
			play_sound(@vehicle, array(sound: 'ENTITY_CAMEL_STEP', pitch: 0, volume: 3));
			@right = get_vector(array(yaw: @colliderLoc['yaw'] + 90, pitch: 0));
			@up = get_vector(array(yaw: @colliderLoc['yaw'], pitch: @colliderLoc['pitch'] - 90));
			foreach(@booster in @boosters) {
				@speed[0] = min(2.0, @speed[0] + 0.6 / (array_size(@blocks) + array_size(@primaryGuns) * 5));
				@particleLoc = array(
					x: @colliderLoc['x'] - @forward['x'] * @speed[0] 
							+ @forward['x'] * @booster['lengthOffset']
							+ @up['x'] * @booster['heightOffset']
							+ @right['x'] * @booster['widthOffset'],
					y: @colliderLoc['y'] - @forward['y'] * @speed[0] + @centerHeight
							+ @forward['y'] * @booster['lengthOffset']
							+ @up['y'] * @booster['heightOffset'],
					z: @colliderLoc['z'] - @forward['z'] * @speed[0]
							+ @forward['z'] * @booster['lengthOffset']
							+ @up['z'] * @booster['heightOffset']
							+ @right['z'] * @booster['widthOffset'],
					world: @world);
				spawn_particle(@particleLoc, array(particle: 'FLAME', count: 20, xoffset: 0.5, yoffset: 0.5, zoffset: 0.5));
				spawn_particle(@particleLoc, array(particle: 'CAMPFIRE_SIGNAL_SMOKE'));
			}
		} else if(@input['backward']) {
			if(@speed[0] > 0) {
				play_sound(@vehicle, array(sound: 'ENTITY_ARMADILLO_LAND', pitch: 0, volume: 2));
				play_sound(@vehicle, array(sound: 'ENTITY_CAMEL_STEP', pitch: 0, volume: 2));
				@speed[0] = max(0.0, @speed[0] - 0.5 / (array_size(@blocks) + array_size(@primaryGuns) * 5));
			}
		} else {
			set_pexp(min(99, pexp() + if(pexp() >= 1 || !(@ticksLived[0] % 20), 2, 0)));
			@speed[0] *= 0.995;
		}

		if(@speed[0] < 0.25) {
			@v = get_vector(array(yaw: rand(360), pitch: -rand(10)));
			@particleLoc = array(
				x: @colliderLoc['x'] + @v['x'] * @widthX / 4,
				y: @colliderLoc['y'] + 0.5,
				z: @colliderLoc['z'] + @v['z'] * @widthZ / 4,
				world: @colliderLoc['world'],
				yaw: 0,
				pitch: 90.0
			);
			@trace = ray_trace(player(), @particleLoc, @height);
			if(@trace['hitblock']) {
				spawn_particle(@trace['location'], array(particle: 'CLOUD', count: 0, speed: 1.0, xoffset: @v['x'] * 1.5, yoffset: @v['y'], zoffset: @v['z'] * 1.5));
			}
			play_sound(@vehicle, array(sound: 'ENTITY_CAMEL_STEP', pitch: rand(), volume: 2));
		}

		@shipVector = get_vector(@colliderLoc, @speed[0]);
		@newLoc = entity_loc(@colliders[0]);
		@colliderLoc['x'] = @newLoc['x'];
		@colliderLoc['y'] = @newLoc['y'];
		@colliderLoc['z'] = @newLoc['z'];
		set_entity_velocity(@colliders[0], @shipVector);
		set_entity_loc(@vehicle, location_shift(@colliderLoc, 'up', @centerHeight));
		@displayYaw = @colliderLoc['yaw'] - @rotation;
		@displayPitch = -@colliderLoc['pitch'];
		foreach(@entity in @blocks) {
			set_entity_rotation(@entity, @displayYaw, @displayPitch);
		}

		@yaw = @pfacing[0] + 180;
		@pitch = -@pfacing[1];
		@cameraVectorBack = get_vector(array(yaw: @yaw, pitch: @pitch), (@length + 1) / 2);
		@cameraVectorSwing = get_vector(array(yaw: @yaw, pitch: @pitch - 45), hypot(@height, @height));
		@cameraLoc = array(
			x: @colliderLoc['x'] + @cameraVectorBack['x'] + @cameraVectorSwing['x'],
			y: @colliderLoc['y'] + @cameraVectorBack['y'] + @cameraVectorSwing['y'],
			z: @colliderLoc['z'] + @cameraVectorBack['z'] + @cameraVectorSwing['z'],
			world: @world);
		set_entity_loc(@camera, @cameraLoc);
	});

	if(@primaryGuns) {
		// primary gun
		bind('player_interact_entity', array(id: player().'ship'), array(clicked: 'INTERACTION'), @event,
				@player = player(),
				@vehicle,
				@colliderLoc,
				@colliders,
				@speed,
				@primaryGuns,
				@cost = integer(99 / (array_size(@primaryGuns) * 3)),
				@centerHeight,
				@gunAlternate = array(0)) {

			if(@player !== player() || !has_scoreboard_tag(@event['id'], 'ship-controls')) {
				die();
			}

			@charge = pexp();
			if(@charge < @cost) {
				play_sound(@vehicle, array(sound: 'BLOCK_VAULT_CLOSE_SHUTTER', pitch: 2, volume: 2));
				set_pexp(0);
				die();
			}
			set_pexp(@charge - @cost);

			play_sound(@vehicle, array(sound: 'ENTITY_ALLAY_HURT', pitch: 0.5, volume: 3));
			play_sound(@vehicle, array(sound: 'ENTITY_IRON_GOLEM_REPAIR', pitch: 2, volume: 3));

			if(@gunAlternate[0] > array_size(@primaryGuns) - 1) {
				@gunAlternate[0] = 0;
			}
			@gun = @primaryGuns[@gunAlternate[0]++];

			@forward = get_vector(@colliderLoc);
			@right = get_vector(array(yaw: @colliderLoc['yaw'] + 90, pitch: 0));
			@up = get_vector(array(yaw: @colliderLoc['yaw'], pitch: @colliderLoc['pitch'] - 90));

			@loc = array(
				x: @colliderLoc['x'] - @forward['x'] * @speed[0] + @forward['x'] * 3
						+ @forward['x'] * @gun['lengthOffset']
						+ @up['x'] * @gun['heightOffset']
						+ @right['x'] * @gun['widthOffset'],
				y: @colliderLoc['y'] - @forward['y'] * @speed[0] + @forward['y'] * 3 + @centerHeight
						+ @forward['y'] * @gun['lengthOffset']
						+ @up['y'] * @gun['heightOffset'],
				z: @colliderLoc['z'] - @forward['z'] * @speed[0] + @forward['z'] * 3
						+ @forward['z'] * @gun['lengthOffset']
						+ @up['z'] * @gun['heightOffset']
						+ @right['z'] * @gun['widthOffset'],
				world: @colliderLoc['world'],
				yaw: @colliderLoc['yaw'],
				pitch: @colliderLoc['pitch']);

			@laser = spawn_entity('ITEM_DISPLAY', 1, @loc, closure(@laser){
				set_entity_saves_on_unload(@laser, false);
				set_display_entity(@laser, array(
					brightness: 15,
					teleportduration: 2,
					transformation: array(
						scale: array(x: 0.125, y: 0.125, z: 7.0),
						translation: array(x: 0, y: 0, z: 0))));
				set_entity_spec(@laser, array(item: array(name: 'OCHRE_FROGLIGHT')));
			})[0];

			@distance = array(0);
			set_interval(50, 0, closure(){
				@distance[0] += @speed[0] + 6;
				if(@distance[0] > 96) {
					try(entity_remove(@laser))
					if(get_block(@loc) === 'LIGHT') {
						set_block(@loc, 'AIR');
					}
					clear_task();
					die();
				}
				@trace = ray_trace(player(), @loc, @speed[0] + 6, 0.125);
				@hit = @trace['hitblock'];
				foreach(@entity in @trace['entities']) {
					if(@entity['uuid'] !== @colliders[0]) {
						if(has_scoreboard_tag(@entity['uuid'], 'ship')) {
							spawn_particle(@entity['location'], array(particle: 'EXPLOSION_LARGE', count: 0, force: true, speed: 4, xoffset: 4));
							@centered = location_shift(entity_loc(@entity['uuid']), 'up', 2);
							spawn_particle(@centered, array(particle: 'EXPLOSION_LARGE', count: 0, force: true, speed: 6, xoffset: 6));
							spawn_particle(@centered, array(particle: 'EXPLOSION_HUGE', force: true));
							@count = array_size(get_entity_riders(@entity['uuid']));
							spawn_particle(@centered, array(particle: 'CAMPFIRE_SIGNAL_SMOKE', force: true, speed: 0.1, xoffset: 1, yoffset: 0.5, zoffset: 1, count: @count));
							play_sound(@centered, array(sound: 'ENTITY_GENERIC_EXPLODE', pitch: 0.5, volume: 5));
							entity_remove(@entity['uuid']);
						}
						@hit = true;
						break();
					}
				}
				if(@hit) {
					try(entity_remove(@laser))
					if(get_block(@loc) === 'LIGHT') {
						set_block(@loc, 'AIR');
					}
					@loc['x'] = @trace['location']['x'];
					@loc['y'] = @trace['location']['y'];
					@loc['z'] = @trace['location']['z'];
					play_sound(@loc, array(sound: 'ENTITY_GENERIC_BURN', pitch: 2, volume: 5));
					play_sound(@loc, array(sound: 'ENTITY_IRON_GOLEM_DAMAGE', pitch: 1.5, volume: 5));
					play_sound(@loc, array(sound: 'BLOCK_NOTE_BLOCK_BASEDRUM', pitch: 2, volume: 5));
					play_sound(@loc, array(sound: 'ENTITY_GENERIC_EXPLODE', volume: 5));
					spawn_particle(@loc, array(particle: 'LAVA', count: 25, force: true, xoffset: 0.25, yoffset: 0.25, zoffset: 0.25));
					if(get_block(@loc) === 'AIR') {
						set_blockdata(@loc, array(block: 'light', level: 15));
					}
					set_interval(150, closure(){
						@blockdata = get_blockdata(@loc);
						if(@blockdata['block'] === 'light') {
							if(@blockdata['level'] < 2) {
								set_block(@loc, 'AIR');
								clear_task();
							} else {
								set_blockdata(@loc, array(block: 'light', level: @blockdata['level'] - 1));
							}
						} else {
							clear_task();
						}
					});
					clear_task();
				} else {
					if(get_block(@loc) === 'LIGHT') {
						set_block(@loc, 'AIR');
					}
					@loc['x'] = @trace['location']['x'];
					@loc['y'] = @trace['location']['y'];
					@loc['z'] = @trace['location']['z'];
					set_entity_loc(@laser, @loc);
					if(get_block(@loc) === 'AIR') {
						set_blockdata(@loc, array(block: 'light', level: 9));
					}
				}
			});
		}
	}

	console('Spawned ship in '.((nano_time() - @startTime) / 1000).' microseconds.');
}