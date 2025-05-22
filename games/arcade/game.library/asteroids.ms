<!
	description: A mini game of asteroids to be displayed on an item frame using text display entities.;
>
proc _load_arcade_game(@itemFrameId) {
	@player = player();

	// game constants
	@minX = -0.5;
	@maxX = 0.5;
	@minY = -0.5;
	@maxY = 0.5;
	@asteroidColor = array(r: 142, g: 80, b: 33, a: 255);
	// ♎⦵ enemy ships

	// get origin position and rotation based on item frame location
	@origin = entity_loc(@itemFrameId);
	switch(get_hanging_direction(@itemFrameId)) {
		case 'NORTH':
			@origin['yaw'] = 180;
		case 'EAST':
			@origin['yaw'] = 270;
		case 'SOUTH':
			@origin['yaw'] = 0;
		case 'WEST':
			@origin['yaw'] = 90;
		default:
			return();
	}

	// clear previous text display entities
	foreach(@entity in entities_in_radius(@origin, 1, 'TEXT_DISPLAY')) {
		if(has_scoreboard_tag(@entity, 'arcade')) {
			entity_remove(@entity);
		}
	}

	// game state
	@pos = array(0.0, 0.0);
	@vector = array(0.0, 0.0);
	@state = array(
		yaw: 0.0,
		shooting: false,
		forward: false,
		hyperspaceCooldown: 0,
		hyperspaceTime: 0,
		hyperspaceFlash: null,
		dead: false,
		gameoverCountdown: 20,
		asteroidCount: 4);

	@projectiles = array();
	@asteroids = array();

	// spawn chair entity
	@seat = _spawn_seat();

	// spawn ship entity
	@ship = spawn_entity('TEXT_DISPLAY', 1, @origin, closure(@e) {
		add_scoreboard_tag(@e, 'arcade');
		set_display_entity(@e, array(
			brightness: 15,
			width: 1.0,
			height: 1.0,
			transformation: array(
				scale: array(
					x: 0.2,
					y: 0.25,
					z: 0),
				translation: array(
					x: @pos[0],
					y: @pos[1] - 0.025,
					z: 0))));
		set_entity_spec(@e, array(
			text: '⮝',
			bgcolor: array(r: 0, g: 0, b: 0, a: 0)));
	})[0];

	set_interval(50, closure(){
		if(!ponline(@player)) {
			clear_task();
			remove_metadata(@itemFrameId, 'arcade', 'CommandHelper');
			die();
		}

		// check if still seated or ship entity is missing
		if(@state['dead'] && --@state['gameoverCountdown'] > 0) {
			return();
		}
		@vehicle = pvehicle();
		if(!@vehicle || !entity_exists(@ship) || @state['dead']) {
			// if vehicle (seat) or ship entity do not exist, the game should end.
			if(entity_exists(@seat)) {
				entity_remove(@seat);
			}
			clear_task();
			remove_metadata(@itemFrameId, 'arcade', 'CommandHelper');
			die();
		}

		// process player input
		@input = get_player_input();
		if(@input['forward']) {
			if(!@state['forward']) {
				play_sound(ploc(), array(sound: 'ENTITY_GUARDIAN_ATTACK'), player());
				@state['forward'] = true;
			}
			@acceleration = get_vector(array(yaw: @state['yaw'], pitch: 0), 0.001);
			@vector[0] += @acceleration[0];
			@vector[1] += @acceleration[2];
		} else if(@state['forward']) {
			stop_sound(player(), array(sound: 'ENTITY_GUARDIAN_ATTACK'));
			@state['forward'] = false;
		}
		if(@input['left'] && !@input['right']) {
			@state['yaw'] += 7;
			if(@state['yaw'] < 0) {
				@state['yaw'] += 360.0;
			}
		} else if(@input['right'] && !@input['left']) {
			@state['yaw'] -= 7;
			if(@state['yaw'] > 360.0) {
				@state['yaw'] -= 360.0;
			}
		}
		@shooting = false;
		if(@state['shooting']) {
			// must unpress key to fire again
			if(!@input['jump']) {
				@state['shooting'] = false;
			}
		} else {
			@shooting = @input['jump'];
		}
		@hyperspace = false;
		if(@state['hyperspaceCooldown']) {
			@state['hyperspaceCooldown']--;
			if(@state['hyperspaceTime']) {
				// adjust ship after-image following hyperspace
				set_entity_spec(@state['hyperspaceFlash'], array(opacity: @state['hyperspaceTime'] * 20));
				@state['hyperspaceTime']--;
			} else if(@state['hyperspaceFlash']) {
				entity_remove(@state['hyperspaceFlash']);
				@state['hyperspaceFlash'] = null;
			}
		} else {
			@hyperspace = @input['backward'];
		}

		// calculate new ship position
		if(@hyperspace) { // teleport ship
			play_sound(ploc(), array(sound: 'ENTITY_ENDERMAN_TELEPORT', pitch: 0.5));
			@state['hyperspaceCooldown'] = 20;
			@state['hyperspaceTime'] = 5;
			@shipDisplay = get_display_entity(@ship);
			@state['hyperspaceFlash'] = spawn_entity('TEXT_DISPLAY', 1, @origin, closure(@e) {
				add_scoreboard_tag(@e, 'arcade');
				set_display_entity(@e, @shipDisplay);
				set_entity_spec(@e, array(
					opacity: 120,
					text: '⮝',
					bgcolor: array(r: 0, g: 0, b: 0, a: 0)));
			})[0];
			@pos[0] = rand() * @maxX * 2 - @maxX;
			@pos[1] = rand() * @maxY * 2 - @maxY;

		} else { // move ship
			@vector[0] *= 0.985; // fake friction improves control
			@vector[1] *= 0.985;

			@pos[0] += @vector[0];
			@pos[1] += @vector[1];

			// wrap screen
			if(@pos[0] > @maxX) {
				@pos[0] = @minX;
			} else if(@pos[0] < @minX) {
				@pos[0] = @maxX;
			}
			if(@pos[1] > @maxY) {
				@pos[1] = @minY;
			} else if(@pos[1] < @minY) {
				@pos[1] = @maxY;
			}
		}

		if(@shooting) {
			@state['shooting'] = true;
			play_sound(ploc(), array(sound: 'ENTITY_ENDER_DRAGON_HURT', pitch: 2, volume: 0.5));
			play_sound(ploc(), array(sound: 'BLOCK_NOTE_BLOCK_BIT', pitch: 2));
			@ppos = array(@pos[0], @pos[1]);
			@v = get_vector(array(yaw: @state['yaw'], pitch: 0), -0.015);
			@projectile = spawn_entity('TEXT_DISPLAY', 1, @origin, closure(@e) {
					add_scoreboard_tag(@e, 'arcade');
					set_display_entity(@e, array(
						brightness: 15,
						width: 1.0,
						height: 1.0,
						transformation: array(
							scale: array(
								x: 0.03,
								y: 0.03,
								z: 0),
							translation: array(
								x: @ppos[0] + @v[0],
								y: @ppos[1] + @v[2],
								z: 0))));
					set_entity_spec(@e, array(
						text: ' ',
						bgcolor: array(r: 255, g: 255, b: 255, a: 255)));
			})[0];
			@projectiles[] = array(
				pos: @ppos,
				entity: @projectile,
				yaw: @state['yaw'],
				lifetime: 20);
		}

		if(!@asteroids) {
			for(@i = 0, @i < @state['asteroidCount'], @i++) {
				@rpos = null
				if(rand(2)) {
					@rpos = array(
						rand() * @maxX * 2 - @maxX,
						rand(2) - 0.5,
					);
				} else {
					@rpos = array(
						rand(2) - 0.5,
						rand() * @maxY * 2 - @maxY,
					);
				}
				@rotation = 0; // randomly rotate here, disabled for now
				@z = to_radians(@rotation) * 0.5;
				@leftRotation = array(
					w: cos(@z),
					x: 0,
					y: 0,
					z: sin(@z));
				@size = 0.4;
				@v = get_vector(array(yaw: @rotation, pitch: 0), -(@size / 8));
				@asteroid = spawn_entity('TEXT_DISPLAY', 1, @origin, closure(@e) {
					add_scoreboard_tag(@e, 'arcade');
					set_display_entity(@e, array(
						brightness: 15,
						width: 1.0,
						height: 1.0,
						transformation: array(
							scale: array(
								x: @size * 2,
								y: @size,
								z: 0),
							translation: array(
								x: @rpos[0] + @v[0] - @size / 40,
								y: @rpos[1] + @v[2],
								z: 0),
							leftRotation: @leftRotation)));
					set_entity_spec(@e, array(
						text: ' ',
						bgcolor: @asteroidColor));
				})[0];
				@asteroids[] = array(
					entity: @asteroid,
					pos: @rpos,
					yaw: rand() * 360,
					speed: rand() / 100,
					size: @size,
					rotation: @rotation);
			}
			@state['asteroidCount'] = min(11, @state['asteroidCount'] + 2);
		}

		foreach(@i: @asteroid in @asteroids) {
			@v = get_vector(array(yaw: @asteroid['yaw'], pitch: 0), @asteroid['speed']);
			@asteroid['pos'][0] += @v[0];
			@asteroid['pos'][1] += @v[2];
			@interp = true;
			// wrap screen
			if(@asteroid['pos'][0] > @maxX) {
				@asteroid['pos'][0] = @minX;
				@interp = false;
			} else if(@asteroid['pos'][0] < @minX) {
				@asteroid['pos'][0] = @maxX;
				@interp = false;
			}
			if(@asteroid['pos'][1] > @maxY) {
				@asteroid['pos'][1] = @minY;
				@interp = false;
			} else if(@asteroid['pos'][1] < @minY) {
				@asteroid['pos'][1] = @maxY;
				@interp = false;
			}
			@v = get_vector(array(yaw: @asteroid['rotation'], pitch: 0), -(@asteroid['size'] / 8));
			set_display_entity(@asteroid['entity'], array(
				interpolationduration: 0,
				transformation: array(
					translation: array(
						x: @asteroid['pos'][0] + @v[0] - @asteroid['size'] / 40,
						y: @asteroid['pos'][1] + @v[2],
						z: 0))));
			if(@interp) {
				set_display_entity(@asteroid['entity'], array(
					interpolationduration: 1,
					startinterpolation: 0));
			}

			if(abs(@pos[0] - @asteroid['pos'][0]) < @asteroid['size'] / 8
			&& abs(@pos[1] - @asteroid['pos'][1]) < @asteroid['size'] / 8) {
				play_sound(ploc(), array(sound: 'ENTITY_BREEZE_SHOOT', pitch: 0.5));
				@state['dead'] = true;
				set_entity_spec(@ship, array(text: '✴', opacity: 255));
				@v = get_vector(array(yaw: @state['yaw'], pitch: 0), -0.12);
				set_display_entity(@ship, array(
					interpolationduration: 2,
					startinterpolation: 0,
					transformation: array(
						translation: array(
							x: @pos[0] + @v[0],
							y: @pos[1] + @v[2],
							z: 0),
						scale: array(
							x: 1,
							y: 1,
							z: 0))));
				return();
			}
		}

		foreach(@i: @projectile in @projectiles) {
			@projectile['lifetime']--;
			if(!@projectile['lifetime']) {
				entity_remove(@projectile['entity']);
				array_remove(@projectiles, @i);
			} else {
				@v = get_vector(array(yaw: @projectile['yaw'], pitch: 0), 0.03);
				@projectile['pos'][0] += @v[0];
				@projectile['pos'][1] += @v[2];
				@interp = true;
				// wrap screen
				if(@projectile['pos'][0] > @maxX) {
					@interp = false;
					@projectile['pos'][0] = @minX;
				} else if(@projectile['pos'][0] < @minX) {
					@interp = false;
					@projectile['pos'][0] = @maxX;
				}
				if(@projectile['pos'][1] > @maxY) {
					@interp = false;
					@projectile['pos'][1] = @minY;
				} else if(@projectile['pos'][1] < @minY) {
					@interp = false;
					@projectile['pos'][1] = @maxY;
				}
				@v = get_vector(array(yaw: @projectile['yaw'], pitch: 0), -0.015);
				set_display_entity(@projectile['entity'], array(
					interpolationduration: 0,
					transformation: array(
						translation: array(
							x: @projectile['pos'][0] + @v[0],
							y: @projectile['pos'][1] + @v[2],
							z: 0))));
				if(@interp) {
					set_display_entity(@projectile['entity'], array(
						interpolationduration: 1,
						startinterpolation: 0));
				}
				if(@projectile['lifetime'] < 2) {
					continue();
				}
				foreach(@j: @asteroid in @asteroids) {
					if(abs(@projectile['pos'][0] - @asteroid['pos'][0]) < @asteroid['size'] / 8
					&& abs(@projectile['pos'][1] - @asteroid['pos'][1]) < @asteroid['size'] / 8) {
						@projectile['lifetime'] = 2;
						entity_remove(@asteroid['entity']);
						array_remove(@asteroids, @j);
						play_sound(ploc(), array(sound: 'ENTITY_BREEZE_SHOOT', pitch: 0.8, volume: 0.3));
						if(@asteroid['size'] > 0.1) {
							for(@n = 0, @n < 2, @n++) {
								@rotation = 0; // randomly rotate here
								@z = to_radians(@rotation) * 0.5;
								@leftRotation = array(
									w: cos(@z),
									x: 0,
									y: 0,
									z: sin(@z));
								@size = @asteroid['size'] / 2;
								@smallasteroid = spawn_entity('TEXT_DISPLAY', 1, @origin, closure(@e) {
									add_scoreboard_tag(@e, 'arcade');
									set_display_entity(@e, array(
										brightness: 15,
										width: 1.0,
										height: 1.0,
										transformation: array(
											scale: array(
												x: @size * 2,
												y: @size,
												z: 0),
											translation: array(
												x: @asteroid['pos'][0],
												y: @asteroid['pos'][1] - 0.02,
												z: 0),
											leftRotation: @leftRotation)));
									set_entity_spec(@e, array(
										text: ' ',
										bgcolor: @asteroidColor));
								})[0];
								@asteroids[] = array(
									entity: @smallasteroid,
									pos: @asteroid['pos'][],
									yaw: @asteroid['yaw'] + rand() * 90 - 45,
									speed: @asteroid['speed'] * (1 + rand() * 0.9),
									size: @size,
									rotation: @rotation);
							}
						}
						break();
					}
				}
			}
		}

		// render ship
		@z = to_radians(@state['yaw']) * 0.5;
		@leftRotation = array(
			w: cos(@z),
			x: 0,
			y: 0,
			z: sin(@z));
		@v = get_vector(array(yaw: @state['yaw'], pitch: 0), -0.025);
		set_display_entity(@ship, array(
			interpolationduration: 1,
			startinterpolation: 0,
			transformation: array(
				translation: array(
					x: @pos[0] + @v[0],
					y: @pos[1] + @v[2],
					z: 0),
				leftRotation: @leftRotation)));
	});
}