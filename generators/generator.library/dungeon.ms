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
	@options = yml_decode(read('dungeon.library/'.@dungeonType.'.yml'));
	if(!array_index_exists(@options, 'floors')
	|| @testFloor > -1 && !array_index_exists(@options['floors'], @testFloor)) {
		die('Floor does not exist. '.if(@testFloor > -1, 'Floor: '.@testFloor));
	}
	@defaults = array_merge(array(
		// size
		minRoomSize: 5,
		maxRoomSize: 21,
		minRoomHeight: 3,
		maxRoomHeight: 3,

		// variability on room features
		chestCount: 0,
		spawnerChance: 0.7,
		extraDoors: 0.0,
		campfireChance: 0.0,
		attic: 0.0, // 0.3
		balcony: 0.0, // 0.3
		lavaPit: 0.0, // 0.06
		waterPit: 0.0, // 0.06
		pit: 0.0, // 0.06
		fireFloor: 0.0, // 0.06
		pillars: 0.0,
		tables: 0.0,
		spawnCount: 1,

		// toggleable features on floors
		roof: true,
		bed: false,
		treasureRoom: false,

		// default materials
		divider: 'bedrock',
		empty: 'bedrock',
		room: 'air',
		door: 'air',
		window: '', // optional

		// special spawns
		boss: '',
	), @options['default']);

	// process floors config to a useful format and verify values
	@dungeonEntrance = array_get(@options, 'dungeonEntrance', false);
	@cloneOffset = array_get(@options, 'cloneOffset', 0);
	@cloneDir = array_get(@options, 'cloneDir', '');
	foreach(@type in array('floors', 'cloneFloors')) {
		if(@type == 'cloneFloors' && !array_index_exists(@options, 'cloneFloors')) {
			continue();
		}
		foreach(@floor: @floorData in @options[@type]) {
			@floorData = array_merge(@defaults, @floorData);

			// For now we can check if all numbers are positive, but this may change in the future.
			foreach(@key: @value in @floorData) {
				if(is_number(@value) && @value < 0) {
					console(@dungeonType.'.yml '.@key.' must be positive.');
					return();
				}
			}

			if(@floorData['minRoomSize'] % 2 != 1) {
				console(@dungeonType.'.yml minRoomSize must be an odd number.');
				return();
			}
			if(@floorData['minRoomSize'] < 5) {
				console(@dungeonType.'.yml minRoomSize must be 5 or larger');
				return();
			}
			if(@floorData['maxRoomSize'] % 2 != 1) {
				console(@dungeonType.'.yml maxRoomSize must be an odd number.');
				return();
			}

			// ensure certain values are arrays
			// these default to an array with air
			foreach(@key in array('utility', 'decor', 'wall', 'floor')) {
				if(array_index_exists(@floorData, @key)) {
					if(is_string(@floorData[@key])) {
						@floorData[@key] = array(@floorData[@key]);
					}
				} else {
					@floorData[@key] = array('air');
				}
			}
			// these default to falsey
			foreach(@key in array('trap', 'spawner')) {
				if(array_index_exists(@floorData, @key)) {
					if(is_string(@floorData[@key])) {
						@floorData[@key] = array(@floorData[@key]);
					}
				} else {
					@floorData[@key] = null;
				}
			}

			@options[@type][@floor] = @floorData;
		}
	}

	// define constants
	@seed = @seed ||| integer(time() / 100000);
	@coords = sk_region_info(@region, @world, 0);
	@regionMinX = @coords[1][0];
	@regionMaxX = @coords[0][0];
	@regionMinY = @coords[1][1];
	@regionMinZ = @coords[1][2];
	@regionMaxZ = @coords[0][2];
	@regionWidth = @coords[0][0] - @coords[1][0] + 1;
	@regionLength = @coords[0][2] - @coords[1][2] + 1;
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
	create_bar('gen'.@region, array(title: 'Generating '.@dungeonType.if(array_size(@options['floors']) > 1, ' floor 1'), percent: 0.0));
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
		@width = @regionWidth;
		@length = @regionLength;
		@c = if(@dungeonEntrance) {
			integer(@width / 2 - 3)
		} else {
			1 + integer(srand(@random) * (@width - 5))
		}
		@r = if(@dungeonEntrance) {
			@length - 6
		} else {
			1 + integer(srand(@random) * (@length - 5))
		}
		@entranceRoom = array(
			r1: @r,
			c1: @c,
			width: 5,
			length: 5,
			connected: 0,
			doors: 0,
			height: @options['floors'][0]['maxRoomHeight'],
			type: 'NORMAL',
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
			@maxRoomSize = min(@floorData['maxRoomSize'], @length - 2, @width - 2);
			@minRoomSize = min(@floorData['minRoomSize'], @maxRoomSize);
			@maxRoomHeight = @floorData['maxRoomHeight'];
			@minRoomHeight = min(@floorData['minRoomHeight'], @maxRoomHeight);
			@roof = @floorData['roof'];
			@chestCount = @floorData['chestCount'];
			@spawnCount = @floorData['spawnCount'];
			@extraDoors = @floorData['extraDoors'];
			@mobTypes = @floorData['spawner'];
			@noise = math_const('INTEGER_MAX') + 1 + integer(srand(@random) * math_const('INTEGER_MAX'));

			@width = @regionWidth;
			@length = @regionLength;

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
					@layoutMap[@c][@r] = 'empty';
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
					r1: @r,
					c1: @c,
					width: min(@exitRoom['width'], 3),
					length: min(@exitRoom['length'], 3),
					connected: 0,
					doors: 0,
					height: 4,
					type: 'NORMAL',
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
			@maxRoomCount = min(@width, @length);
			@unconnected = array(0);
			for(@r = 0, @r < @length - 2, @r++) {
				for(@c = 0, @c < @width - 2, @c++) {
					if(x_is_interrupted()) {
						remove_bar('gen'.@region);
						die('Interrupted planning rooms: '.array_size(@rooms).' '.@rooms[0..5].' ... ');
					}
					if(@roomMap[@c][@r] == -1 && @roomMap[@c + 1][@r + 1] == -1) {
						@roomWidth = integer(srand(@random) * (@maxRoomSize - @minRoomSize + 1)) + @minRoomSize;
						@roomLength = integer(srand(@random) * (@maxRoomSize - @minRoomSize + 1)) + @minRoomSize;

						// Check placement and shrink if necessary to avoid room collisions.
						for(@r2 = @r, @r2 < @r + @roomLength + 2, @r2++) {
							if(@r2 >= @length) {
								@roomLength = @r2 - @r - 2;
								break();
							} else if(@roomMap[@c][@r2] != -1) {
								@roomLength = @r2 - @r - 2;
								break();
							}
							for(@c2 = @c + 1, @c2 < @c + @roomWidth + 2, @c2++) {
								if(@c2 >= @width) {
									@roomWidth = @c2 - @c - 2;
									break();
								} else if(@roomMap[@c2][@r2] != -1) {
									if(@c2 - @c - 2 < 1) {
										@roomLength = @r2 - @r - 2;
										break(2);
									} else {
										@roomWidth = @c2 - @c - 2;
										break();
									}
								}
							}
						}

						if(@roomLength < 1 || @roomWidth < 1) {
							continue();
						}

						// Now that we have the width and length, the height can be determined to match.
						// This allows for good looking hallways at minRoomHeight.
						@height = @minRoomHeight;
						if(@roomWidth != 1 && @roomLength != 1) {
							@height = @minRoomHeight + integer(srand(@random) * (@maxRoomHeight - @minRoomHeight + 1));
						}

						// Room types determine generation shape
						@type = 'NORMAL';
						if(@floorData['tables'] && @roomWidth == @roomLength && @roomWidth > 2 && @roomWidth < 6
						&& @height >= 4 && srand(@random) < @floorData['tables']) {
							@type = 'TABLE';
						} else if(@floorData['pillars'] && @roomWidth > 1 && @roomLength > 1 && srand(@random) < @floorData['pillars']) {
							@type = 'PILLARS';
						} else if(@floorData['attic'] && @height >= 7 && srand(@random) < @floorData['attic']) {
							@type = 'ATTIC';
						} else if(@floorData['balcony'] && @roomWidth > 1 && @roomLength > 1 && @height >= 7 && srand(@random) < @floorData['balcony']) {
							@type = 'BALCONY';
						} else if(@floorData['lavaPit'] && @roomWidth > 1 && @roomLength > 1 && srand(@random) < @floorData['lavaPit']) {
							@type = 'LAVA_PIT';
							if(@height < 4) {
								@height = 4;
							}
						} else if(@floorData['waterPit'] && srand(@random) < @floorData['waterPit']) {
							@type = 'WATER_PIT';
						} else if(@floorData['fireFloor'] && @roomWidth > 1 && @roomLength > 1 && srand(@random) < @floorData['fireFloor']) {
							@type = 'FIRE_FLOOR';
						} else if(@floorData['pit'] && srand(@random) < @floorData['pit']) {
							@type = 'PIT';
							if(@height < 4) {
								@height = 4;
							}
						}

						// Save room
						@unconnected[] = array_size(@rooms);
						@rooms[] = array(
							r1: @r + 1,
							c1: @c + 1,
							width: @roomWidth,
							length: @roomLength,
							connected: 0,
							doors: 0,
							height: @height,
							midheight: 3 + integer(srand(@random) * (@height - 7)),
							type: @type
						);

						if(array_size(@rooms) > @maxRoomCount) {
							remove_bar('gen'.@region);
							console('Debug: (max room count exceeded) '.@rooms);
							die('Exceeded max room count of '.@maxRoomCount.'. Stopped room planning.');
						}

						// Mask room
						for(@r2 = @r + 1, @r2 < @roomLength + @r + 1, @r2++) {
							for(@c2 = @c + 1, @c2 < @roomWidth + @c + 1, @c2++) {
								@roomMap[@c2][@r2] = array_size(@rooms) - 1;
							}
						}

						// Move the column var to the end of the room, before incrementation.
						@c += @roomWidth;
					}
				}
			}

			// Connect rooms
			@current = 0;
			@previous = 0;
			@try = array();
			@limit = array_size(@rooms) * @maxRoomSize * 4;
			@connected = associative_array();
			@maxRoomDistance = 0;
			@farthestRoom = null;
			@possibleDeadEnds = associative_array();
			while(@unconnected) {
				if(x_is_interrupted()) {
					remove_bar('gen'.@region);
					die('Interrupted connecting rooms: '.array_size(@unconnected).'/'.array_size(@rooms).' ... ');
				}
				@limit--;
				if(@limit < 0){
					msg('Hit room connector limit ('.@limit.')! Rooms left: '.array_size(@unconnected).'/'.array_size(@rooms).'!');
					break();
				}

				array_remove_values(@unconnected, @current);
				@connected[@current] = null;
				@room = @rooms[@current];
				if(@room['connected'] == 0){
					@room['connected'] = @rooms[@previous]['connected'] + 1;
					if(@room['connected'] > @maxRoomDistance) {
						@maxRoomDistance = @room['connected'];
						@farthestRoom = @current;
					}
				}

				@r = @room['r1'];
				@c = @room['c1'];
				@roomWidth = @room['width'];
				@roomLength = @room['length'];

				@success = false;
				@dirs = array(0, 1, 2, 3);
				foreach(@d in range(4)) {
					@dir = array_remove(@dirs, integer(srand(@random) * array_size(@dirs)));
					try {
						@c2 = 0;
						@r2 = 0;
						@c3 = 0;
						@r3 = 0;
						switch(@dir){
							case 0:
								@r2 = @r - 2;
								if(@r2 < 1) {
									continue();
								}
								@c2 = @c + integer(srand(@random) * @roomWidth);
								@r3 = @r2 + 1;
								@c3 = @c2;
							case 1:
								@r2 = @r + @roomLength + 1;
								if(@r2 >= @length) {
									continue();
								}
								@c2 = @c + integer(srand(@random) * @roomWidth);
								@r3 = @r2 - 1;
								@c3 = @c2;
							case 2:
								@c2 = @c - 2;
								if(@c2 < 1) {
									continue();
								}
								@r2 = @r + integer(srand(@random) * @roomLength);
								@c3 = @c2 + 1;
								@r3 = @r2;
							case 3:
								@c2 = @c + @roomWidth + 1;
								if(@c2 >= @width) {
									continue();
								}
								@r2 = @r + integer(srand(@random) * @roomLength);
								@c3 = @c2 - 1;
								@r3 = @r2;
						}
						@next = @roomMap[@c2][@r2];
						if(@next != -1 && @next != @previous) {
							if(!@rooms[@next]['connected']) {
								@layoutMap[@c3][@r3] = 'door';
								@rooms[@next]['doors']++;
								@room['doors']++;
								@previous = @current;
								@current = @next;
								@success = true;
								@try = array();
								break();
							} else if((@rooms[@next]['doors'] == 2 || @rooms[@current]['doors'] == 2) && srand(@random) < @extraDoors) {
								@layoutMap[@c3][@r3] = 'door';
								@rooms[@next]['doors']++;
								@room['doors']++;
							}
						}
					} catch(Exception @ex){
						// no room here
					}
				}
				if(!@success) {
					@possibleDeadEnds[@current] = array_get(@possibleDeadEnds, @current, 0) + 1;
					if(@previous == @current) {
						@limit2 = array_size(@rooms) * 2;
						do {
							@current = array_keys(@connected)[integer(srand(@random) * array_size(@connected))];
							@limit2--;
						} while(@limit2 > 0 && (@current == @previous || array_contains(@try, @current)));
						@try[] = @current;
					} else {
						// go back one if we haven't already
						@current = @previous;
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

			// Mark room layout
			foreach(@n: @room in @rooms){
				if(!@room['connected']){
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
							if(@room['type'] == 'PILLARS'
							|| @room['type'] == 'TABLE'
							|| @roomLength == 1
							|| @roomWidth == 1
							|| _adjacent_equals(@layoutMap, @c2, @r2, 'door')
							|| (!is_null(@rowOdd) && (@rowOdd != @r2 % 2 || @columnOdd != @c2 % 2))
							|| integer(srand(@random) * 100) < 90) {
								@layoutMap[@c2][@r2] = 'room';
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
								@r = (@chunkZ * 16 + @z - @chunkOffsetZ);
								@c = (@chunkX * 16 + @x - @chunkOffsetX);
								if(@r < 0 || @c < 0 || @r >= @length || @c >= @width) {
									continue();
								}

								@groundY = @regionMinY + @floor * (@maxRoomHeight + 4) + if(@cloneDir == 'up', @clone * @cloneOffset, 0);
								@roomHeight = @heightMap[@c][@r];
								@roomId = @roomMap[@c][@r];
								@room = if(@roomMap[@c][@r] != -1, @rooms[@roomId], null);
								@loc = array(
									(@chunkMinX + @chunkX) * 16 + @x + if(@cloneDir == 'east', @clone * @cloneOffset, 0),
									@groundY,
									(@chunkMinZ + @chunkZ) * 16 + @z + if(@cloneDir == 'south', @clone * @cloneOffset, 0),
									@world
								);

								// Bedrock divider
								_add_to_chunk(@chunk, @loc, @materials['divider']);

								// Floor
								@loc[1] += 1;
								@roomType = if(@room, @room['type'], null);
								if(@roomType == 'FIRE_FLOOR' && @layoutMap[@c][@r] != 'column') {
									_add_to_chunk(@chunk, @loc, 'dispenser[facing=up]');
								} else if(@roomType == 'LAVA_PIT' && @layoutMap[@c][@r] != 'column') {
									if(!_direction_of_solid(@layoutMap, @c, @r) || srand(@random) < 0.6) {
										_add_to_chunk(@chunk, @loc, 'lava');
									} else {
										_add_to_chunk(@chunk, @loc, @materials['floor']);
									}
								} else if(@roomType == 'WATER_PIT' && @layoutMap[@c][@r] != 'column') {
									if(!_direction_of_solid(@layoutMap, @c, @r) || srand(@random) < 0.7) {
										_add_to_chunk(@chunk, @loc, 'water');
									} else {
										_add_to_chunk(@chunk, @loc, @materials['floor']);
									}
								} else if(@roomType == 'PIT' && @layoutMap[@c][@r] != 'column') {
									if(!_direction_of_solid(@layoutMap, @c, @r) || srand(@random) < 0.55) {
										@holeDepth = @maxRoomHeight;
										while(@holeDepth-- > 0) {
											_add_to_chunk(@chunk, location_shift(@loc, 'down', @holeDepth), 'air');
										}
									} else {
										_add_to_chunk(@chunk, @loc, @materials['floor']);
									}
								} else if(@layoutMap[@c][@r] == 'wall') {
									_add_to_chunk(@chunk, @loc, @materials['wall']);
								} else {
									// different rooms, different floors
									@floorMat = @materials['floor'];
									if(is_array(@floorMat) && @testFloor > -1) {
										if(@room != null) {
											@floorMat = @floorMat[@room['connected'] % array_size(@materials['floor'])];
										} else {
											@floorMat = @floorMat[0];
										}
									}
									_add_to_chunk(@chunk, @loc, @floorMat);
								}

								// Walls
								@ceilingY = @groundY + @roomHeight + 2;
								@y = 0;
								for(@y = @groundY + 2, @y < @ceilingY, @y++) {
									@loc[1] = @y;
									switch(@layoutMap[@c][@r]) {
										case 'window':
											if(@y < @ceilingY - @roomHeight + 3
											&& @y > @ceilingY - @roomHeight) {
												_add_to_chunk(@chunk, @loc, @materials['window']);
											} else {
												_add_to_chunk(@chunk, @loc, @materials['wall']);
											}

										case 'wall':
											_add_to_chunk(@chunk, @loc, @materials['wall']);

										case 'room':
											switch(@roomType) {
												case 'TABLE':
													if(@y == @groundY + 2
													&& !_direction_of_border(@layoutMap, @c, @r)) {
														_add_to_chunk(@chunk, @loc, @materials['table']);
														continue();
													}
												case 'PILLARS':
													if(!_adjacent_equals(@layoutMap, @c, @r, 'door') 
													&& !bit_and(@noise, integer(2 ** (abs(@x) + abs(@z))))
													&& integer(@x ** abs(@z)) % 5 == 1
													&& integer(@z ** abs(@x)) % 5 == 1) {
														_add_to_chunk(@chunk, @loc, @materials['column']);
														continue();
													}
												case 'FIRE_FLOOR':
													if(@y == @groundY + 2
													&& (@x + @z) % 2
													&& srand(@random) > 0.2) {
														_add_to_chunk(@chunk, @loc, 'stone_pressure_plate');
														continue();
													}
												case 'ATTIC':
													if(@y == @ceilingY - @roomHeight + @room['midheight']) {
														_add_to_chunk(@chunk, @loc, @materials['floor']);
														continue();
													}
												case 'BALCONY':
													if(@y == @ceilingY - @roomHeight + @room['midheight']
													&& _direction_of_border(@layoutMap, @c, @r)) {
														_add_to_chunk(@chunk, @loc, @materials['floor'][0]);
														continue();
													}
											}

											if(@materials['edge'] != 'air'
											&& @room['width'] > 1
											&& @room['length'] > 1
											&& @roomHeight > 3
											&& @y == @ceilingY - 1) {
												@stairs = string_ends_with(@materials['edge'], 'stairs');
												@north = @layoutMap[@c][@r - 1];
												@south = @layoutMap[@c][@r + 1];
												@west = @layoutMap[@c - 1][@r];
												@east = @layoutMap[@c + 1][@r];
												@state = @materials['edge'].if(@stairs, '[half=top'.if(@materials['room'] == 'water', ',waterlogged=true'));
												if(@roomHeight < 4 && (@east == 'window' || @west == 'window'
												|| @north == 'window' || @south == 'window')) {
													@state = @materials['room'];
												} else if(@east == 'wall' || @east == 'door' || @east == 'window') {
													if(@stairs) {
														@state .= ',facing=east'
														if(@roomHeight == 3 && @east == 'door') {
															@state .= ',shape=outer_left';
														} else if(@north == 'wall' || @north == 'door' && @roomHeight > 3) {
															@state .= ',shape=inner_left';
														} else if(@south == 'wall' || @south == 'door' && @roomHeight > 3) {
															@state .= ',shape=inner_right';
														}
														@state .= ']';
													}
												} else if(@west == 'wall' || @west == 'door' || @west == 'window') {
													if(@stairs) {
														@state .= ',facing=west'
														if(@roomHeight == 3 && @west == 'door') {
															@state .= ',shape=outer_left';
														} else if(@north == 'wall' || @north == 'door' && @roomHeight > 3) {
															@state .= ',shape=inner_right';
														} else if(@south == 'wall' || @south == 'door' && @roomHeight > 3) {
															@state .= ',shape=inner_left';
														}
														@state .= ']';
													}
												} else if(@south == 'wall' || @south == 'door' || @south == 'window') {
													if(@stairs) {
														@state .= ',facing=south';
														if(@roomHeight == 3 && @south == 'door') {
															@state .= ',shape=outer_left';
														}
														@state .= ']';
													}
												} else if(@north == 'wall' || @north == 'door' || @north == 'window') {
													if(@stairs) {
														@state .= ',facing=north'
														if(@roomHeight == 3 && @north == 'door') {
															@state .= ',shape=outer_left';
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
												if(string_ends_with(@materials['door'], 'door')) {
													@lower = @y < @ceilingY - @roomHeight + 1;
													@north = @roomMap[@c][@r - 1];
													@south = array_get(@roomMap[@c], @r + 1, 0); // special case for dungeon entrance
													@west = @roomMap[@c - 1][@r];
													@east = @roomMap[@c + 1][@r];
													@count = array_size(@chunk);
													if(@north % 7 == 0) {
														@half = if(@lower, 'half=lower,', 'half=upper,');
														_add_to_chunk(@chunk, @loc, @materials['door'].'[facing=south,'.@half.'hinge=left]');
													} else if(@south % 7 == 0) {
														@half = if(@lower, 'half=lower,', 'half=upper,');
														_add_to_chunk(@chunk, @loc, @materials['door'].'[facing=north,'.@half.'hinge=left]');
													} else if(@west % 7 == 0) {
														@half = if(@lower, 'half=lower,', 'half=upper,');
														_add_to_chunk(@chunk, @loc, @materials['door'].'[facing=east,'.@half.'hinge=left]');
													} else if(@east % 7 == 0) {
														@half = if(@lower, 'half=lower,', 'half=upper,');
														_add_to_chunk(@chunk, @loc, @materials['door'].'[facing=west,'.@half.'hinge=left]');
													}
													if(@count == array_size(@chunk)) {
														_add_to_chunk(@chunk, @loc, @materials['room']);
													}
												} else {
													_add_to_chunk(@chunk, @loc, @materials['door']);
												}
											} else if(@y == @ceilingY - @roomHeight + 2 && !string_ends_with(@materials['door'], 'door')) {
												_add_to_chunk(@chunk, @loc, @materials['room']);
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
										_add_to_chunk(@chunk, @loc, @materials['divider']);
									}

									// Bedrock floor divider
									while(@loc[1] < @y + @maxRoomHeight - @roomHeight + 1) {
										@loc[1] += 1;
										if(@layoutMap[@c][@r] === 'room') {
											_add_to_chunk(@chunk, @loc, @materials['empty']);
										} else {
											_add_to_chunk(@chunk, @loc, @materials['divider']);
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
							update_bar(@bar, array(title: @title, percent: @percent));
						}, 'generator');
						queue_push(iclosure(
							@thisChunk = @chunk,
							@thisWorld = @world
						){
							for(@i = 0, @i < array_size(@thisChunk), @i += 2) {
								set_blockdata_string(@thisChunk[@i], @thisChunk[@i + 1], false);
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
			@chestArray = array();
			foreach(@i: @room in @rooms) {
				if(!@room['connected']) {
					continue();
				}

				@yFloor = @regionMinY + (@floor * (@maxRoomHeight + 4)) + 2;
				@roomHeight = @room['height'];

				// We need to create spawns after all blocks are set to ensure clearance.
				@createSpawns = closure(){
					if(@spawnCount > 0) {
						@count = @spawnCount;
						while(@count > 0) {
							@loc = array(
								@regionMinX + @room['c1'] + integer(srand(@random) * (@room['width'])) + 0.5,
								@yFloor + if(@room['type'] == 'ATTIC', @room['midheight'] + 1, 0),
								@regionMinZ + @room['r1'] + integer(srand(@random) * (@room['length'])) + 0.5,
								@world,
								if(@room['type'] == 'ATTIC', 0, @room['doors']), // use this for sorting, lower being more isolated a room
								@room['connected'] // distance to start
							);
							if(equals_ic(@materials['room'], get_block(@loc))) {
								if(string_ends_with(@room['type'], 'PIT')) {
									set_blockdata_string(location_shift(@loc, 'down'), array_get_rand(@materials['floor']), false);
								}
								@count--;
								@spawns[@floor][] = @loc;
							} else if(srand(@random) < 0.2) { // re-attempt spawns 4/5 of the time
								@count--;
							}
						}
					}
				}

				if(@room['length'] == 1 || @room['width'] == 1) {
					if(@room['doors'] == 1) {
						// only create spawns if it's a dead end hallway
						queue_push(@createSpawns, 'generator');
					}
					continue();
				} else if(string_ends_with(@room['type'], 'PIT')) {
					// Still want to create spawns, but conditions are poor for other blocks and traps
					queue_push(@createSpawns, 'generator');
					continue();
				}

				queue_push(closure(){
					@spawner = false;
					if(@room['type'] == 'FIRE_FLOOR') {
						@y = @yFloor - 1;
						for(@x = @regionMinX + @room['c1'], @x < @regionMinX + @room['c1'] + @room['width'], @x++) {
							for(@z = @regionMinZ + @room['r1'], @z < @regionMinZ + @room['r1'] + @room['length'], @z++) {
								try(set_inventory(array(@x, @y, @z, @world), array(0: array(
									name: 'FLINT_AND_STEEL'
								))));
							}
						}
					} else {
						// spawner
						if(@room['connected'] > 1 && @mobTypes && srand(@random) < @floorData['spawnerChance']) {
							@loc = array(
								@regionMinX + @room['c1'] + 1 + integer(srand(@random) * (@room['width'] - 2)),
								@yFloor + if(@room['type'] == 'ATTIC' && srand(@random) > 0.67, @room['midheight'] + 1, 0),
								@regionMinZ + @room['r1'] + 1 + integer(srand(@random) * (@room['length'] - 2)),
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
							@attempts = 10;
							while(@attempts-- > 0) {
								@loc = array(
									@regionMinX + @room['c1'] + 1 + integer(srand(@random) * (@room['width'] - 2)),
									@yFloor + if(@room['type'] == 'ATTIC' && srand(@random) > 0.67, @room['midheight'] + 1, 0),
									@regionMinZ + @room['r1'] + 1 + integer(srand(@random) * (@room['length'] - 2)),
									@world
								);
								if(equals_ic(@materials['room'], get_block(@loc))) {
									set_block(@loc, 'CAMPFIRE', false);\
									@loc = location_shift(@loc, 'down');
									set_block(@loc, 'PODZOL', false);
									for(@x = -1, @x <= 1, @x++) {
										for(@z = -1, @z <= 1, @z++) {
											@r = rand();
											if(@x == @z && @r > 0.75 || @x != @z && @r > 0.25) {
												set_block(array(@loc['x'] + @x, @loc['y'], @loc['z'] + @z, @loc['world']), 'PODZOL', false);
											}
										}
									}
									break();
								}
							}
						}
					}

					if(@chestCount > 0) {
						@chests = @chestCount;
						if(@room['type'] == 'TREASURE') {
							@chests = 1;
						} else if(is_double(@chests)) {
							@chests = integer(srand(@random) * min(@room['length'], @room['width']) * @chests);
						}
						@bonus = if(@room['type'] == 'TREASURE', 4, 1);
						@chestHeight = if(@room['type'] == 'ATTIC' && srand(@random) > 0.33){
							@room['midheight'] + 1
						} else if(@room['type'] == 'TREASURE') {
							1
						} else {
							0
						}
						@attempts = 10;
						while(@attempts-- > 0 && @chests > 0) {
							@loc = array(
								@regionMinX + @room['c1'] + 1 + integer(srand(@random) * (@room['width'] - 2)),
								@yFloor + @chestHeight,
								@regionMinZ + @room['r1']  + 1 + integer(srand(@random) * (@room['length'] - 2)),
								@world
							);
							if(equals_ic(@materials['room'], get_block(@loc))) {
								@chests--;
								set_blockdata_string(@loc, 'chest[facing='._get_direction(@random).if(@materials['room'] == 'water', ',waterlogged=true').']', false);
								try(set_inventory(@loc, _get_loot(@floor, @random, @bonus)))
								if(@room['type'] == 'TREASURE') {
									set_blockdata_string(location_shift(@loc, 'down'), 'diamond_block');
									if(@chestArray) { // only lock this chest if we have a previous chest to add a key to
										set_block_lock(@loc, 'Key'.(@floor + 1));
										add_to_inventory(@chestArray[integer(srand(@random) * array_size(@chestArray))],
												array(name: 'TRIPWIRE_HOOK', meta: array(display: 'Key'.(@floor + 1))));
									}
								} else {
									@chestArray[] = @loc;
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
							@regionMinX + @room['c1'] + 1 + integer(srand(@random) * (@room['width'] - 2)),
							@yFloor + if(@room['type'] == 'ATTIC' && srand(@random) > 0.5, @room['midheight'] + 1, 0),
							@regionMinZ + @room['r1'] + 1 + integer(srand(@random) * (@room['length'] - 2)),
							@world
						);
						if(equals_ic(@materials['room'], get_block(@loc))) {
							set_blockdata_string(@loc, @materials['utility'][integer(srand(@random) * array_size(@materials['utility']))], false);
						}
					}

					@decorations = integer(srand(@random) * max(@room['length'], @room['width']));
					while(@decorations-- > 0) {
						@loc = array(
							@regionMinX + @room['c1'] + 1 + integer(srand(@random) * (@room['width'] - 2)),
							@yFloor + if(@room['type'] == 'ATTIC' && srand(@random) > 0.5, @room['midheight'] + 1, 0),
							@regionMinZ + @room['r1'] + 1 + integer(srand(@random) * (@room['length'] - 2)),
							@world
						);
						if(equals_ic(@materials['room'], get_block(@loc))) {
							set_blockdata_string(@loc, @materials['decor'][integer(srand(@random) * array_size(@materials['decor']))], false);
						}
					}

					if(@room['type'] == 'ATTIC') {
						@vines = min(@room['width'], @room['length']);
						do {
							@loc = null;
							@attempts = 5;
							do {
								@loc = array(
									@regionMinX + @room['c1'] + integer(srand(@random) * @room['width']),
									@yFloor + @room['midheight'] + 1,
									@regionMinZ + @room['r1'] + integer(srand(@random) * @room['length']),
									@world
								);
							} while(!equals_ic(@materials['room'], get_block(@loc)) && --@attempts > 0);
							@dirs = array_rand(array('east', 'west', 'north', 'south'), rand(1, 4), false);
							@block = array(block: 'vine');
							foreach(@dir in @dirs) {
								@block[@dir] = true;
							}
							@length = @room['midheight'];
							while(@length-- > 0) {
								@loc[1]--;
								set_blockdata(@loc, @block);
							}
							@vines--;
						} while(@vines > 0 || srand(@random) > 0.45);
					}

					if(@i == @farthestRoom && @floorData['boss']) {
						@tries = 10;
						while(@tries-- > 0) {
							@loc = array(
								@regionMinX + @room['c1'] + integer(srand(@random) * @room['width']) + 0.5,
								@yFloor,
								@regionMinZ + @room['r1'] + integer(srand(@random) * @room['length']) + 0.5,
								@world
							);
							if(equals_ic(@materials['room'], get_block(@loc))) {
								_spawn_entity(@floorData['boss'], @loc, null, closure(@entity) {
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
							@data = if(array_size(@type) >= 3, array_implode(@type[2..], '_'), null);
							@facing = 'up';
							@loc = null;
							if(@trigger == 'chest' || @effect == 'cactus') {
								@loc = array(
									@regionMinX + @room['c1'] + 1 + integer(srand(@random) * (@room['width'] - 2)),
									@yFloor,
									@regionMinZ + @room['r1'] + 1 + integer(srand(@random) * (@room['length'] - 2)),
									@world
								);
							} else {
								@loc = array(
									@regionMinX + @room['c1'] + integer(srand(@random) * @room['width']),
									@yFloor,
									@regionMinZ + @room['r1'] + integer(srand(@random) * @room['length']),
									@world
								);
							}
							if(!equals_ic(@materials['room'], get_block(@loc))) {
								continue();
							}
							switch(@trigger) {
								case 'static':
									noop(); // no trigger
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
								case 'vines':
									if(@room['type'] == 'ATTIC' || @room['type'] == 'BALCONY') {
										continue();
									}
									if(!@spawner) {
										set_block(@loc, 'TRIPWIRE', false);
										@loc = location_shift(@loc, 'up');
									}
									while(@loc[1] < @yFloor + @roomHeight && !material_info(get_block(@loc), 'isOccluding')) {
										set_block(@loc, 'TWISTING_VINES');
										@loc = location_shift(@loc, 'up');
									}
									set_blockdata(location_shift(@loc, 'up'), 'redstone_block', false);
									@facing = 'down';
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
									set_blockdata_string(@tripwire[0], 'tripwire_hook[facing='.@positive.',attached=true]', false);
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
											name: 'FLINT_AND_STEEL', meta: array(damage: 61)
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
									set_inventory(@loc, array(0: array(name: 'TNT', qty: 2)));
								case 'potion':
									@solid = material_info(get_block(location_shift(@loc, @facing)), 'isSolid');
									if(@solid || @facing == 'down') {
										set_blockdata_string(@loc, 'dispenser[facing='.@facing.']', false);
									} else {
										set_blockdata_string(@loc, 'dispenser[facing=north]', false);
									}
									set_inventory(@loc, array(0: array(
										name: if(@solid || @facing == 'down', 'LINGERING_POTION', 'SPLASH_POTION'),
										qty: if(@trigger == 'vines', 1, 3),
										meta: array(base: array(extended: false, type: to_upper(@data), upgraded: true))
									)));
								case 'arrow':
									set_blockdata_string(@loc, 'dispenser[facing='.@facing.']', false);
									set_inventory(@loc, array(0: array(name: 'TIPPED_ARROW', qty: 3, meta: array(base: array(type: 'INSTANT_DAMAGE', upgraded: true, extended: false)))));
							}
							if(@trigger == 'plate') {
								// needs to be after dispenser
								set_block(location_shift(@loc, 'up'), 'STONE_PRESSURE_PLATE', false);
							}
						}
					}

					execute(@createSpawns);
				}, 'generator');
			}

			// exit room / Pop ladder into floor
			if(@exitRoom) {
				queue_push(closure(){

					@loc = array(
						@regionMinX + @exitRoom['c1'],
						@regionMinY + @floor * (@maxRoomHeight + 4) + 2,
						@regionMinZ + @exitRoom['r1'],
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
							set_blockdata_string(@loc, 'reinforced_deepslate', false);
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
						@exitRoomC = @exitRoom['c1'] + @c;
						@exitRoomR = @exitRoom['r1'] + @r;
						if(@layoutMap[@exitRoomC][@exitRoomR] != 'column') {
							// we have the desired @c and @r now
							break(2);
						}
					}
				}
				@end = array(
					x: (@exitRoom['c1'] + @c) + @regionMinX + 0.5,
					y: @regionMinY + @floor * (@maxRoomHeight + 4) + 1,
					z: (@exitRoom['r1'] + @r) + @regionMinZ + 0.5,
					world: @world,
				);
				@start = array(
					x: @entranceRoom['c1'] + @regionMinX + 0.5,
					y: @sy = @regionMinY + 1,
					z: @entranceRoom['r1'] + @regionMinZ + 0.5,
					world: @world,
				);
				foreach(@floor: @spawnSet in @spawns) {
					array_sort(@spawnSet, closure(@left, @right) {
						return(@left[4] > @right[4]); // sort by door count (more isolated is lower)
					});
				}
				execute(@start, @end, @spawns, @callback);
			}
		}, 'generator');

	}); // End thread
}
