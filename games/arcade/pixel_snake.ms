bind('player_interact_entity', null, array(clicked: 'ITEM_FRAME', hand: 'main_hand'), @event) {
	@spec = entity_spec(@event['id']);
	if(@spec['visible']) {
		die();
	}
	@item = @spec['item'];
	if(!@item || @item['name'] !== 'FILLED_MAP') {
		die();
	}
	@meta = @item['meta'];
	if(!@meta || !@meta['lore'] || @meta['lore'][0] !== 'snake') {
		die();
	}

	// global variables
	@width = 32;
	@scale = 1 / (@width + 1);
	
	// define game state
	@pos = array(integer(@width / 2), integer(@width / 2));
	@applePos = array(rand(@width), rand(@width));
	@snake = array(
		dir: 'up', // up, down, left, right
		length: 1,
		maxLength: 8,
		dead: false,
		tail: null,
		score: 0,
	);
	@grid = array_resize(array(), @width);
	foreach(@i: @row in @grid) {
		@grid[@i] = array_resize(array(), @width, false);
	}

	// get origin location and rotation
	@origin = entity_loc(@event['id']);
	switch(get_hanging_direction(@event['id'])) {
		case 'UP':
		case 'DOWN':
			@origin['x'] -= 0.47;
			@origin['z'] -= 0.47;
			@origin['yaw'] = round(ploc()['yaw'] / 90) * 90;
		case 'NORTH':
			@origin['y'] += 0.46;
			@origin['x'] += 0.47;
			@origin['yaw'] = 180;
		case 'EAST':
			@origin['y'] += 0.46;
			@origin['z'] += 0.47;
			@origin['yaw'] = 270;
		case 'SOUTH':
			@origin['y'] += 0.46;
			@origin['x'] -= 0.47;
			@origin['yaw'] = 0;
		case 'WEST':
			@origin['y'] += 0.46;
			@origin['z'] -= 0.47;
			@origin['yaw'] = 90;
	}

	// clear previous entities
	foreach(@entity in entities_in_radius(@origin, 1, 'TEXT_DISPLAY')) {
		entity_remove(@entity);
	}

	// spawn chair entity
	@seatLoc = location_shift(ploc(), 'up', 1.6)
	@seatLoc['yaw'] += 90;
	@seatLoc['pitch'] = 0;
	@seat = spawn_entity('ITEM_DISPLAY', 1, @seatLoc, closure(@e){
		set_entity_spec(@e, array(item: array(name: 'OAK_STAIRS')));
		set_entity_saves_on_unload(@e, false);
		set_display_entity(@e, array(
			brightness: 15,
			transformation: array(
				scale: array(x: 0.5, y: 0.5, z: 0.5))));
	})[0];
	set_entity_rider(@seat, puuid());

	// spawn apple entity
	@apple = spawn_entity('TEXT_DISPLAY', 1, @origin, closure(@e) {
		set_display_entity(@e, array(
			brightness: 15,
			transformation: array(
				scale: array(
					x: @scale * 8,
					y: @scale * 4,
					z: 0),
				translation: array(
					x: @applePos[0] * @scale,
					y: -(@applePos[1] * @scale),
					z: 0))));
		set_entity_spec(@e, array(
			text: ' ',
			alignment: 'LEFT',
			bgcolor: array(r: 255, g: 0, b: 0, a: 255)));
	})[0];

	// spawn snake head entity
	@head = spawn_entity('TEXT_DISPLAY', 1, @origin, closure(@e) {
		set_display_entity(@e, array(
			brightness: 15,
			transformation: array(
				scale: array(
					x: @scale * 8,
					y: @scale * 4,
					z: 0),
				translation: array(
					x: @pos[0] * @scale,
					y: -(@pos[1] * @scale),
					z: 0))));
		set_entity_spec(@e, array(
			text: ' ',
			alignment: 'LEFT',
			bgcolor: array(r: 64, g: 255, b: 192, a: 255)));
	})[0];

	// spawn score entity
	@score = spawn_entity('TEXT_DISPLAY', 1, @origin, closure(@e) {
		set_display_entity(@e, array(
			brightness: 15,
			transformation: array(
				scale: array(
					x: 0.4,
					y: 0.4,
					z: 0),
				translation: array(
					x: 0.88,
					y: -0.08,
					z: 0.02))));
		set_entity_spec(@e, array(
			text: ' 0',
			bgcolor: array(r: 0, g: 0, b: 0, a: 0)));
	})[0];

	@tail = array();

	@notes = array(1, null, null, 3, null, null, 5, null, null, 3, null, null, 1, null, null, 3, null, null, 5, null, null, null, null, null, 1, null, null, null, null, null, 1);

	@bufferedInput = array(null);
	@tick = array(0);
	@tickInterval = array(3);

	// start game loop
	set_interval(50, closure(){
		if(@notes) {
			if(!is_null(@notes[0])) {
				play_sound(ploc(), array(sound: 'BLOCK_NOTE_BLOCK_BIT', pitch: 2 ** ((@notes[0] - 12) / 12)));
			}
			array_remove(@notes, 0);
		}

		@vehicle = pvehicle();
		if(!@vehicle || !entity_exists(@head)) {

			if(entity_exists(@seat)) {
				try(entity_remove(@seat))
				spawn_entity('TEXT_DISPLAY', 1, entity_loc(@event['id']), closure(@e) {
					set_display_entity(@e, array(
						brightness: 15,
						transformation: array(
							scale: array(
								x: 0.7,
								y: 0.7,
								z: 0))));
					set_entity_spec(@e, array(
						text: color('#151515').color('BOLD').'SNAKE',
						bgcolor: array(r: 64, g: 128, b: 96, a: 255)));
				})[0];
			} else {
				spawn_entity('TEXT_DISPLAY', 1, entity_loc(@event['id']), closure(@e) {
					set_display_entity(@e, array(
						brightness: 15,
						transformation: array(
							scale: array(
								x: 0.5,
								y: 0.5,
								z: 0))));
					set_entity_spec(@e, array(
						text: color('#151515').color('BOLD').'GAME OVER',
						bgcolor: array(r: 64, g: 128, b: 96, a: 255)));
				})[0];
			}

			clear_task();
			die();
		}

		@tick[0]++;
		@lastDir = @snake['dir'];
		@input = get_player_input();
		@turned = false;
		if(@input['forward'] && @lastDir !== 'up' && @lastDir !== 'down') {
			if(@tick[0] % @tickInterval[0] > 0) {
				@bufferedInput[0] = 'up';
				die();
			}
			@snake['dir'] = 'up';
			@turned = true;
		} else if(@input['backward'] && @lastDir !== 'up' && @lastDir !== 'down') {
			if(@tick[0] % @tickInterval[0] > 0) {
				@bufferedInput[0] = 'down';
				die();
			}
			@snake['dir'] = 'down';
			@turned = true;
		} else if(@input['left'] && @lastDir !== 'left' && @lastDir !== 'right') {
			if(@tick[0] % @tickInterval[0] > 0) {
				@bufferedInput[0] = 'left';
				die();
			}
			@snake['dir'] = 'left';
			@turned = true;
		} else if(@input['right'] && @lastDir !== 'left' && @lastDir !== 'right') {
			if(@tick[0] % @tickInterval[0] > 0) {
				@bufferedInput[0] = 'right';
				die();
			}
			@snake['dir'] = 'right';
			@turned = true;
		} else if(@tick[0] % @tickInterval[0] > 0) {
			die();
		} else if(@bufferedInput[0]) {
			@snake['dir'] = @bufferedInput[0];
			@turned = true;
		}
		@bufferedInput[0] = null;

		@lastPos = @pos[];

		switch(@snake['dir']) {
			case 'up':
				@pos[1] -= 1;
				if(@pos[1] < 0) {
					@snake['dead'] = true;
				}
			case 'down':
				@pos[1] += 1;
				if(@pos[1] >= @width) {
					@snake['dead'] = true;
				}
			case 'left':
				@pos[0] -= 1;
				if(@pos[0] < 0) {
					@snake['dead'] = true;
				}
			case 'right':
				@pos[0] += 1;
				if(@pos[0] >= @width) {
					@snake['dead'] = true;
				}
		}

		if(!@snake['dead']) {
			@x = @pos[0];
			@y = @pos[1];
			if(@grid[@x][@y]) {
				@snake['dead'] = true;
			} else if(@x == @applePos[0] && @y == @applePos[1]) {
				@snake['maxLength'] += 16;
				@snake['score']++;
				set_entity_spec(@score, array(text: if(@snake['score'] < 10, ' ').@snake['score']));
				@applePos[0] = rand(@width);
				@applePos[1] = rand(@width);
				@grid[@applePos[0]][@applePos[1]] = false;
				set_display_entity(@apple, array(
					transformation: array(
						translation: array(
							x: @applePos[0] * @scale,
							y: -(@applePos[1] * @scale),
							z: 0))));
				if(@snake['score'] == 5) {
					@tickInterval[0] = 2;
					array_push(@notes, 12, 14, 16);
				} else if(@snake['score'] == 10) {
					@tickInterval[0] = 1;
					array_push(@notes, 14, 16, 18, 20);
				} else {
					array_push(@notes, 12);
				}
			}
			@grid[@x][@y] = true;
		}

		if(@snake['dead']) {
			play_sound(ploc(), array(sound: 'BLOCK_NOTE_BLOCK_BIT', pitch: 0.5));
			@notes[] = 0;
			if(entity_type(@vehicle) === 'ITEM_DISPLAY') {
				entity_remove(@vehicle);
			}
			die();
		}

		// update snake render
		set_display_entity(@head, array(
			transformation: array(
				translation: array(
					x: @pos[0] * @scale,
					y: -(@pos[1] * @scale),
					z: 0))));
					
		if(!@snake['tail']) {
			@snake['tail'] = spawn_entity('TEXT_DISPLAY', 1, @origin, closure(@e) {
				set_display_entity(@e, array(
					brightness: 15,
					transformation: array(
						scale: array(
							x: @scale * 8,
							y: @scale * 4,
							z: 0),
						translation: array(
							x: @lastPos[0] * @scale,
							y: -(@lastPos[1] * @scale),
							z: -0.001))));
				set_entity_spec(@e, array(
					text: ' ',
					alignment: 'LEFT',
					bgcolor: array(r: 64, g: 128, b: 96, a: 255)));
			})[0];
			@tail[] = array(entity: @snake['tail'], positions: array(@lastPos), dir: @lastDir);
		} else {
			@tail[-1]['positions'][] = @lastPos;
			@transform = get_display_entity(@snake['tail'])['transformation'];
			if(@lastDir === 'up') {
				set_display_entity(@snake['tail'], array(
					transformation: array(
						scale: array(
							x: @scale * 8,
							y: @transform['scale']['y'] + @scale * 4,
							z: 0))));

			} else if(@lastDir === 'down') {
				set_display_entity(@snake['tail'], array(
					transformation: array(
						scale: array(
							x: @scale * 8,
							y: @transform['scale']['y'] + @scale * 4,
							z: 0),
						translation: array(
							x: @transform['translation']['x'],
							y: @transform['translation']['y'] - @scale,
							z: -0.001))));
			} else if(@lastDir === 'left') {
				set_display_entity(@snake['tail'], array(
					transformation: array(
						scale: array(
							x: @transform['scale']['x'] + @scale * 8,
							y: @scale * 4,
							z: 0),
						translation: array(
							x: @transform['translation']['x'] - @scale / 1.67,
							y: @transform['translation']['y'],
							z: -0.001))));

			} else if(@lastDir === 'right') {
				set_display_entity(@snake['tail'], array(
					transformation: array(
						scale: array(
							x: @transform['scale']['x'] + @scale * 8,
							y: @scale * 4,
							z: 0),
						translation: array(
							x: @transform['translation']['x'] + @scale / 2.5,
							y: @transform['translation']['y'],
							z: -0.001))));
			}
		}

		if(@snake['length'] + 1 > @snake['maxLength']) {
			@segment = @tail[0];
			@x = @segment['positions'][0][0];
			@y = @segment['positions'][0][1];
			@grid[@x][@y] = false;
			if(array_size(@segment['positions']) < 2) {
				entity_remove(@segment['entity']);
				array_remove(@tail, 0);
			} else {
				@segment = @tail[0];
				@transform = get_display_entity(@segment['entity'])['transformation'];
				array_remove(@segment['positions'], 0);
				if(@segment['dir'] === 'up') {
					set_display_entity(@segment['entity'], array(
						transformation: array(
							scale: array(
								x: @scale * 8,
								y: @transform['scale']['y'] - @scale * 4,
								z: 0),
							translation: array(
								x: @transform['translation']['x'],
								y: @transform['translation']['y'] + @scale,
								z: -0.001))));

				} else if(@segment['dir'] === 'down') {
					set_display_entity(@segment['entity'], array(
						transformation: array(
							scale: array(
								x: @scale * 8,
								y: @transform['scale']['y'] - @scale * 4,
								z: 0))));

				} else if(@segment['dir'] === 'left') {
					set_display_entity(@segment['entity'], array(
						transformation: array(
							scale: array(
								x: @transform['scale']['x'] - @scale * 8,
								y: @scale * 4,
								z: 0),
							translation: array(
								x: @transform['translation']['x'] - @scale / 2.5,
								y: @transform['translation']['y'],
								z: -0.001))));
				} else if(@segment['dir'] === 'right') {
					set_display_entity(@segment['entity'], array(
						transformation: array(
							scale: array(
								x: @transform['scale']['x'] - @scale * 8,
								y: @scale * 4,
								z: 0),
							translation: array(
								x: @transform['translation']['x'] + @scale / 1.67,
								y: @transform['translation']['y'],
								z: -0.001))));
				}
			}
		} else {
			@snake['length']++;
		}
		if(@turned) {
			@snake['tail'] = null;
		}
	});
}

bind('entity_damage', array(priority: 'MONITOR'), array(type: 'ITEM_FRAME'), @event) {
	if(is_cancelled()) {
		die();
	}
	@spec = entity_spec(@event['id']);
	if(@spec['visible']) {
		die();
	}
	@item = @spec['item'];
	if(!@item || @item['name'] !== 'FILLED_MAP') {
		die();
	}
	@meta = @item['meta'];
	if(!@meta || !@meta['lore'] || @meta['lore'][0] !== 'snake') {
		die();
	}

	// get origin location
	@origin = entity_loc(@event['id']);
	switch(get_hanging_direction(@event['id'])) {
		case 'UP':
		case 'DOWN':
			@origin['x'] -= 0.47;
			@origin['z'] -= 0.47;
		case 'NORTH':
			@origin['y'] += 0.46;
			@origin['x'] += 0.47;
		case 'EAST':
			@origin['y'] += 0.46;
			@origin['z'] += 0.47;
		case 'SOUTH':
			@origin['y'] += 0.46;
			@origin['x'] -= 0.47;
		case 'WEST':
			@origin['y'] += 0.46;
			@origin['z'] -= 0.47;
	}

	// clear previous entities
	foreach(@entity in entities_in_radius(@origin, 1, 'TEXT_DISPLAY')) {
		entity_remove(@entity);
	}
}