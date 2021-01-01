proc _generate(@dungeonType, @region, @world, @seed, @callback) {
	// verify location is valid
	if(_is_survival_world(@world)) {
		die('Cannot generate a dungeon in a survival world!');
	} else if(!sk_region_exists(@world, @region)) {
		die('Region doesn\'t exist.');
	}

	@split = split(':', @dungeonType, 1);
	@dungeonType = @split[0];
	@testFloor = if(array_size(@split) == 1, -1, integer(@split[1]));

	// load dungeon type specific procedures
	include('dungeon.library/util.ms');
	include('dungeon.library/default.ms');
	try {
		include('dungeon.library/'.@dungeonType.'.ms');
	} catch(IOException @ex) {
		// doesn't exist, but that's okay
	}

	// load dungeon type configuration
	@options = yml_decode(read('/dungeon.library/'.@dungeonType.'.yml'));
	@defaults = array_merge(array(
		// size and scale
		'scale': 2,
		'minRoomSize': 3,
		'maxRoomSize': 11,
		'minRoomHeight': 3,
		'maxRoomHeight': 3,

		// variability on floor features
		'spawnChance': 0.001,

		// variability on room features
		'chestCount': 0,
		'spawnerChance': 0.7,
		'extraDoors': 0.0,
		'campfireChance': 0.0,

		// toggleable features on floors
		'roof': true,
		'bed': false,
		'entranceDoor': false,
		'lavaPit': false,
		'waterPit': false,
		'pit': false,
		'fireFloor': false,
		'staggeredWall': false,
		'attic': false,
		'balcony': false,
		'treasureRoom': false,

		// default materials
		'divider': 'bedrock',
		'empty': 'bedrock',
		'room': 'air',
		'door': 'air',
		'window': '', // optional

		// special spawns
		'boss': '',
	), @options['default']);

	// process floors config to standard format
	@dungeonEntrance = array_get(@options, 'dungeonEntrance', false);
	@cloneOffset = array_get(@options, 'cloneOffset', 0);
	@cloneDir = array_get(@options, 'cloneDir', '');
	foreach(@type in array('floors', 'cloneFloors')) {
		if(@type == 'cloneFloors' && !array_index_exists(@options, 'cloneFloors')) {
			continue();
		}
		foreach(@floor: @floorData in @options[@type]) {
			@floorData = array_merge(@defaults, @floorData);

			// ensure certain values are arrays
			if(array_index_exists(@floorData, 'utility')) {
				if(is_string(@floorData['utility'])) {
					@floorData['utility'] = array(@floorData['utility']);
				}
			} else {
				@floorData['utility'] = array('air');
			}
			if(array_index_exists(@floorData, 'decor')) {
				if(is_string(@floorData['decor'])) {
					@floorData['decor'] = array(@floorData['decor']);
				}
			} else {
				@floorData['decor'] = array('air');
			}
			if(array_index_exists(@floorData, 'wall')) {
				if(is_string(@floorData['wall'])) {
					@floorData['wall'] = array(@floorData['wall']);
				}
			} else {
				@floorData['wall'] = array('air');
			}
			if(array_index_exists(@floorData, 'floor')) {
				if(is_string(@floorData['floor'])) {
					@floorData['floor'] = array(@floorData['floor']);
				}
			} else {
				@floorData['floor'] = array('air');
			}
			if(array_index_exists(@floorData, 'trap')) {
				if(is_string(@floorData['trap'])) {
					@floorData['trap'] = array(@floorData['trap']);
				}
			} else {
				@floorData['trap'] = null;
			}

			@options[@type][@floor] = @floorData;
		}
	}

	// define constants
	@seed = @seed ||| integer(time() / 100000);
	@coords = sk_region_info(@region, @world, 0);
	@regionMinX = ceil(@coords[1][0] / @defaults['scale']) * @defaults['scale']; // align to default scale
	@regionMaxX = @coords[0][0];
	@regionMinY = @coords[1][1];
	@regionMinZ = ceil(@coords[1][2] / @defaults['scale']) * @defaults['scale']; // align to default scale
	@regionMaxZ = @coords[0][2];
	@regionWidth = @coords[0][0] - @coords[1][0];
	@regionLength = @coords[0][2] - @coords[1][2];
	@chunkMinX = floor(@regionMinX / 16);
	@chunkMaxX = floor(@regionMaxX / 16);
	@chunkMinZ = floor(@regionMinZ / 16);
	@chunkMaxZ = floor(@regionMaxZ / 16);
	@chunkWidth = @chunkMaxX - @chunkMinX + 1;
	@chunkLength = @chunkMaxZ - @chunkMinZ + 1;
	@chunkOffsetX = @regionMinX % 16;
	@chunkOffsetZ = @regionMinZ % 16;
	@chunkOffsetX = abs(@chunkOffsetX + if(@chunkOffsetX && @regionMinX < 0, 16, 0));
	@chunkOffsetZ = abs(@chunkOffsetZ + if(@chunkOffsetZ && @regionMinZ < 0, 16, 0));
	@maxChunks = array_size(@options['floors']) * @chunkWidth * @chunkLength;

	// prepare to thread
	@chunkCount = array(0);
	create_bar('gen'.@region, array('title': 'Generating '.@dungeonType.if(array_size(@options['floors']) > 1, ' floor 1'), 'percent': 0.0));
	foreach(@p in all_players(@world)) {
		bar_add_player('gen'.@region, @p);
	}
	_remove_region_entities(@region, array(), @world);

	// Dungeon planning (off the server thread)
	x_new_thread('DungeonPlanner', closure(){
		@random = res_create_resource('RANDOM', @seed);
		@rooms = null;
		@farthestRoom = null;
		@exitRoom = null;
		@spawns = array();

		// Place entrance room
		@scale = @options['floors'][0]['scale'];
		@width = ceil(@regionWidth / @scale);
		@length = ceil(@regionLength / @scale);
		if(@width % 2 == 0) {
			@width -= 1;
		}
		if(@length % 2 == 0) {
			@length -= 1;
		}
		@c = if(@dungeonEntrance) {
			integer((@width / 2 - 3) / 2) * 2 + 1;
		} else {
			integer(srand(@random) * (@width / 2 - 3)) * 2 + 3;
		}
		@r = if(@dungeonEntrance) {
			@length - 4;
		} else {
			integer(srand(@random) * (@length / 2 - 3)) * 2 + 3;
		}
		@entranceRoom = array(
			'r1': @r,
			'c1': @c,
			'width': 5,
			'length': 3,
			'connected': 0,
			'doors': 0,
			'height': 4,
			'type': 'NORMAL',
		);

		// Need these outside the foreach scope
		@floor = null;
		@maxRoomHeight = null;
		@layoutMap = null;

		foreach(@floor in range(if(@testFloor > -1, @testFloor, 0), if(@testFloor > -1, @testFloor + 1, array_size(@options['floors'])))) {
			queue_push(iclosure(
				@bar = 'gen'.@region,
				@title = 'Planning '.@dungeonType.' floor '.(@floor + 1)
			){
				update_bar(@bar, @title);
			}, 'generator');

			@floorData = @options['floors'][@floor];
			@scale = @floorData['scale'];
			@minRoomSize = @floorData['minRoomSize'];
			@maxRoomSize = @floorData['maxRoomSize'];
			@maxRoomHeight = @floorData['maxRoomHeight'];
			@minRoomHeight = @floorData['minRoomHeight'];
			@roof = @floorData['roof'];
			@chestCount = @floorData['chestCount'];
			@spawnChance = @floorData['spawnChance'];
			@extraDoors = @floorData['extraDoors'];
			@mobTypes = @floorData['spawner'];

			@width = ceil(@regionWidth / @scale);
			@length = ceil(@regionLength / @scale);
			if(@width % 2 == 0) {
				@width -= 1;
			}
			if(@length % 2 == 0) {
				@length -= 1;
			}

			@spawns[@floor] = array();
			// Define grid
			@layoutMap = array();
			@roomMap = array();
			@heightMap = array();
			for(@c = 0, @c < @width, @c++) {
				@layoutMap[@c] = array();
				@roomMap[@c] = array();
				@heightMap[@c] = array();
				for(@r = 0, @r < @length, @r++) {
					@type = 'empty';
					if(@r == 0 || @r == @length - 1
					|| @c == 0 || @c == @width - 1) {
						@type = 'wall';
					}
					@layoutMap[@c][@r] = @type;
					@roomMap[@c][@r] = -1;
					@heightMap[@c][@r] = @maxRoomHeight;
				}
			}

			// Define rooms
			@rooms = array();
			@r = 0;
			@c = 0;
			if(@floor == 0) {
				if(@dungeonEntrance) {
					@layoutMap[integer(@width / 2)][@length - 1] = 'door';
				}
				@r = @entranceRoom['r1'];
				@c = @entranceRoom['c1'];
				@rooms[] = @entranceRoom;
			} else if(@exitRoom != null) {
				@r = @exitRoom['r1'];
				@c = @exitRoom['c1'];
				@rooms[] = array(
					'r1': @r,
					'c1': @c,
					'width': min(@exitRoom['width'], 3),
					'length': min(@exitRoom['length'], 3),
					'connected': 0,
					'doors': 0,
					'height': 4,
					'type': 'NORMAL',
				);
			}
			if(@rooms) {
				for(@r2 = @r, @r2 < @rooms[0]['length'] + @r, @r2++) {
					for(@c2 = @c, @c2 < @rooms[0]['width'] + @c, @c2++) {
						@layoutMap[@c2][@r2] = 'room';
						@roomMap[@c2][@r2] = 0;
					}
				}
			}

			// Place rooms
			@unconnected = array(0);
			for(@r = 1, @r < @length, @r += 2) {
				for(@c = 1, @c < @width, @c += 2) {
					if(@roomMap[@c][@r] == -1) {
						@roomWidth = integer(srand(@random) * ((@maxRoomSize - @minRoomSize) / 2 + 1)) * 2 + @minRoomSize;
						@roomLength = integer(srand(@random) * ((@maxRoomSize - @minRoomSize) / 2 + 1)) * 2 + @minRoomSize;

						// Check placement and shrink if necessary to avoid room collisions.
						for(@r2 = @r, @r2 < @r + @roomLength, @r2 += 2) {
							@c2 = @c;
							if(@r2 >= @length || @roomMap[@c2][@r2] != -1) {
								@roomLength = @r2 - @r - 1;
								break();
							}
							for(@c2 = @c, @c2 < @c + @roomWidth, @c2 += 2) {
								if(@c2 >= @width || @roomMap[@c2][@r2] != -1) {
									@roomWidth = @c2 - @c - 1;
									break();
								}
							}
						}

						// Now that we have the width and length, the height can be determined to match.
						// This allows for good looking hallways at minRoomHeight.
						@height = @minRoomHeight;
						if(@roomWidth != 1 && @roomLength != 1) {
							@height = @minRoomHeight + integer(srand(@random) * (@maxRoomHeight - @minRoomHeight + 1));
						}

						// Room types determine generation shape
						@type = 'NORMAL';
						if(@floorData['attic'] && @height >= 7 && srand(@random) > 0.70) {
							@type = 'ATTIC';
						} else if(@floorData['balcony'] && @roomWidth > 2 && @roomLength > 2 && @height >= 7 && srand(@random) > 0.70) {
							@type = 'BALCONY';
						} else if(@floorData['lavaPit'] && @roomWidth > 1 && @roomLength > 1 && srand(@random) > 0.94) {
							@type = 'LAVA_PIT';
						} else if(@floorData['waterPit'] && @roomWidth > 1 && @roomLength > 1 && srand(@random) > 0.94) {
							@type = 'WATER_PIT';
						} else if(@floorData['fireFloor'] && @roomWidth > 1 && @roomLength > 1 && srand(@random) > 0.94) {
							@type = 'FIRE_FLOOR';
						} else if(@floorData['pit'] && @floor > 0 && srand(@random) > 0.94) {
							@type = 'PIT';
						}

						// Save room
						@unconnected[] = array_size(@rooms);
						@rooms[] = array(
							'r1': @r,
							'c1': @c,
							'width': @roomWidth,
							'length': @roomLength,
							'connected': 0,
							'doors': 0,
							'height': @height,
							'midheight': 3 + integer(srand(@random) * (@height - 7)),
							'type': @type
						);

						// Mask room
						for(@r2 = @r, @r2 < @roomLength + @r, @r2++) {
							for(@c2 = @c, @c2 < @roomWidth + @c, @c2++) {
								@roomMap[@c2][@r2] = array_size(@rooms) - 1;
							}
						}

						// Move the column var to the end of the room, before incrementation.
						@c = @c + @roomWidth - 1;
					}
				}
			}

			// Connect rooms
			@next = 0;
			@previous = @next;
			@try = array();
			@limit = 3000;
			@connected = associative_array();
			@maxRoomDistance = 0;
			@farthestRoom = null;
			@possibleDeadEnds = associative_array();
			while(@unconnected) {
				@limit--;
				if(@limit < 0){
					die('Hit room connector limits! Rooms left: '.array_size(@unconnected).'/'.array_size(@rooms).'!');
				}

				array_remove_values(@unconnected, @next);
				@connected[@next] = null;
				if(@rooms[@next]['connected'] == 0){
					@rooms[@next]['connected'] = @rooms[@previous]['connected'] + 1;
					if(@rooms[@next]['connected'] > @maxRoomDistance) {
						@maxRoomDistance = @rooms[@next]['connected'];
						@farthestRoom = @next;
					}
				}

				@r = @rooms[@next]['r1'];
				@c = @rooms[@next]['c1'];
				@roomWidth = @rooms[@next]['width'];
				@roomLength = @rooms[@next]['length'];

				@success = false;
				@dirs = array(0, 1, 2, 3);
				foreach(@d in range(4)) {
					@dir = integer(srand(@random) * array_size(@dirs));
					array_remove_values(@dirs, @dir);
					try {
						@c2 = 0;
						@r2 = 0;
						@c3 = 0;
						@r3 = 0;
						switch(@dir){
							case 0:
								@r2 = @r - 2;
								@c2 = @c + integer(srand(@random) * ((@roomWidth + 1) / 2)) * 2;
								@r3 = @r2 + 1;
								@c3 = @c2;
							case 1:
								@r2 = @r + @roomLength + 1;
								@c2 = @c + integer(srand(@random) * ((@roomWidth + 1) / 2)) * 2;
								@r3 = @r2 - 1;
								@c3 = @c2;
							case 2:
								@c2 = @c - 2;
								@r2 = @r + integer(srand(@random) * ((@roomLength + 1) / 2)) * 2;
								@c3 = @c2 + 1;
								@r3 = @r2;
							case 3:
								@c2 = @c + @roomWidth + 1;
								@r2 = @r + integer(srand(@random) * ((@roomLength + 1) / 2)) * 2;
								@c3 = @c2 - 1;
								@r3 = @r2;
						}
						@room = @roomMap[@c2][@r2];
						if(@room != -1
						&& @room != @previous
						&& (!@rooms[@room]['connected'] || srand(@random) < @extraDoors)) {
							@layoutMap[@c3][@r3] = 'door';
							@rooms[@room]['doors']++;
							@rooms[@next]['doors']++;
							@previous = @next;
							@next = @room;
							@success = true;
							@try = array();
							break();
						}
					} catch(Exception @ex){
						// no room here
					}
				}
				if(!@success) {
					@possibleDeadEnds[@next] = array_get(@possibleDeadEnds, @next, 0) + 1;
					if(@previous == @next) {
						@limit2 = array_size(@rooms) * 2;
						do {
							@next = array_keys(@connected)[integer(srand(@random) * array_size(@connected))];
							@limit2--;
						} while(@limit2 > 0 && (@next == @previous || array_contains(@try, @next)));
						@try[] = @next;
					} else {
						// go back one if we haven't already
						@next = @previous;
					}
				}
			}

			// Mark special rooms
			if(@floorData['treasureRoom']) {
				@treasureRoom = -1;
				@connectionFailures = -1;
				foreach(@n: @v in @possibleDeadEnds){
					@room = @rooms[@n];
					if(@n != @farthestRoom && @room['doors'] == 1 && @v > @connectionFailures
					&& @room['width'] > 1 && @room['length'] > 1) {
						@treasureRoom = @n;
						@connectionFailures = @v;
					}
				}
				if(@treasureRoom > 0) {
					@rooms[@treasureRoom]['type'] = 'TREASURE';
				}
			}

			// Plan room layout
			foreach(@n: @room in @rooms){
				if(@n == 0){
					continue();
				}
				@r = @room['r1'];
				@c = @room['c1'];
				@roomWidth = @room['width'];
				@roomLength = @room['length'];
				@rowOdd = null;
				@columnOdd = null;
				for(@r2 = @r - 1, @r2 <= @roomLength + @r, @r2++) {
					for(@c2 = @c - 1, @c2 <= @roomWidth + @c, @c2++) {
						if(@r2 >= @r && @r2 < @roomLength + @r
						&& @c2 >= @c && @c2 < @roomWidth + @c) {
							@heightMap[@c2][@r2] = @room['height'];
							if(@roomLength == 1
							|| @roomWidth == 1
							|| _adjacent_equals(@layoutMap, @c2, @r2, 'door')
							|| (!is_null(@rowOdd) && (@rowOdd != @r2 % 2 || @columnOdd != @c2 % 2))
							|| integer(srand(@random) * 100) < 90) {
								@layoutMap[@c2][@r2] = 'room';
								if(srand(@random) < @spawnChance) {
									@spawns[@floor][] = array(
										'x': @regionMinX + @c2 * @scale + 0.5,
										'y': @regionMinY + @floor * (@maxRoomHeight + 3) + 1,
										'z': @regionMinZ + @r2 * @scale + 0.5,
										'world': @world,
									);
								}
							} else {
								@layoutMap[@c2][@r2] = 'column';
								if(is_null(@rowOdd)) {
									@rowOdd = @r2 % 2;
									@columnOdd = @c2 % 2;
								}
							}
						} else if(@layoutMap[@c2][@r2] !== 'door') {
							if(@floorData['window'] && srand(@random) > 0.9 &&
							!(@c2 == 0 || @r2 == 0 || @c2 == @width - 1 || @r2 == @length - 1
							|| _adjacent_equals(@layoutMap, @c2, @r2, 'door'))) {
								@layoutMap[@c2][@r2] = 'window';
							} else {
								@layoutMap[@c2][@r2] = 'wall';
							}
						}
					}
				}
			}

			// Build dungeon floor
			@allmaterials = array(@floorData);
			if(@cloneOffset) {
				if(array_index_exists(@options, 'cloneFloors')) {
					@allmaterials[] = @options['cloneFloors'][@floor];
				} else {
					@allmaterials[] = @floorData;
				}
			}

			for(@chunkZ = 0, @chunkZ < @chunkLength, @chunkZ++) {
				for(@chunkX = 0, @chunkX < @chunkWidth, @chunkX++) {
					@chunk = array();
					for(@z = 0, @z < 16, @z++) {
						for(@x = 0, @x < 16, @x++) {
							foreach(@clone: @materials in @allmaterials) {
								@r = floor((@chunkZ * 16 + @z - @chunkOffsetZ) / @scale);
								@c = floor((@chunkX * 16 + @x - @chunkOffsetX) / @scale);
								if(@r < 0 || @c < 0 || @r >= @length || @c >= @width) {
									continue();
								}

								@groundY = @regionMinY + @floor * (@maxRoomHeight + 4) + if(@cloneDir == 'up', @clone * @cloneOffset, 0);
								@roomHeight = @heightMap[@c][@r];
								@room = if(@roomMap[@c][@r] != -1, @rooms[@roomMap[@c][@r]], null);
								@loc = array(
									(@chunkMinX + @chunkX) * 16 + @x + if(@cloneDir == 'east', @clone * @cloneOffset, 0),
									@groundY,
									(@chunkMinZ + @chunkZ) * 16 + @z + if(@cloneDir == 'south', @clone * @cloneOffset, 0),
									@world
								);

								@northEdge = if(@scale == 1, true, (@loc[2] - @regionMinZ) % @scale == 0);
								@southEdge = if(@scale == 1, true, (@loc[2] - @regionMinZ) % @scale == @scale - 1);
								@eastEdge = if(@scale == 1, true, (@loc[0] - @regionMinX) % @scale == @scale - 1);
								@westEdge = if(@scale == 1, true, (@loc[0] - @regionMinX) % @scale == 0);

								// Bedrock divider
								_add_to_chunk(@chunk, @loc, @materials['divider']);

								// Floor
								@loc[1] += 1;
								@roomType = if(@room, @room['type'], null);
								if(@roomType == 'FIRE_FLOOR') {
									_add_to_chunk(@chunk, @loc, 'dispenser[facing=up]');
								} else if(@roomType == 'LAVA_PIT') {
									if(!_direction_of_solid(@layoutMap, @c, @r) || srand(@random) < 0.6) {
										_add_to_chunk(@chunk, @loc, 'lava');
									} else {
										_add_to_chunk(@chunk, @loc, @materials['floor']);
									}
								} else if(@roomType == 'WATER_PIT') {
									if(!_direction_of_solid(@layoutMap, @c, @r) || srand(@random) < 0.7) {
										_add_to_chunk(@chunk, @loc, 'water');
									} else {
										_add_to_chunk(@chunk, @loc, @materials['floor']);
									}
								} else if(@roomType == 'PIT') {
									if(!_direction_of_solid(@layoutMap, @c, @r) || srand(@random) > 0.4) {
										@holeDepth = @maxRoomHeight;
										while(@holeDepth-- > 0) {
											_add_to_chunk(@chunk, location_shift(@loc, 'down', @holeDepth), 'air');
										}
									} else {
										_add_to_chunk(@chunk, @loc, @materials['floor']);
									}
								} else {
									_add_to_chunk(@chunk, @loc, @materials['floor']);
								}

								// Walls
								@ceilingY = @groundY + @roomHeight + 2;
								@y = 0;
								for(@y = @groundY + 2, @y < @ceilingY, @y++) {
									@loc[1] = @y;
									switch(@layoutMap[@c][@r]) {
										case 'window':
											if(@y < @ceilingY - @roomHeight + 3 && @y > @ceilingY - @roomHeight) {
												_add_to_chunk(@chunk, @loc, @materials['window']);
											} else {
												_add_to_chunk(@chunk, @loc, @materials['wall']);
											}

										case 'wall':
											if(@materials['staggeredWall']) {
												if((@x + @z) % 2 == 0 || (@x + @z) % 3 == 0) {
													_add_to_chunk(@chunk, @loc, @materials['wall'][(@x + @z) % array_size(@materials['wall'])]);
												} else if(@y == @groundY + 1 + _get_nearest_height(@heightMap, @maxRoomHeight, @c, @r, @x, @z)) {
													_add_to_chunk(@chunk, @loc, @materials['edge']);
												} else {
													_add_to_chunk(@chunk, @loc, 'air');
												}
											} else {
												_add_to_chunk(@chunk, @loc, @materials['wall']);
											}

										case 'room':
											if(@roomType == 'FIRE_FLOOR' && @y == @groundY + 2 && (@x + @z) % 2 && srand(@random) > 0.2) {
												_add_to_chunk(@chunk, @loc, 'stone_pressure_plate');

											} else if(@roomType == 'ATTIC' && @y == @ceilingY - @roomHeight + @room['midheight']) {
												_add_to_chunk(@chunk, @loc, @materials['floor']);

											} else if(@roomType == 'BALCONY' && @y == @ceilingY - @roomHeight + @room['midheight']
													&& _direction_of_border(@layoutMap, @c, @r)) {
												_add_to_chunk(@chunk, @loc, @materials['floor'][0]);

											} else if(@materials['edge'] != 'air' && @roomHeight > 2 && @y == @ceilingY - 1) {
												@stairs = string_ends_with(@materials['edge'], 'stairs');
												@north = @layoutMap[@c][@r - 1];
												@south = @layoutMap[@c][@r + 1];
												@west = @layoutMap[@c - 1][@r];
												@east = @layoutMap[@c + 1][@r];
												@state = @materials['edge'].if(@stairs, '[half=top'.if(@materials['room'] == 'water', ',waterlogged=true'));
												if((@east == 'wall' || @east == 'door' || @east == 'window' && @roomHeight > 3) && @eastEdge) {
													if(@stairs) {
														@state .= ',facing=east'
														if(@roomHeight == 3 && @east == 'door') {
															if(@northEdge) {
																@state .= ',shape=outer_left';
															} else {
																@state .= ',shape=outer_right';
															}
														} else if((@north == 'wall' || @north == 'door' && @roomHeight > 3) && @northEdge) {
															@state .= ',shape=inner_left';
														} else if((@south == 'wall' || @south == 'door' && @roomHeight > 3) && @southEdge) {
															@state .= ',shape=inner_right';
														}
														@state .= ']';
													}
												} else if((@west == 'wall' || @west == 'door' || @west == 'window' && @roomHeight > 3) && @westEdge) {
													if(@stairs) {
														@state .= ',facing=west'
														if(@roomHeight == 3 && @west == 'door') {
															if(@southEdge) {
																@state .= ',shape=outer_left';
															} else {
																@state .= ',shape=outer_right';
															}
														} else if((@north == 'wall' || @north == 'door' && @roomHeight > 3) && @northEdge) {
															@state .= ',shape=inner_right';
														} else if((@south == 'wall' || @south == 'door' && @roomHeight > 3) && @southEdge) {
															@state .= ',shape=inner_left';
														}
														@state .= ']';
													}
												} else if((@south == 'wall' || @south == 'door' || @south == 'window' && @roomHeight > 3) && @southEdge) {
													if(@stairs) {
														@state .= ',facing=south';
														if(@roomHeight == 3 && @south == 'door') {
															if(@eastEdge) {
																@state .= ',shape=outer_left';
															} else {
																@state .= ',shape=outer_right';
															}
														}
														@state .= ']';
													}
												} else if((@north == 'wall' || @north == 'door' || @north == 'window' && @roomHeight > 3) && @northEdge) {
													if(@stairs) {
														@state .= ',facing=north'
														if(@roomHeight == 3 && @north == 'door') {
															if(@westEdge) {
																@state .= ',shape=outer_left';
															} else {
																@state .= ',shape=outer_right';
															}
														}
														@state .= ']';
													}
												} else {
													@state = @materials['room'];
												}
												_add_to_chunk(@chunk, @loc, @state);

											} else {
												_add_to_chunk(@chunk, @loc, @materials['room']);
											}

										case 'door':
											if(@y < @ceilingY - @roomHeight + 2) {
												if(@materials['entranceDoor']) {
													@north = @roomMap[@c][@r - 1];
													@south = array_get(@roomMap[@c], @r + 1, 0); // special case for dungeon entrance
													@west = @roomMap[@c - 1][@r];
													@east = @roomMap[@c + 1][@r];
													@lower = @y < @ceilingY - @roomHeight + 1;
													@count = array_size(@chunk);
													if(@north % 7 == 0) {
														if(@southEdge) {
															@half = if(@lower, 'half=lower,', 'half=upper,');
															@hinge = if(@eastEdge, 'hinge=left', 'hinge=right');
															_add_to_chunk(@chunk, @loc, 'spruce_door[facing=south,'.@half.@hinge.']');
														}
													} else if(@south % 7 == 0) {
														if(@northEdge) {
															@half = if(@lower, 'half=lower,', 'half=upper,');
															@hinge = if(@westEdge, 'hinge=left', 'hinge=right');
															_add_to_chunk(@chunk, @loc, 'spruce_door[facing=north,'.@half.@hinge.']');
														}
													} else if(@west % 7 == 0) {
														if(@eastEdge) {
															@half = if(@lower, 'half=lower,', 'half=upper,');
															@hinge = if(@northEdge, 'hinge=left', 'hinge=right');
															_add_to_chunk(@chunk, @loc, 'spruce_door[facing=east,'.@half.@hinge.']');
														}
													} else if(@east % 7 == 0) {
														if(@westEdge) {
															@half = if(@lower, 'half=lower,', 'half=upper,');
															@hinge = if(@southEdge, 'hinge=left', 'hinge=right');
															_add_to_chunk(@chunk, @loc, 'spruce_door[facing=west,'.@half.@hinge.']');
														}
													}
													if(@count == array_size(@chunk)) {
														_add_to_chunk(@chunk, @loc, @materials['door']);
													}
												} else {
													_add_to_chunk(@chunk, @loc, @materials['door']);
												}
											} else if(@y < @ceilingY - @roomHeight + 3) {
												@stairs = string_ends_with(@materials['edge'], 'stairs');
												@north = @layoutMap[@c][@r - 1];
												@south = array_get(@layoutMap[@c], @r + 1, 'room'); // special case for dungeon entrance
												@west = @layoutMap[@c - 1][@r];
												@east = @layoutMap[@c + 1][@r];
												@state = @materials['edge'].if(@stairs, '[half=top'.if(@materials['room'] == 'water', ',waterlogged=true'));
												if(@east == 'wall' && @eastEdge) {
													if(@stairs) {
														@state .= ',facing=east]';
													}
												} else if(@west == 'wall' && @westEdge) {
													if(@stairs) {
														@state .= ',facing=west]';
													}
												} else if(@south == 'wall' && @southEdge) {
													if(@stairs) {
														@state .= ',facing=south]';
													}
												} else if(@north == 'wall' && @northEdge) {
													if(@stairs) {
														@state .= ',facing=north]';
													}
												} else {
													@state = @materials['wall'];
												}
												_add_to_chunk(@chunk, @loc, @state);
											} else if(@materials['staggeredWall']) {
												_add_to_chunk(@chunk, @loc, @materials['wall'][0]);
											} else {
												_add_to_chunk(@chunk, @loc, @materials['wall']);
											}

										case 'column':
											_add_to_chunk(@chunk, @loc, @materials['column']);

										default:
											_add_to_chunk(@chunk, @loc, @materials['empty']);
									}
								}

								if(@roof) {
									// Ceiling
									@loc[1] += 1;
									if(@layoutMap[@c][@r] === 'room') {
										_add_to_chunk(@chunk, @loc, @materials['ceiling']);
									} else {
										_add_to_chunk(@chunk, @loc, 'bedrock');
									}

									// Bedrock floor divider
									while(@loc[1] < @y + @maxRoomHeight - @roomHeight + 1) {
										@loc[1] += 1;
										if(@layoutMap[@c][@r] === 'room') {
											_add_to_chunk(@chunk, @loc, @materials['empty']);
										} else {
											_add_to_chunk(@chunk, @loc, 'bedrock');
										}
									}
								}
							}
						}
					}
					if(@chunk) {
						queue_push(iclosure(
							@bar = 'gen'.@region,
							@title = 'Placing '.@dungeonType.' floor '.(@floor + 1),
							@percent = double(++@chunkCount[0] / @maxChunks)
						){
							update_bar(@bar, array('title': @title, 'percent': @percent));
						}, 'generator');
						queue_push(iclosure(
							@thisChunk = @chunk,
							@thisWorld = @world
						){
							// removing chests drops items, so we need to make sure those don't drop
							@bind = bind('item_spawn', null, null, @event, @thisWorld) {
								if(@event['location']['world'] == @thisWorld) {
									cancel();
								}
							}
							try {
								for(@i = 0, @i < array_size(@thisChunk), @i += 2) {
									set_blockdata_string(@thisChunk[@i], @thisChunk[@i + 1], false);
								}
							} finally {
								unbind(@bind);
							}
						}, 'generator');
					}
				}
			}
			@chunk = null;

			queue_push(iclosure(
				@bar = 'gen'.@region,
				@title = 'Decorating '.@dungeonType.' floor '.(@floor + 1)
			){
				update_bar(@bar, @title);
			}, 'generator');

			// Populate rooms
			@materials = @allmaterials[0];
			foreach(@i: @room in @rooms) {
				queue_push(closure(){
					if(@room['length'] == 1 || @room['width'] == 1 || string_ends_with(@room['type'], 'PIT')) {
						die();
					}

					@yFloor = @regionMinY + (@floor * (@maxRoomHeight + 4)) + 2;
					@roomHeight = @room['height'];

					@spawner = false;
					if(@room['type'] == 'FIRE_FLOOR') {
						@y = @yFloor - 1;
						for(@x = @regionMinX + @room['c1'] * @scale, @x < @regionMinX + @room['c1'] * @scale + @room['width'] * @scale, @x++) {
							for(@z = @regionMinZ + @room['r1'] * @scale, @z < @regionMinZ + @room['r1'] * @scale + @room['length'] * @scale, @z++) {
								try(set_inventory(array(@x, @y, @z, @world), array(0: array(
									'name': 'FLINT_AND_STEEL'
								))));
							}
						}
					} else {
						// spawner
						if(@room['connected'] > 1 && @mobTypes && srand(@random) < @floorData['spawnerChance']) {
							@loc = array(
								@regionMinX + @room['c1'] * @scale + 1 + integer(srand(@random) * (@room['width'] - 1)) * @scale,
								@yFloor + if(@room['type'] == 'ATTIC' && srand(@random) > 0.67, @room['midheight'] + 1, 0),
								@regionMinZ + @room['r1'] * @scale + 1 + integer(srand(@random) * (@room['length'] - 1)) * @scale,
								@world
							);
							if(equals_ic(@materials['room'], get_block(@loc))) {
								@spawner = true;
								set_block(@loc, 'SPAWNER', false);
								@rand = integer(srand(@random) * array_size(@mobTypes));
								@mob = array_get(@mobTypes, @rand, 'ZOMBIE');
								set_spawner_type(@loc, @mob);
							}
						} else if(@room['width'] > 2 && @room['length'] > 2
								&& @floorData['campfireChance'] && srand(@random) < @floorData['campfireChance']) {
							@loc = array(
								@regionMinX + @room['c1'] * @scale + 2 + integer(srand(@random) * (@room['width'] - 2)) * @scale,
								@yFloor + if(@room['type'] == 'ATTIC' && srand(@random) > 0.67, @room['midheight'] + 1, 0),
								@regionMinZ + @room['r1'] * @scale + 2 + integer(srand(@random) * (@room['length'] - 2)) * @scale,
								@world
							);
							if(equals_ic(@materials['room'], get_block(@loc))) {
								set_block(@loc, 'CAMPFIRE', false);
							}
						}
					}

					if(@chestCount > 0) {
						@chests = @chestCount;
						if(@room['type'] == 'TREASURE') {
							@chests = 1;
						} else if(is_double(@chests)) {
							@chests = integer(srand(@random) * min(@room['length'], @room['width']) / @chests);
						}
						@bonus = if(@room['type'] == 'TREASURE', 3, 1);
						@chestHeight = if(@room['type'] == 'ATTIC' && srand(@random) > 0.33){
							@room['midheight'] + 1
						} else if(@room['type'] == 'TREASURE') {
							1;
						} else {
							0;
						}
						@attempts = 10;
						while(@attempts-- > 0 && @chests > 0) {
							@loc = array(
								@regionMinX + @room['c1'] * @scale + 1 + integer(srand(@random) * (@room['width'] - 1)) * @scale,
								@yFloor + @chestHeight,
								@regionMinZ + @room['r1'] * @scale + 1 + integer(srand(@random) * (@room['length'] - 1)) * @scale,
								@world
							);
							if(equals_ic(@materials['room'], get_block(@loc))) {
								@chests--;
								set_blockdata_string(@loc, 'chest[facing='._get_direction(@random).if(@materials['room'] == 'water', ',waterlogged=true').']', false);
								try(set_inventory(@loc, _get_loot(@floor, @random, @bonus)));
								if(@room['type'] == 'TREASURE') {
									set_blockdata_string(location_shift(@loc, 'down'), 'diamond_block');
								}
							}
						}
					}

					if(@room['type'] == 'TREASURE') {
						die();
					}

					@utilities = integer(srand(@random) * 2);
					while(@utilities-- > 0) {
						@loc = array(
							@regionMinX + @room['c1'] * @scale + 1 + integer(srand(@random) * (@room['width'] - 1) * @scale),
							@yFloor + if(@room['type'] == 'ATTIC' && srand(@random) > 0.5, @room['midheight'] + 1, 0),
							@regionMinZ + @room['r1'] * @scale + 1 + integer(srand(@random) * (@room['length'] - 1) * @scale),
							@world
						);
						if(equals_ic(@materials['room'], get_block(@loc))) {
							set_block(@loc, @materials['utility'][integer(srand(@random) * array_size(@materials['utility']))], false);
						}
					}

					@decorations = integer(srand(@random) * max(@room['length'], @room['width']));
					while(@decorations-- > 0) {
						@loc = array(
							@regionMinX + @room['c1'] * @scale + 1 + integer(srand(@random) * (@room['width'] - 1) * @scale),
							@yFloor + if(@room['type'] == 'ATTIC' && srand(@random) > 0.5, @room['midheight'] + 1, 0),
							@regionMinZ + @room['r1'] * @scale + 1 + integer(srand(@random) * (@room['length'] - 1) * @scale),
							@world
						);
						if(equals_ic(@materials['room'], get_block(@loc))) {
							set_block(@loc, @materials['decor'][integer(srand(@random) * array_size(@materials['decor']))], false);
						}
					}

					if(@room['type'] == 'ATTIC') {
						do {
							@loc = null;
							@attempts = 5;
							do {
								@loc = array(
									@regionMinX + @room['c1'] * @scale + integer(srand(@random) * @room['width']) * @scale,
									@yFloor + @room['midheight'] + 1,
									@regionMinZ + @room['r1'] * @scale + integer(srand(@random) * @room['length']) * @scale,
									@world
								);
							} while(!equals_ic(@materials['room'], get_block(@loc)) && --@attempts > 0);
							@dirs = array_rand(array('east', 'west', 'north', 'south'), rand(1, 4), false);
							@block = array('block': 'vine');
							foreach(@dir in @dirs) {
								@block[@dir] = true;
							}
							@length = @room['midheight'];
							while(@length-- > 0) {
								@loc[1]--;
								set_blockdata(@loc, @block);
							}
						} while(srand(@random) > 0.45);
					}

					if(@i == @farthestRoom && @floorData['boss']) {
						@tries = 10;
						while(@tries-- > 0) {
							@loc = array(
								@regionMinX + @room['c1'] * @scale + integer(srand(@random) * @room['width']) * @scale + 0.5,
								@yFloor,
								@regionMinZ + @room['r1'] * @scale + integer(srand(@random) * @room['length']) * @scale + 0.5,
								@world
							);
							if(equals_ic(@materials['room'], get_block(@loc))) {
								_spawn_entity(@floorData['boss'], @loc, null, null, closure(@entity) {
									add_scoreboard_tag(@entity, 'floor'.@floor.'boss');
									set_mob_name(@entity, 'BOSS');
								});
								die();
							}
						}
					}

					if(@floorData['trap'] && @room['type'] != 'FIRE_FLOOR') {
						@traps = integer(srand(@random) * (@room['length'] + @room['width']));
						while(@traps-- > 0) {
							@type = split('_', @materials['trap'][integer(srand(@random) * array_size(@materials['trap']))]);
							@trigger = @type[0];
							@effect = @type[1];
							@data = if(array_size(@type) == 3, @type[2], null);
							@facing = 'up';
							@loc = null;
							if(@trigger == 'chest' || @effect == 'cactus') {
								@loc = array(
									@regionMinX + @room['c1'] * @scale + 1 + integer(srand(@random) * (@room['width'] - 1)) * @scale,
									@yFloor,
									@regionMinZ + @room['r1'] * @scale + 1 + integer(srand(@random) * (@room['length'] - 1)) * @scale,
									@world
								);
							} else {
								@loc = array(
									@regionMinX + @room['c1'] * @scale + integer(srand(@random) * @room['width']) * @scale,
									@yFloor,
									@regionMinZ + @room['r1'] * @scale + integer(srand(@random) * @room['length']) * @scale,
									@world
								);
							}
							if(!equals_ic(@materials['room'], get_block(@loc))) {
								continue();
							}
							switch(@trigger) {
								case 'plate':
									if(@spawner) {
										// ignore rooms that already have spawners
										continue();
									}
									// must set pressure plate after dispenser underneath it
									@loc = location_shift(@loc, 'down');
								case 'chest':
									set_block(@loc, 'TRAPPED_CHEST', false);
									@loc = location_shift(@loc, 'down');
									@traps = 0; // so we don't block the door
								case 'tripwire':
									if(@spawner) {
										// ignore rooms that already have spawners
										continue();
									}
									@positive = null;
									@negative = null;
									if(@room['width'] > 1 && @room['width'] < 6) {
										@positive = 'east';
										@negative = 'west';
									} else if(@room['length'] > 1 && @room['length'] < 6) {
										@positive = 'south';
										@negative = 'north';
									}
									if(!@positive) {
										continue();
									}
									@tripwire = array(@loc);
									@dist = 1;
									while(!array_contains_ic(@materials['wall'], get_block(location_shift(@loc, @negative, @dist))) && @dist < 12) {
										array_insert(@tripwire, location_shift(@loc, @negative, @dist), 0);
										@dist++;
									}
									if(@dist == 12) {
										continue();
									}
									@dist = 1;
									while(!array_contains_ic(@materials['wall'], get_block(location_shift(@loc, @positive, @dist))) && @dist < 12) {
										@tripwire[] = location_shift(@loc, @positive, @dist);
										@dist++;
									}
									if(@dist == 12) {
										continue();
									}
									set_blockdata_string(@tripwire[0], 'tripwire_hook[facing='.@positive',attached=true]', false);
									foreach(@t in @tripwire[1..-2]) {
										set_blockdata_string(@t, 'tripwire['.@positive.'=true,'.@negative.'=true,attached=true]', false);
									}
									set_blockdata_string(@tripwire[-1], 'tripwire_hook[facing='.@negative.',attached=true]', false);
									if(srand(@random) > 0.5) {
										@facing = @negative;
										@loc = location_shift(location_shift(@tripwire[-1], @positive), 'up');
									} else {
										@facing = @positive;
										@loc = location_shift(location_shift(@tripwire[0], @negative), 'up');
									}
							}
							switch(@effect) {
								case 'fire':
									foreach(@dir in array('north', 'south', 'east', 'west')) {
										set_blockdata_string(location_shift(@loc, @dir), 'dispenser[facing=up]', false);
										set_inventory(location_shift(@loc, @dir), array(0: array(
											'name': 'FLINT_AND_STEEL', 'meta': array('damage': 61)
										)));
									}
								case 'cactus':
									set_block(location_shift(@loc, 'down'), 'SAND', false);
									set_block(@loc, 'CACTUS', false);
									set_block(location_shift(@loc, 'up'), 'CACTUS', false);
								case 'web':
									set_block(@loc, 'COBWEB', false);
									@dir = _get_direction(@random);
									@count = 0;
									while(@count++ < @maxRoomHeight) {
										@loc = location_shift(location_shift(@loc, 'up'), @dir);
										if(equals_ic(@materials['room'], get_block(@loc))) {
											set_block(@loc, 'COBWEB', false);
										} else {
											break();
										}
									}
								case 'tnt':
									set_blockdata_string(@loc, 'dispenser[facing='.@facing.']', false);
									set_inventory(@loc, array(0: array('name': 'TNT', 'qty': 2)));
								case 'potion':
									@solid = material_info(get_block(location_shift(@loc, @facing)), 'isSolid');
									if(@solid) {
										set_blockdata_string(@loc, 'dispenser[facing='.@facing.']', false);
									} else {
										set_blockdata_string(@loc, 'dispenser[facing=north]', false);
									}
									set_inventory(@loc, array(0: array(
										'name': if(@solid, 'LINGERING_POTION', 'SPLASH_POTION'),
										'qty': 3,
										'meta': array('base': array('extended': false, 'type': to_upper(@data), 'upgraded': true))
									)));
								case 'arrow':
									set_blockdata_string(@loc, 'dispenser[facing='.@facing.']', false);
									set_inventory(@loc, array(0: array('name': 'TIPPED_ARROW', 'qty': 3, 'meta': array('base': array('type': 'INSTANT_DAMAGE', 'upgraded': true, 'extended': false)))));
							}
							if(@trigger == 'plate') {
								// needs to be after dispenser
								set_block(location_shift(@loc, 'up'), 'STONE_PRESSURE_PLATE', false);
							}
						}
					}
				}, 'generator');
			}

			// exit room / Pop ladder into floor
			if(@exitRoom) {
				queue_push(closure(){

					@loc = array(
						@regionMinX + @exitRoom['c1'] * @scale,
						@regionMinY + @floor * (@maxRoomHeight + 4) + 2,
						@regionMinZ + @exitRoom['r1'] * @scale,
						@world,
					);
					set_blockdata_string(@loc, 'spruce_trapdoor[facing=south,half=bottom]', false);

					if(@floorData['bed']) {
						@bedLoc = location_shift(@loc, 'east');
						set_blockdata_string(@bedLoc, 'red_bed[facing=north,part=head]', false);
						set_blockdata_string(location_shift(@bedLoc, 'south'), 'red_bed[facing=north,part=foot]', false);
					}

					@ladderHeight = @maxRoomHeight + 4;
					while(@ladderHeight--) {
						@loc[1]--;
						if(!@exitRoom['boss'] || @ladderHeight > 2) {
							set_blockdata_string(@loc, 'ladder[facing=south]', false);
						} else {
							set_blockdata_string(@loc, 'iron_bars[north=true,south=true,east=true,west=true]', false);
						}
						if(@ladderHeight > 2) {
							set_block(location_shift(@loc, 'south'), @materials['wall'][0], false);
							set_block(location_shift(@loc, 'east'), @materials['wall'][0], false);
							set_block(location_shift(@loc, 'west'), @materials['wall'][0], false);
						} else {
							set_block(location_shift(@loc, 'south'), 'AIR', false);
						}
						set_block(location_shift(@loc, 'north'), @materials['wall'][0], false);
					}
					if(@exitRoom['boss']) {
						set_blockdata_string(@loc, 'repeating_command_block[facing=up]', false);
						set_block_command(@loc, 'execute unless entity @e[tag=floor'.(@floor - 1).'boss] run fill ~ ~ ~ ~ ~2 ~ ladder[facing=south]');
						@loc[1]--;
						set_block(@loc, 'REDSTONE_BLOCK');
					}
				}, 'generator');
			}
			@exitRoom = @rooms[@farthestRoom];
			@exitRoom['boss'] = @floorData['boss'];
		}

		// finished generation
		queue_push(closure(){
			res_free_resource(@random);
			remove_bar('gen'.@region);

			if(is_closure(@callback)) {
				// find an end col and row that isn't in a column
				for(@c = 0, @c < @exitRoom['width'], @c++) {
					for(@r = 0, @r < @exitRoom['length'], @r++) {
						if(@layoutMap[@c + @exitRoom['c1']][@r + @exitRoom['r1']] != 'column') {
							break(2);
						}
					}
				}
				@end = array(
					'x': (@exitRoom['c1'] + @c) * @options['floors'][array_size(@options['floors']) - 1]['scale'] + @regionMinX + 0.5,
					'y': @regionMinY + @floor * (@maxRoomHeight + 4) + 1,
					'z': (@exitRoom['r1'] + @r) * @options['floors'][array_size(@options['floors']) - 1]['scale'] + @regionMinZ + 0.5,
					'world': @world,
				);
				@start = array(
					'x': @entranceRoom['c1'] * @options['floors'][0]['scale'] + @regionMinX + 0.5,
					'y': @sy = @regionMinY + 1,
					'z': @entranceRoom['r1'] * @options['floors'][0]['scale'] + @regionMinZ + 0.5,
					'world': @world,
				);
				execute(@start, @end, @spawns, @callback);
			}
		}, 'generator');

	}); // End thread
}
