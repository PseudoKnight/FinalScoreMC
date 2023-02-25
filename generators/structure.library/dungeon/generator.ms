proc _generate(@dungeonType, @region, @world, @seed, @callback, @debug = false) {
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
	include('loot/default.ms');
	try {
		include('loot/'.@dungeonType.'.ms');
	} catch(IOException @ex) {
		// does not exist, but that is okay
	}

	// load dungeon type configuration
	@options = yml_decode(read('configs/'.@dungeonType.'.yml'));
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
		barrelCount: 0,
		spawnerChance: 0.7,
		extraDoorChance: 0.0,
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

	foreach(@floor: @floorData in @options['floors']) {
		@floorData = array_merge(@defaults, @floorData);

		// For now we can check if all numbers are positive, but this may change in the future.
		foreach(@key: @value in @floorData) {
			if(is_number(@value) && @value < 0) {
				console(@dungeonType.'.yml '.@key.' must be positive.');
				return();
			}
		}

		if(@floorData['minRoomSize'] < 5) {
			console(@dungeonType.'.yml minRoomSize must be 5 or larger');
			return();
		}

		// ensure certain values are arrays
		// these default to an array with air
		foreach(@key in array('wall', 'floor')) {
			if(array_index_exists(@floorData, @key)) {
				if(is_string(@floorData[@key])) {
					@floorData[@key] = array(@floorData[@key]);
				}
			} else {
				@floorData[@key] = array('air');
			}
		}
		// these default to falsey
		foreach(@key in array('utility', 'trap', 'spawner')) {
			if(array_index_exists(@floorData, @key)) {
				if(is_string(@floorData[@key])) {
					@floorData[@key] = array(@floorData[@key]);
				}
			} else {
				@floorData[@key] = null;
			}
		}

		@options['floors'][@floor] = @floorData;
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
			integer(@width / 2 - 4)
		} else {
			2 + integer(srand(@random) * (@width - 9))
		}
		@r = if(@dungeonEntrance) {
			@length - 8
		} else {
			2 + integer(srand(@random) * (@length - 9))
		}
		@entranceRoom = array(
			r1: @r,
			c1: @c,
			width: 6,
			length: 6,
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

			@floorData = @options['floors'][@floor];
			@maxRoomSize = min(@floorData['maxRoomSize'], @length - 4, @width - 4);
			@minRoomSize = min(@floorData['minRoomSize'], @maxRoomSize);
			@maxRoomHeight = @floorData['maxRoomHeight'];
			@minRoomHeight = min(@floorData['minRoomHeight'], @maxRoomHeight);
			@groundY = @regionMinY + @floor * (@maxRoomHeight + 4);
			@roof = @floorData['roof'];
			@chestCount = @floorData['chestCount'];
			@barrelCount = @floorData['barrelCount'];
			@spawnCount = @floorData['spawnCount'];
			@extraDoorChance = @floorData['extraDoorChance'];
			@mobTypes = @floorData['spawner'];
			@noise = integer(srand(@random) * math_const('LONG_MAX'));

			@width = @regionWidth;
			@length = @regionLength;

			queue_push(iclosure(
				@bar = 'gen'.@region,
				@title = 'Planning '.@dungeonType.' floor '.(@floor + 1),
				@pos1 = array(@regionMinX, @groundY, @regionMinZ),
				@pos2 = array(@regionMaxX, @groundY + @maxRoomHeight, @regionMaxZ),
			){
				update_bar(@bar, @title);
				sk_pos1(player(), @pos1);
				sk_pos2(player(), @pos2);
			}, 'generator');

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
					@layoutMap[integer(@width / 2) - 1][@length - 2] = 'door';
					@layoutMap[integer(@width / 2) - 2][@length - 2] = 'door';
					@layoutMap[integer(@width / 2) - 1][@length - 1] = 'door';
					@layoutMap[integer(@width / 2) - 2][@length - 1] = 'door';
					@layoutMap[integer(@width / 2) - 3][@length - 1] = 'wall';
					@layoutMap[integer(@width / 2)][@length - 1] = 'wall';
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
			@maxRoomCount = integer((average(@width, @length) / @minRoomSize) ** 2);
			@unconnected = array(0);
			@attempts = 0;
			for(@r = 1, @r < @length - 3, @r++) {
				for(@c = 1, @c < @width - 3, @c++) {
					if(x_is_interrupted()) {
						remove_bar('gen'.@region);
						sk_pos1(player(), null);
						sk_pos2(player(), null);
						die('Interrupted planning rooms: '.array_size(@rooms).' '.@rooms[0..5].' ... ');
					}
					if(@roomMap[@c][@r] == -1 && @roomMap[@c + 1][@r + 1] == -1) {
						@attempts++;
						@roomWidth = integer(srand(@random) * (@maxRoomSize - @minRoomSize + 1)) + @minRoomSize;
						@roomLength = integer(srand(@random) * (@maxRoomSize - @minRoomSize + 1)) + @minRoomSize;

						// Check placement and shrink if necessary to avoid room collisions.
						for(@r2 = @r, @r2 < @r + @roomLength + 2, @r2++) {
							if(@r2 + 1 >= @length) {
								@roomLength = @r2 - @r - 2;
								break();
							} else if(@roomMap[@c][@r2] != -1) {
								@roomLength = @r2 - @r - 2;
								break();
							}
							for(@c2 = @c + 1, @c2 < @c + @roomWidth + 2, @c2++) {
								if(@c2 + 1 >= @width) {
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
						} else if(@floorData['attic'] && @height >= 7 && @roomWidth > 2 && @roomLength > 2 && srand(@random) < @floorData['attic']) {
							@type = 'ATTIC';
						} else if(@floorData['balcony'] && @roomWidth > 3 && @roomLength > 3 && @height >= 7 && srand(@random) < @floorData['balcony']) {
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

			if(@debug) {
				msg(@attempts.' were made to create '.array_size(@rooms).' rooms.');
			}

			// Connect rooms
			@current = 0;
			@previous = 0;
			@try = array();
			@maxAttempts = array_size(@rooms) * @maxRoomSize * 4;
			@attempts = 0;
			@connected = associative_array();
			@maxRoomDistance = 0;
			@farthestRoom = null;
			@possibleDeadEnds = associative_array();
			while(@unconnected) {
				if(x_is_interrupted()) {
					remove_bar('gen'.@region);
					die('Interrupted connecting rooms: '.array_size(@unconnected).'/'.array_size(@rooms).' ... ');
				}
				@attempts++;
				if(@attempts >= @maxAttempts){
					msg('Hit room connector limit ('.@attempts.')! Rooms left: '.array_size(@unconnected).'/'.array_size(@rooms).'!');
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
				@dirs = array('north', 'south', 'east', 'west');
				foreach(@d in range(4)) {
					@dir = array_remove(@dirs, integer(srand(@random) * array_size(@dirs)));
					try {
						@cRoom = 0;
						@rRoom = 0;
						@cDoor = 0;
						@rDoor = 0;
						switch(@dir) {
							case 'north':
								@rRoom = @r - 2;
								if(@rRoom < 1) {
									continue();
								}
								@cRoom = @c + integer(srand(@random) * @roomWidth);
								@rDoor = @rRoom + 1;
								@cDoor = @cRoom;
							case 'south':
								@rRoom = @r + @roomLength + 1;
								if(@rRoom >= @length) {
									continue();
								}
								@cRoom = @c + integer(srand(@random) * @roomWidth);
								@rDoor = @rRoom - 1;
								@cDoor = @cRoom;
							case 'west':
								@cRoom = @c - 2;
								if(@cRoom < 1) {
									continue();
								}
								@rRoom = @r + integer(srand(@random) * @roomLength);
								@cDoor = @cRoom + 1;
								@rDoor = @rRoom;
							case 'east':
								@cRoom = @c + @roomWidth + 1;
								if(@cRoom >= @width) {
									continue();
								}
								@rRoom = @r + integer(srand(@random) * @roomLength);
								@cDoor = @cRoom - 1;
								@rDoor = @rRoom;
						}
						@next = @roomMap[@cRoom][@rRoom];
						if(@next != -1 && @next != @previous) {
							if(!@rooms[@next]['connected']) {
								@layoutMap[@cDoor][@rDoor] = 'door';
								@rooms[@next]['doors']++;
								@room['doors']++;
								try {
									// attempt to add a double door
									if(@room['height'] >= 5 && @rooms[@next]['height'] >= 5 && srand(@random) < 0.5) {
										if(@dir == 'north') {
											// check both rooms for space (current and next room)
											if(@roomMap[@cRoom + 1][@rRoom] == @next && @roomMap[@cRoom + 1][@rRoom + 2] == @current) {
												@layoutMap[@cDoor + 1][@rDoor] = 'door';
											} else if(@roomMap[@cRoom - 1][@rRoom] == @next && @roomMap[@cRoom - 1][@rRoom + 2] == @current) {
												@layoutMap[@cDoor - 1][@rDoor] = 'door';
											}
										} else if(@dir == 'south') {
											if(@roomMap[@cRoom + 1][@rRoom] == @next && @roomMap[@cRoom + 1][@rRoom + 2] == @current) {
												@layoutMap[@cDoor + 1][@rDoor] = 'door';
											} else if(@roomMap[@cRoom - 1][@rRoom] == @next && @roomMap[@cRoom - 1][@rRoom - 2] == @current) {
												@layoutMap[@cDoor - 1][@rDoor] = 'door';
											}
										} else if(@dir == 'east') {
											if(@roomMap[@cRoom][@rRoom + 1] == @next && @roomMap[@cRoom - 2][@rRoom + 1] == @current) {
												@layoutMap[@cDoor][@rDoor + 1] = 'door';
											} else if(@roomMap[@cRoom][@rRoom - 1] == @next && @roomMap[@cRoom - 2][@rRoom - 1] == @current) {
												@layoutMap[@cDoor][@rDoor - 1] = 'door';
											}
										} else { // west
											if(@roomMap[@cRoom][@rRoom + 1] == @next && @roomMap[@cRoom + 2][@rRoom + 1] == @current) {
												@layoutMap[@cDoor][@rDoor + 1] = 'door';
											} else if(@roomMap[@cRoom][@rRoom - 1] == @next && @roomMap[@cRoom + 2][@rRoom - 1] == @current) {
												@layoutMap[@cDoor][@rDoor - 1] = 'door';
											}
										}
									}
								} catch(IndexOverflowException @ignore) {}
								@previous = @current;
								@current = @next;
								@success = true;
								@try = array();
								break();
							} else if((@rooms[@next]['doors'] == 2 || @rooms[@current]['doors'] == 2) && srand(@random) < @extraDoorChance) {
								@layoutMap[@cDoor][@rDoor] = 'door';
								@rooms[@next]['doors']++;
								@room['doors']++;
							}
						}
					} catch(IndexOverflowException @ignore) {}
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
						// go back one if we have not already
						@current = @previous;
					}
				}
			}

			if(@debug) {
				msg(@attempts.' / '.@maxAttempts.' were made to connect '.array_size(@rooms).' rooms.');
			}

			// Mark special rooms
			if(@floorData['treasureRoom']) {
				@treasureRoom = -1;
				@connectionFailures = -1;
				foreach(@n: @v in @possibleDeadEnds){
					@room = @rooms[@n];
					if(@n != @farthestRoom && @room['doors'] == 1 && @v > @connectionFailures
					&& @room['width'] > 2 && @room['length'] > 2) {
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
			@materials = @floorData;
			for(@chunkZ = 0, @chunkZ < @chunkLength, @chunkZ++) {
				for(@chunkX = 0, @chunkX < @chunkWidth, @chunkX++) {
					@chunk = array();
					for(@z = 0, @z < 16, @z++) {
						for(@x = 0, @x < 16, @x++) {
							@r = (@chunkZ * 16 + @z - @chunkOffsetZ);
							@c = (@chunkX * 16 + @x - @chunkOffsetX);
							if(@r < 0 || @c < 0 || @r >= @length || @c >= @width) {
								continue();
							}

							@groundY = @regionMinY + @floor * (@maxRoomHeight + 4);
							@column = @layoutMap[@c][@r];
							@roomHeight = @heightMap[@c][@r];
							@roomId = @roomMap[@c][@r];
							@room = if(@roomId != -1, @rooms[@roomId], null);
							@loc = array(
								(@chunkMinX + @chunkX) * 16 + @x,
								@groundY,
								(@chunkMinZ + @chunkZ) * 16 + @z,
								@world
							);

							// Bedrock divider
							_add_to_chunk(@chunk, @loc, @materials['divider']);

							// Floor
							@loc[1] += 1;
							@roomType = if(@room, @room['type'], null);
							if(@roomType == 'FIRE_FLOOR' && @column != 'column') {
								_add_to_chunk(@chunk, @loc, 'dispenser[facing=up]');
							} else if(@roomType == 'LAVA_PIT' && @column != 'column') {
								if(!_direction_of_solid(@layoutMap, @c, @r) || srand(@random) < 0.6) {
									_add_to_chunk(@chunk, @loc, 'lava');
								} else {
									_add_to_chunk(@chunk, @loc, @materials['floor']);
								}
							} else if(@roomType == 'WATER_PIT' && @column != 'column') {
								if(!_direction_of_solid(@layoutMap, @c, @r) || srand(@random) < 0.7) {
									_add_to_chunk(@chunk, @loc, 'water');
								} else {
									_add_to_chunk(@chunk, @loc, @materials['floor']);
								}
							} else if(@roomType == 'PIT' && @column != 'column') {
								if(!_direction_of_solid(@layoutMap, @c, @r) || srand(@random) < 0.55) {
									@holeDepth = @maxRoomHeight;
									while(@holeDepth-- > 0) {
										_add_to_chunk(@chunk, location_shift(@loc, 'down', @holeDepth), 'air');
									}
								} else {
									_add_to_chunk(@chunk, @loc, @materials['floor']);
								}
							} else if(@column == 'wall') {
								_add_to_chunk(@chunk, @loc, @materials['wall']);
							} else if(@column == 'empty') {
								_add_to_chunk(@chunk, @loc, @materials['divider']);
							} else {
								// different rooms, different floors
								@floorMat = @materials['floor'];
								if(is_array(@floorMat) && @debug) {
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
							@columnRandom = srand(@random);
							for(@y = @groundY + 2, @y < @ceilingY, @y++) {
								@loc[1] = @y;
								@doorAdjacent = _adjacent_equals(@layoutMap, @c, @r, 'door');
								switch(@column) {
									case 'window':
										if(@y < @ceilingY - @roomHeight + 3
										&& @y > @ceilingY - @roomHeight) {
											_add_to_chunk(@chunk, @loc, @materials['window']);
										} else {
											_add_to_chunk(@chunk, @loc, @materials['wall']);
										}

									case 'wall':
									case 'door':
										if(@column == 'door' && @y < @ceilingY - @roomHeight + 2) {
											if(string_ends_with(@materials['door'], 'door')) {
												@lower = @y < @ceilingY - @roomHeight + 1;
												@north = @roomMap[@c][@r - 1];
												@south = array_get(@roomMap[@c], @r + 1, 0); // special case for dungeon entrance
												@west = @roomMap[@c - 1][@r];
												@east = @roomMap[@c + 1][@r];
												@count = array_size(@chunk);
												if(!@doorAdjacent) {
													if(@north % 6 == 0) {
														@half = if(@lower, 'half=lower,', 'half=upper,');
														_add_to_chunk(@chunk, @loc, @materials['door'].'[facing=south,'.@half.'hinge=left]');
													} else if(@south % 6 == 0) {
														@half = if(@lower, 'half=lower,', 'half=upper,');
														_add_to_chunk(@chunk, @loc, @materials['door'].'[facing=north,'.@half.'hinge=left]');
													} else if(@west % 6 == 0) {
														@half = if(@lower, 'half=lower,', 'half=upper,');
														_add_to_chunk(@chunk, @loc, @materials['door'].'[facing=east,'.@half.'hinge=left]');
													} else if(@east % 6 == 0) {
														@half = if(@lower, 'half=lower,', 'half=upper,');
														_add_to_chunk(@chunk, @loc, @materials['door'].'[facing=west,'.@half.'hinge=left]');
													}
												}
												if(@count == array_size(@chunk)) {
													_add_to_chunk(@chunk, @loc, @materials['room']);
												}
											} else {
												_add_to_chunk(@chunk, @loc, @materials['door']);
											}
										} else if(@column == 'door' && @y == @ceilingY - @roomHeight + 2
										&& (!string_ends_with(@materials['door'], 'door') || @doorAdjacent)) {
											_add_to_chunk(@chunk, @loc, @materials['room']);
										} else if(array_index_exists(@materials, 'doorFrame')
										&& (@column == 'door' || @doorAdjacent)
										&& @y <= @ceilingY - @roomHeight + if((!string_ends_with(@materials['door'], 'door') || @doorAdjacent) && @column == 'door', 3, 2)) {
											_add_to_chunk(@chunk, @loc, @materials['doorFrame']);
										} else if(array_index_exists(@materials, 'windowFrame')
										&& _adjacent_equals(@layoutMap, @c, @r, 'window')
										&& @y < @ceilingY - @roomHeight + 3 && @y > @ceilingY - @roomHeight) {
											_add_to_chunk(@chunk, @loc, @materials['windowFrame']);
										} else {
											@wallMaterial = @materials['wall'];
											// tree log walls need special handling to look good
											if(is_array(@wallMaterial) && string_ends_with(@wallMaterial[0], 'log')) {
												if(@columnRandom < 0.6) {
													@wallMaterial = @wallMaterial[0];
												} else {
													@wallMaterial = @wallMaterial[1];
												}
											}
											_add_to_chunk(@chunk, @loc, @wallMaterial);
										}

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
												&& @columnRandom < 0.2
												&& (@c + (@r + 1) * @width) % 3 == 0) {
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
												if(@y == @ceilingY - @roomHeight + @room['midheight'] && srand(@random) > 0.1) {
													_add_to_chunk(@chunk, @loc, @materials['floor']);
													continue();
												}
											case 'BALCONY':
												@d = @roomId % 4;
												if(@y == @ceilingY - @roomHeight + @room['midheight']
												&& (@d == 0 && @c < @room['c1'] + @room['width'] / 2
												|| @d == 1 && @c > @room['c1'] + @room['width'] / 2
												|| @d == 2 && @r < @room['r1'] + @room['length'] / 2
												|| @d == 3 && @r > @room['r1'] + @room['length'] / 2)) {
													_add_to_chunk(@chunk, @loc, @materials['floor'][0]);
													continue();
												} else if(@y <= @ceilingY - @roomHeight + @room['midheight']
												&& (@d == 0 && @c == ceil(@room['c1'] + @room['width'] / 2) && @r == @room['r1']
												|| @d == 1 && @c == floor(@room['c1'] + @room['width'] / 2) && @r == @room['r1']
												|| @d == 2 && @r == ceil(@room['r1'] + @room['length'] / 2) && @c == @room['c1']
												|| @d == 3 && @r == floor(@room['r1'] + @room['length'] / 2) && @c == @room['c1'])) {
													@dir = 'east';
													if(@d == 1) {
														@dir = 'west';
													} else if(@d == 2) {
														@dir = 'south';
													} else if(@d == 3) {
														@dir = 'north';
													}
													_add_to_chunk(@chunk, @loc, 'ladder[facing='.@dir.']');
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

									case 'column':
										_add_to_chunk(@chunk, @loc, @materials['column']);

									default:
										_add_to_chunk(@chunk, @loc, @materials['empty']);
								}
							}

							if(@roof) {
								// Ceiling
								@loc[1] += 1;
								if(@column == 'room') {
									_add_to_chunk(@chunk, @loc, @materials['ceiling']);
								} else {
									_add_to_chunk(@chunk, @loc, @materials['divider']);
								}

								// Bedrock floor divider
								while(@loc[1] < @y + @maxRoomHeight - @roomHeight + 1) {
									@loc[1] += 1;
									if(@column == 'room') {
										_add_to_chunk(@chunk, @loc, @materials['empty']);
									} else {
										_add_to_chunk(@chunk, @loc, @materials['divider']);
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
			@chestArray = array();
			foreach(@i: @room in @rooms) {
				if(!@room['connected']) {
					continue();
				}

				@roomType = @room['type'];
				@roomWidth = @room['width'];
				@roomLength = @room['length'];
				@minWidth = min(@roomWidth, @roomLength);
				@roomHeight = @room['height'];
				@roomX = @regionMinX + @room['c1'];
				@roomY = @regionMinY + (@floor * (@maxRoomHeight + 4)) + 2;
				@roomZ = @regionMinZ + @room['r1'];

				// We need to create spawns after all blocks are set to ensure clearance.
				@createSpawns = closure(){
					if(@spawnCount > 0) {
						@count = @spawnCount;
						@attempts = @spawnCount * 10;
						while(@attempts-- > 0 && @count > 0) {
							@loc = array(
								@roomX + integer(srand(@random) * @roomWidth) + 0.5,
								@roomY + if(@roomType == 'ATTIC', @room['midheight'] + 1, 0),
								@roomZ + integer(srand(@random) * @roomLength) + 0.5,
								@world,
								if(@roomType == 'ATTIC', 0, @room['doors']), // use this for sorting, lower being more isolated a room
								@room['connected'] // distance to start
							);
							if(equals_ic(@materials['room'], get_block(@loc))) {
								if(string_ends_with(@roomType, 'PIT')) {
									set_blockdata_string(location_shift(@loc, 'down'), array_get_rand(@materials['floor']), false);
								}
								@count--;
								@spawns[@floor][] = @loc;
							}
						}
					}
				}

				if(@roomLength == 1 || @roomWidth == 1) {
					if(@room['doors'] == 1) {
						// only create spawns if it is a dead end hallway
						queue_push(@createSpawns, 'generator');
					}
					continue();
				} else if(string_ends_with(@roomType, 'PIT')) {
					// Still want to create spawns, but conditions are poor for other blocks and traps
					queue_push(@createSpawns, 'generator');
					continue();
				}

				queue_push(closure(){
					sk_pos1(player(), array(@roomX, @roomY, @roomZ));
					sk_pos2(player(), array(@roomX + @roomWidth, @roomY + @roomHeight, @roomZ + @roomLength));

					@spawner = false;
					if(@roomType == 'FIRE_FLOOR') {
						@y = @roomY - 1;
						for(@x = @roomX, @x < @roomX + @roomWidth, @x++) {
							for(@z = @roomZ, @z < @roomZ + @roomLength, @z++) {
								try(set_inventory(array(@x, @y, @z, @world), array(0: array(
									name: 'FLINT_AND_STEEL'
								))));
							}
						}
					} else if(@roomWidth > 2 && @roomLength > 2) {
						// can place a door blocking block in the room
						if(@room['connected'] > 2 && @mobTypes && @roomType != 'TREASURE' && srand(@random) < @floorData['spawnerChance']) {
							@loc = array(
								@roomX + 1 + integer(srand(@random) * (@roomWidth - 2)),
								@roomY + if(@roomType == 'ATTIC' && srand(@random) > 0.67, @room['midheight'] + 1, 0),
								@roomZ + 1 + integer(srand(@random) * (@roomLength - 2)),
								@world
							);
							@spawner = true;
							set_block(@loc, 'SPAWNER', false);
							@rand = integer(srand(@random) * array_size(@mobTypes));
							@mob = array_get(@mobTypes, @rand, 'ZOMBIE');
							set_spawner_type(@loc, @mob);
						} else if(@floorData['campfireChance'] && srand(@random) < @floorData['campfireChance']) {
							@attempts = 10;
							while(@attempts-- > 0) {
								@loc = array(
									@roomX + 1 + integer(srand(@random) * (@roomWidth - 2)),
									@roomY + if(@roomType == 'ATTIC' && srand(@random) > 0.67, @room['midheight'] + 1, 0),
									@roomZ + 1 + integer(srand(@random) * (@roomLength - 2)),
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

					if(@roomType == 'TREASURE' || (@roomWidth > 2 && @roomLength > 2 && (@chestCount > 0 || @barrelCount > 0))) {
						@chests = @chestCount;
						@barrels = @barrelCount;
						if(@roomType == 'TREASURE') {
							@chests = 0;
							@barrels = 0;
						} else {
							if(is_double(@chests)) {
								@chests = integer(round(@minWidth * srand(@random) * @chests)) * if(@i == 0 && @floor == 0, 2, 1);
							}
							if(is_double(@barrels)) {
								@barrels = integer(round(@minWidth * srand(@random) * @barrels)) * if(@i == 0 && @floor == 0, 2, 1);
							}
						}
						@bonus = if(@roomType == 'TREASURE', 4, 1);
						@chestHeight = 0;
						if(@roomType == 'ATTIC' && srand(@random) > 0.33) {
							@chestHeight = @room['midheight'] + 1;
						} else if(@roomType == 'TREASURE') {
							@chestHeight = 1;
						}
						@attempts = 10;
						while(@attempts-- > 0 && @chests > 0) {
							@wallSide = _get_direction(@random);
							@loc = array(
								@roomX,
								@roomY + @chestHeight,
								@roomZ,
								@world
							);
							if(@roomType == 'BALCONY') {
								@d = @i % 4;
								if(@d == 0 && @wallSide == 'west'
								|| @d == 1 && @wallSide == 'east'
								|| @d == 2 && @wallSide == 'north'
								|| @d == 3 && @wallSide == 'south') {
									@loc[1] += @room['midheight'] + 1;
								}
							}
							if(@wallSide == 'north') {
								@loc[0] += 1 + integer(srand(@random) * (@roomWidth - 2));
							} else if(@wallSide == 'south') {
								@loc[0] += 1 + integer(srand(@random) * (@roomWidth - 2));
								@loc[2] += @roomLength - 1;
							} else if(@wallSide == 'east') {
								@loc[0] += @roomWidth - 1;
								@loc[2] += 1 + integer(srand(@random) * (@roomLength - 2));
							} else if(@wallSide == 'west') {
								@loc[2] += 1 + integer(srand(@random) * (@roomLength - 2));
							}
							if(equals_ic(@materials['room'], get_block(@loc))
							&& array_contains_ic(@materials['wall'], get_block(location_shift(@loc, @wallSide)))) {
								@inv = _get_chest_loot(@floor, @random, @bonus);
								set_blockdata_string(@loc, 'chest[facing='._opposite_direction(@wallSide).if(@materials['room'] == 'water', ',waterlogged=true').']', false);
								@chestArray[] = @loc;
								@chests--;
								if(array_size(@inv) > get_inventory_size(@loc)) {
									@inv = @inv[cslice(0, get_inventory_size(@loc))];
								}
								try(set_inventory(@loc, @inv));
							}
						}
						if(@roomType == 'TREASURE') {
							@attempts = 8;
							while(@attempts-- > 0) {
								@loc = array(
									@roomX + 1 + integer(srand(@random) * (@roomWidth - 2)),
									@roomY + @chestHeight,
									@roomZ + 1 + integer(srand(@random) * (@roomLength - 2)),
									@world
								);
								if(equals_ic(@materials['room'], get_block(@loc))) {
									@podium = array_get(array('OCHRE_FROGLIGHT', 'VERDANT_FROGLIGHT', 'PEARLESCENT_FROGLIGHT'), min(2, integer(@floor / 3)));
									@double = false;
									if(equals_ic(@materials['room'], get_block(location_shift(@loc, 'west')))) {
										@double = true;
										@rightSide = location_shift(@loc, 'west');
										set_blockdata_string(@rightSide, 'chest[facing=south'.if(@materials['room'] == 'water', ',waterlogged=true').',type=right]', false);
										set_block(location_shift(@rightSide, 'down'), @podium, false);
									}
									set_blockdata_string(@loc, 'chest[facing=south'.if(@materials['room'] == 'water', ',waterlogged=true').if(@double, ',type=left').']', false);
									set_block(location_shift(@loc, 'down'), @podium, false);
									if(@chestArray) { // only lock this chest if we have a previous chest to add a key to
										try {
											add_to_inventory(_array_get_srand(@random, @chestArray),
													array(name: 'TRIPWIRE_HOOK', meta: array(display: 'Key'.(@floor + 1))));
											set_block_lock(@loc, 'Key'.(@floor + 1));
										} catch(Exception @ignore) {
											// just do not lock it
										}
									}
									@inv = _get_chest_loot(@floor, @random, @bonus);
									@chests--;
									if(array_size(@inv) > get_inventory_size(@loc)) {
										@inv = @inv[cslice(0, get_inventory_size(@loc))];
									}
									try(set_inventory(@loc, @inv));
									break();
								}
							}
						}
						@attempts = 8;
						while(@attempts-- > 0 && @barrels > 0) {
							@loc = array(
								@roomX + 1 + integer(srand(@random) * (@roomWidth - 2)),
								@roomY + @chestHeight,
								@roomZ + 1 + integer(srand(@random) * (@roomLength - 2)),
								@world
							);
							if(equals_ic(@materials['room'], get_block(@loc))) {
								@inv = _get_barrel_loot(@floor, @random, @bonus);
								set_blockdata_string(@loc, 'barrel[facing='._get_direction(@random, array('north', 'south', 'east', 'west', 'up')).']', false);
								@barrels--;
								if(array_size(@inv) > get_inventory_size(@loc)) {
									@inv = @inv[cslice(0, get_inventory_size(@loc))];
								}
								set_inventory(@loc, @inv);
							}
						}
					}

					if(@materials['utility'] && @roomWidth > 2 && @roomLength > 2) {
						if(integer(srand(@random) * 2) == 1) {
							@loc = array(
								@roomX + 1 + integer(srand(@random) * (@roomWidth - 2)),
								@roomY + if(@roomType == 'ATTIC' && srand(@random) > 0.5, @room['midheight'] + 1, 0),
								@roomZ + 1 + integer(srand(@random) * (@roomLength - 2)),
								@world
							);
							if(equals_ic(@materials['room'], get_block(@loc))) {
								set_blockdata_string(@loc, _array_get_srand(@random, @materials['utility']), false);
							}
						}
					}

					if(array_index_exists(@materials, 'randomblocks') && @roomWidth > 2 && @roomLength > 2 && @i != 0) {
						@decorations = integer(srand(@random) * max(@roomLength, @roomWidth));
						while(@decorations-- > 0) {
							@loc = array(
								@roomX + 1 + integer(srand(@random) * (@roomWidth - 2)),
								@roomY + if(@roomType == 'ATTIC' && srand(@random) > 0.5, @room['midheight'] + 1, 0),
								@roomZ + 1 + integer(srand(@random) * (@roomLength - 2)),
								@world
							);
							if(equals_ic(@materials['room'], get_block(@loc))) {
								@blockType = _array_get_srand(@random, @materials['randomblocks']);
								set_blockdata_string(@loc, @blockType, false);
								if(!string_contains(@blockType, '[') && material_info(@blockType, 'isSolid') && srand(@random) > 0.5) {
									set_blockdata_string(location_shift(@loc, 'up'), @blockType, false);
								}
							}
						}
					}

					if(@roomType == 'ATTIC') {
						@vines = integer(@minWidth / 2);
						do {
							@loc = null;
							@block = null;
							@length = null;
							if(array_index_exists(@materials, 'vines')) {
								@block = @materials['vines'];
								@length = @room['height'];
							} else {
								@dirs = array_rand(array('east', 'west', 'north', 'south'), rand(1, 4), false);
								@block = array(block: 'vine');
								foreach(@dir in @dirs) {
									@block[@dir] = true;
								}
								@length = @room['midheight'] + 1;
							}
							@attempts = 5;
							do {
								@loc = array(
									@roomX + 1 + integer(srand(@random) * (@roomWidth - 2)),
									@roomY + @length,
									@roomZ + 1 + integer(srand(@random) * (@roomLength - 2)),
									@world
								);
							} while(!equals_ic(@materials['room'], get_block(@loc)) && --@attempts > 0);

							while(@length-- > 0) {
								@loc[1]--;
								set_blockdata(@loc, @block, @block == 'weeping_vines');
							}
							@vines--;
						} while(@vines > 0 || srand(@random) > 0.45);
					}

					if(@i == @farthestRoom && @floorData['boss']) {
						@tries = 10;
						while(@tries-- > 0) {
							@loc = array(
								@roomX + integer(srand(@random) * @roomWidth) + 0.5,
								@roomY,
								@roomZ + integer(srand(@random) * @roomLength) + 0.5,
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

					if(@room['connected'] > 2 && @floorData['trap'] && @roomType != 'FIRE_FLOOR') {
						@traps = integer(srand(@random) * max(@roomLength, @roomWidth));
						while(@traps-- > 0) {
							@type = split('_', _array_get_srand(@random, @materials['trap']));
							@trigger = @type[0];
							@effect = @type[1];
							@data = if(array_size(@type) >= 3, array_implode(@type[2..], '_'), null);
							@facing = 'up';
							@loc = null;
							if(@trigger == 'chest' || @effect == 'cactus') {
								@loc = array(
									@roomX + 1 + integer(srand(@random) * (@roomWidth - 2)),
									@roomY,
									@roomZ + 1 + integer(srand(@random) * (@roomLength - 2)),
									@world
								);
							} else {
								@loc = array(
									@roomX + integer(srand(@random) * @roomWidth),
									@roomY,
									@roomZ + integer(srand(@random) * @roomLength),
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
									@traps = 0; // so we do not block the door
								case 'vines':
									if(@roomType == 'ATTIC' || @roomType == 'BALCONY') {
										continue();
									}
									if(!@spawner) {
										set_block(@loc, 'TRIPWIRE', false);
										@loc = location_shift(@loc, 'up');
									}
									while(@loc[1] < @roomY + @roomHeight && !material_info(get_block(@loc), 'isOccluding')) {
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
									if(@roomWidth > 2 && @roomWidth < 12) {
										@positive = 'east';
										@negative = 'west';
									} else if(@roomLength > 2 && @roomLength < 12) {
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
										@dispenserLoc = location_shift(@loc, @dir);
										set_blockdata_string(@dispenserLoc, 'dispenser[facing=up]', false);
										set_inventory(@dispenserLoc, array(0: array(
											name: 'FLINT_AND_STEEL', meta: array(damage: 61)
										)));
										set_block_lock(@dispenserLoc, 'Key'.(@floor + 1));
									}
								case 'cactus':
									set_block(location_shift(@loc, 'down'), 'RED_SAND', false);
									@valid = true;
									foreach(@dir in array('north', 'south', 'east', 'west')) {
										if(material_info(get_block(location_shift(@loc, @dir)), 'isSolid')) {
											@valid = false;
										}
									}
									if(@valid) {
										set_block(@loc, 'CACTUS', false);
										set_block(location_shift(@loc, 'up'), 'CACTUS', false);
									}
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
									set_block_lock(@loc, 'Key'.(@floor + 1));
								case 'potion':
									if(@spawner) {
										continue();
									}
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
									set_block_lock(@loc, 'Key'.(@floor + 1));
								case 'arrow':
									set_blockdata_string(@loc, 'dispenser[facing='.@facing.']', false);
									set_inventory(@loc, array(0: array(name: 'TIPPED_ARROW', qty: 3, meta: array(base: array(type: 'INSTANT_DAMAGE', upgraded: true, extended: false)))));
									set_block_lock(@loc, 'Key'.(@floor + 1));
							}
							if(@trigger == 'plate') {
								// needs to be after dispenser
								set_block(location_shift(@loc, 'up'), 'STONE_PRESSURE_PLATE', false);
							}
						}
					}

					execute(@createSpawns);
				}, 'generator');

				
				if(is_array(@materials['floor']) && array_contains(@materials['floor'], 'grass_block') || @materials['floor'] === 'grass_block') {
					queue_push(closure(){
						@loc = array(
							@roomX + 1 + integer(srand(@random) * (@roomWidth - 2)),
							@roomY - 1,
							@roomZ  + 1 + integer(srand(@random) * (@roomLength - 2)),
							@world
						);
						bone_meal_block(@loc);
					}, 'generator');
				}
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
							set_block(@loc, 'REINFORCED_DEEPSLATE', false);
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
			sk_pos1(player(), null);
			sk_pos2(player(), null);

			if(is_closure(@callback)) {
				// find an end col and row that is not in a column
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
