<!
	description: A mini game of snake to be displayed on filled map in an item frame using text display entities.;
	suppressWarnings: CodeUpgradeNotices;
>
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
	
	@player = player();

	// game constants
	@width = 32;
	@scale = 1 / (@width + 1.9);
	@color = array(r: 16, g: 137, b: 99, a: 255);
	@highlight = array(r: 24, g: 204, b: 147, a: 255);

	// define game state
	@pos = array(integer(@width / 2), @width - 2);
	@applePos = array(rand(@width), rand(@width));
	@snake = array(
		dir: 'up', // up, down, left, right
		length: 1,
		maxLength: 8,
		dead: false,
		currentTailSegment: null,
		score: 0,
	);
	@grid = array_resize(array(), @width);
	foreach(@i: @row in @grid) {
		@grid[@i] = array_resize(array(), @width, false);
	}

	// get origin position and rotation based on item frame location
	@origin = entity_loc(@event['id']);
	switch(get_hanging_direction(@event['id'])) {
		case 'UP':
		case 'DOWN':
			@origin['x'] -= 0.45;
			@origin['z'] -= 0.45;
			@origin['yaw'] = round(ploc()['yaw'] / 90) * 90;
		case 'NORTH':
			@origin['y'] += 0.445;
			@origin['x'] += 0.46;
			@origin['yaw'] = 180;
		case 'EAST':
			@origin['y'] += 0.445;
			@origin['z'] += 0.46;
			@origin['yaw'] = 270;
		case 'SOUTH':
			@origin['y'] += 0.445;
			@origin['x'] -= 0.46;
			@origin['yaw'] = 0;
		case 'WEST':
			@origin['y'] += 0.445;
			@origin['z'] -= 0.46;
			@origin['yaw'] = 90;
	}

	// clear previous text display entities
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
			bgcolor: @highlight));
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
					x: 0.86,
					y: -0.08,
					z: 0.02))));
		set_entity_spec(@e, array(
			text: ' 0',
			bgcolor: array(r: 0, g: 0, b: 0, a: 0)));
	})[0];

	// all tail segments are pushed to this array
	@tail = array();

	// notes are consumed one per tick, using the numerical representation of noteblock notes
	@notes = array(1, null, null, 3, null, null, 5, null, null, 3, null, null, 1, null, null, 3, null, null, 5, null, null, null, null, null, 1, null, null, null, null, null, 1);

	// buffer player input when tick interval is higher than 1. this improves responsiveness.
	@bufferedInput = array(null);

	// tick interval is the number of ticks before snake is processed. lower this to make snake go faster.
	@tickInterval = array(3);
	@tick = array(0);

	// start game loop
	set_interval(50, closure(){
		@tick[0]++;

		if(!ponline(@player)) {
			clear_task();
			die();
		}

		if(@notes) {
			// consume/play next note
			if(!is_null(@notes[0])) {
				play_sound(ploc(), array(sound: 'BLOCK_NOTE_BLOCK_BIT', pitch: 2 ** ((@notes[0] - 12) / 12)));
			}
			array_remove(@notes, 0);
		}

		@vehicle = pvehicle();
		if(!@vehicle || !entity_exists(@head)) {
			// if vehicle (seat) or snake head entity do not exist, the game should end.
			if(entity_exists(@seat)) {
				entity_remove(@seat);
				if(@seat !== @vehicle) {
					// new game started before end screen appeared, so skip end screen
					clear_task();
					die();
				}
			}
			@endScreen = spawn_entity('TEXT_DISPLAY', 1, entity_loc(@event['id']), closure(@e) {
				set_display_entity(@e, array(
					brightness: 15,
					transformation: array(
						scale: array(
							x: 0.4,
							y: 0.4,
							z: 0),
						translation: array(
							x: 0.0,
							y: -0.39,
							z: 0.0))));
				set_entity_spec(@e, array(
					text: color('BOLD').'GAME OVER\n\n\n\n',
					bgcolor: array(r: 0, g: 0, b: 0, a: 0)));
			})[0];
			@scores = get_value('pixel_snake');
			@newEntry = array(name: to_upper(player()[0..2]), uuid: puuid(), score: @snake['score']);
			if(!@scores) {
				@scores = array();
			}
			@newHighScore = false;
			@text = color('bold').'HIGH\nSCORES\n';
			@playersWithHighScores = associative_array();
			foreach(@index: @entry in @scores) {
				if(!@newHighScore
				&& (@snake['score'] > @entry['score']
				|| array_index_exists(@playersWithHighScores, @entry['uuid']) && @snake['score'] >= @entry['score'])) {
					// insert new high score if higher than existing score at this index
					// or if score is equal and the player entry here already has a higher score
					array_insert(@scores, @newEntry, @index);
					@text .= '\n'.@newEntry['name'].' '.if(@newEntry['score'] < 10, ' ').@newEntry['score'];
					@newHighScore = true;
					if(array_size(@scores) > 5) {
						array_remove(@scores, array_size(@scores) - 1);
					}
				}
				@playersWithHighScores[@entry['uuid']] = true;
				@text .= '\n'.@entry['name'].' '.if(@entry['score'] < 10, ' ').@entry['score'];
			}
			if(!@newHighScore && array_size(@scores) < 5) {
				@text .= '\n'.@newEntry['name'].' '.if(@newEntry['score'] < 10, ' ').@newEntry['score'];
				@scores[] = @newEntry;
				store_value('pixel_snake', @scores);
			} else if(@newHighScore) {
				store_value('pixel_snake', @scores);
			}
			set_timeout(3000, closure(){
				if(entity_exists(@endScreen)) {
					set_entity_spec(@endScreen, array(text: @text));
				}
			});

			clear_task();
			die();
		}

		// get player input
		@lastDir = @snake['dir'];
		@input = get_player_input();
		@turned = false;
		// check for exclusive inputs, buffer inputs for next tick if snake cannot move this tick
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

		// update position based on input
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

		// process movement
		if(!@snake['dead']) {
			@x = @pos[0];
			@y = @pos[1];
			if(@grid[@x][@y]) {
				// collided with tail
				@snake['dead'] = true;
			} else if(@x == @applePos[0] && @y == @applePos[1]) {
				// collided with apple
				@snake['maxLength'] += 24;
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
				// if score is above a certain amount, clear tail and increase snake speed
				if(@snake['score'] % 10 < 1) {
					@snake['currentTailSegment'] = null;
					foreach(@i: @segment in @tail) {
						entity_remove(@segment['entity']);
						foreach(@position in @segment['positions']) {
							@grid[@position[0]][@position[1]] = false;
						}
						array_remove(@tail, @i);
					}
					@snake['length'] = 1;
					@snake['maxLength'] = 8;
					array_push(@notes, 12, 14, 16);
					if(@snake['score'] == 10) {
						@tickInterval[0] = 2;
					} else if(@snake['score'] == 20) {
						@tickInterval[0] = 1;
					}
				} else {
					array_push(@notes, 12);
				}
			}
			@grid[@x][@y] = true;
		}

		if(@snake['dead']) {
			play_sound(ploc(), array(sound: 'BLOCK_NOTE_BLOCK_BIT', pitch: 0.5));
			@notes[] = 0;
			// removing player vehicle (seat) indicates to this task to clean up next tick
			if(entity_type(@vehicle) === 'ITEM_DISPLAY') {
				entity_remove(@vehicle);
			}
			die();
		}

		// translate snake head entity to match new position
		set_display_entity(@head, array(
			transformation: array(
				translation: array(
					x: @pos[0] * @scale,
					y: -(@pos[1] * @scale),
					z: 0))));

		if(!@snake['currentTailSegment']) {
			// may have turned last tick, so create a new tail segment behind head
			@snake['currentTailSegment'] = spawn_entity('TEXT_DISPLAY', 1, @origin, closure(@e) {
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
					bgcolor: @color));
			})[0];
			@tail[] = array(entity: @snake['currentTailSegment'], positions: array(@lastPos), dir: @lastDir);
		} else {
			// scale and translate current tail segmented attached to head to make it longer
			@tail[-1]['positions'][] = @lastPos;
			@transform = get_display_entity(@snake['currentTailSegment'])['transformation'];
			if(@lastDir === 'up') {
				set_display_entity(@snake['currentTailSegment'], array(
					transformation: array(
						scale: array(
							x: @scale * 8,
							y: @transform['scale']['y'] + @scale * 4,
							z: 0))));

			} else if(@lastDir === 'down') {
				set_display_entity(@snake['currentTailSegment'], array(
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
				set_display_entity(@snake['currentTailSegment'], array(
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
				set_display_entity(@snake['currentTailSegment'], array(
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

		if(@snake['length'] < @snake['maxLength']) {
			@snake['length']++;
		} else {
			// remove length from the tail to make it shorter
			@segment = @tail[0];
			@x = @segment['positions'][0][0];
			@y = @segment['positions'][0][1];
			@grid[@x][@y] = false;
			if(array_size(@segment['positions']) < 2) {
				// if the segment is only one unit of length, remove it
				entity_remove(@segment['entity']);
				array_remove(@tail, 0);
			} else {
				// scale and translate text display for the oldest tail segment
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
		}
		if(@turned) {
			// create new tail segment next tick
			@snake['currentTailSegment'] = null;
		}
	});
}

/*
	Whenever an item frame containing a snake filled map is broken,
	the text display entities should be removed.
 */
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

	// clear text display entities next to item frame entity
	foreach(@entity in entities_in_radius(entity_loc(@event['id']), 1, 'TEXT_DISPLAY')) {
		entity_remove(@entity);
	}
}