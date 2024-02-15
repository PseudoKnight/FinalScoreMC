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
		minRoomSize: 3,
		maxRoomSize: 21,
		minRoomHeight: 3,
		maxRoomHeight: 3,

		// variability on room features
		chestCount: 0,
		barrelCount: 0,
		spawnerChance: 0.7,
		extraDoorChance: 0.0,
		campfireChance: 0.0,
		wallTorchChance: 0.0,
		randomBlockChance: 0.05,
		attic: 0.0, // 0.3 is a good value
		balcony: 0.0, // 0.3
		lavaPit: 0.0, // 0.06
		waterPit: 0.0, // 0.06
		pit: 0.0, // 0.06
		fireFloor: 0.0, // 0.06
		rugs: 0.0,
		spawnCount: 1,
		title: '',

		// toggleable features
		roof: true,
		bed: false,
		treasureRoom: false,
		randomRoofHeight: false,
		tallDoors: false,
		ascending: false,

		// materials (single or multiple)
		divider: 'bedrock',
		empty: 'reinforced_deepslate',
		window: '',
		windowFrame: '',
		doorFrame: '',
		ceiling: 'stone',
		column: 'stone',
		rug: 'red_carpet',

		// single materials
		door: 'air',
		room: 'air',
		edge: 'air',
		vine: '',
		overhead: '',

		// multiple materials
		wall: array('stone'),
		floor: array('stone'),
		randomblocks: array(),
		utility: array(),

		// specially formatted string arrays: trigger_effect[_data]
		trap: array(),

		// entity types
		spawner: array(),

		// custom entities
		boss: '',
	), @options['default']);

	@debugMaterials = null;
	if(@debug) {
		@debugMaterials = array('black_terracotta', 'lime_terracotta', 'red_terracotta', 'blue_terracotta', 'green_terracotta', 'yellow_terracotta',
				'magenta_terracotta', 'orange_terracotta', 'light_blue_terracotta', 'pink_terracotta', 'light_gray_terracotta', 'gray_terracotta',
				'cyan_terracotta', 'purple_terracotta', 'brown_terracotta', 'white_terracotta');
	}

	// process floors config to a useful format and verify values
	@dungeonEntrance = array_get(@options, 'dungeonEntrance', '');


	@dataValidator = iclosure(@data) {
		// All must be positive.
		// Doubles must be within 0.0 - 1.0 inclusive.
		foreach(@key: @value in @data) {
			if(is_number(@value)) {
				if(@value < 0) {
					console(@key.' must be positive.');
					return();
				} else if(is_double(@value) && @value > 1.0) {
					console(@key.' must be 0.0 - 1.0.');
					return();
				}
			}
		}

		// Ensure these values are arrays
		foreach(@key in array('wall', 'utility', 'trap', 'spawner', 'randomBlocks', 'floor')) {
			if(array_index_exists(@data, @key)) {
				if(is_string(@data[@key])) {
					if(@data[@key]) {
						@data[@key] = array(@data[@key]);
					} else {
						@data[@key] = array();
					}
				}
			}
		}
	}
	foreach(@floorIndex: @floorData in @options['floors']) {
		@floorData = array_merge(@defaults, @floorData);
		@dataValidator(@floorData);
		@options['floors'][@floorIndex] = @floorData;
	}
	if(array_index_exists(@options, 'rooms')) {
		foreach(@roomName: @roomData in @options['rooms']) {
			@dataValidator(@roomData);
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
	if(array_contains(get_bars(), 'gen'.@region)) {
		remove_bar('gen'.@region);
	}
	create_bar('gen'.@region, array(title: 'Generating '.@dungeonType.if(array_size(@options['floors']) > 1, ' floor 1'), percent: 0.0));
	foreach(@p in all_players(@world)) {
		bar_add_player('gen'.@region, @p);
	}
	_remove_region_entities(@region, array(), @world);

	@cleanUp = closure(@randomResource = null){
		if(!is_null(@randomResource)) {
			res_free_resource(@randomResource);
		}
		queue_push(closure(){
			remove_bar('gen'.@region);
			if(@debug) {
				sk_pos1(player(), null);
				sk_pos2(player(), null);
			}
		}, 'generator');
	}

	// Dungeon planning (off the server thread)
	x_new_thread('DungeonPlanner', closure(){
		@rooms = null;
		@farthestRoom = null;
		@exitRoom = null;
		@spawns = array();

		// Place entrance room
		@width = @regionWidth;
		@length = @regionLength;
		@c = integer(@width / 2 - 4);
		@r = if(@dungeonEntrance, @length - 8, integer(@length / 2 - 4));

		@startingRoom = array(
			r1: @r,
			c1: @c,
			length: 6,
			width: 6,
			depth: 0,
			doors: 0,
			floor: if(@options['floors'][0]['ascending'], 1, 0),
			height: @options['floors'][0]['maxRoomHeight'],
			midheight: 3 + @options['floors'][0]['maxRoomHeight'] - 7,
			type: null,
			shape: 'normal',
		);

		// Need these outside the foreach scope
		@floor = null;
		@maxRoomHeight = null;
		@layoutMap = null;

		foreach(@floor in range(if(@testFloor > -1, @testFloor, 0), if(@testFloor > -1, @testFloor + 1, array_size(@options['floors'])))) {
			@random = res_create_resource('RANDOM', @seed);

			@floorData = @options['floors'][@floor];
			@maxRoomSize = min(@floorData['maxRoomSize'], @length - 4, @width - 4);
			@minRoomSize = min(@floorData['minRoomSize'], @maxRoomSize);
			@maxRoomHeight = @floorData['maxRoomHeight'];
			@minRoomHeight = min(@floorData['minRoomHeight'], @maxRoomHeight);
			@groundY = @regionMinY + @floor * (@maxRoomHeight + 4);
			@roof = @floorData['roof'];
			@extraDoorChance = @floorData['extraDoorChance'];

			@width = @regionWidth;
			@length = @regionLength;

			queue_push(iclosure(
				@bar = 'gen'.@region,
				@title = 'Planning '.@dungeonType.' floor '.(@floor + 1),
				@pos1 = array(@regionMinX, @groundY, @regionMinZ),
				@pos2 = array(@regionMaxX, @groundY + @maxRoomHeight, @regionMaxZ),
				@isDebugMode = @debug,
			){
				update_bar(@bar, @title);
				if(@isDebugMode) {
					sk_pos1(player(), @pos1);
					sk_pos2(player(), @pos2);
				}
			}, 'generator');

			@spawns[@floor] = array();
			// Define grid
			@layoutMap = array();
			@roomMap = array();
			@roomHeightMap = array();
			@floorHeightMap = array();
			for(@c = 0, @c < @width, @c++) {
				@layoutMap[@c] = array();
				@roomMap[@c] = array();
				@roomHeightMap[@c] = array();
				@floorHeightMap[@c] = array();
				for(@r = 0, @r < @length, @r++) {
					@layoutMap[@c][@r] = if(@r == 0 || @c == 0 || @r == @length - 1 || @c == @length - 1, 'divider', 'empty');
					@roomMap[@c][@r] = -1;
					@roomHeightMap[@c][@r] = @maxRoomHeight;
					@floorHeightMap[@c][@r] = 0;
				}
			}

			// Define rooms
			if(@exitRoom != null) {
				@startingRoom = array(
					r1: @exitRoom['r1'],
					c1: @exitRoom['c1'],
					length: @exitRoom['length'],
					width: @exitRoom['width'],
					depth: 0,
					doors: 0,
					floor: if(@floorData['ascending'], 1, 0),
					height: @floorData['maxRoomHeight'],
					midheight: 3 + @floorData['maxRoomHeight'] - 7,
					type: null,
					shape: 'normal',
				);
			} else if(@dungeonEntrance) {
				@layoutMap[integer(@width / 2) - 1][@length - 2] = 'door';
				@layoutMap[integer(@width / 2) - 2][@length - 2] = 'door';
				@layoutMap[integer(@width / 2) - 1][@length - 1] = 'door';
				@layoutMap[integer(@width / 2) - 2][@length - 1] = 'door';
				@layoutMap[integer(@width / 2) - 3][@length - 1] = 'wall';
				@layoutMap[integer(@width / 2)][@length - 1] = 'wall';
			}
			@rooms = array(@startingRoom);
			@r = @startingRoom['r1'];
			@c = @startingRoom['c1'];

			// Place rooms
			// Split around starting room
			if(@r > @minRoomSize + 4) {
				@rooms[] = array( // northeast on north face
					r1: 2,
					c1: @c,
					length: @r - 5,
					width: @width - @c - 3,
				);
			}
			if(@c + @startingRoom['width'] + 3 + @minRoomSize < @width) {
				@rooms[] = array( // southeast on east face
					r1: @r,
					c1: @c + @startingRoom['width'] + 3,
					length: @length - @r - 2,
					width: @width - @c - @startingRoom['width'] - 6,
				);
			}
			if(@r + @startingRoom['length'] + 3 + @minRoomSize < @length) {
				@rooms[] = array( // southwest on south face
					r1: @r + @startingRoom['length'] + 3,
					c1: 2,
					length: @length - @r - @startingRoom['length'] - 5,
					width: @c + @startingRoom['width'] - 2,
				);
			}
			if(@c > @minRoomSize + 4) {
				@rooms[] = array( // northwest on west face
					r1: 2,
					c1: 2,
					length: @r - 2 + @startingRoom['length'],
					width: @c - 5,
				);
			}

			// Binary Space Partitioning (BSP)
			@count = 1;
			while(@count < array_size(@rooms)) {
				if(x_is_interrupted()) {
					@cleanUp(@random);
					die('Interrupted partitioning rooms: '.@count.'/'.array_size(@rooms));
				}
				foreach(@room in @rooms) {
					if(array_index_exists(@room, 'depth')) {
						continue();
					}
					if(@room['width'] <= @maxRoomSize && @room['length'] <= @maxRoomSize && srand(@random) < 0.67) {
						// sufficiently split
						@room['depth'] = 0;
						@count++;
						continue();
					}
					@widthTooSmall = @room['width'] < @minRoomSize * 2 + 3;
					@lengthTooSmall = @room['length'] < @minRoomSize * 2 + 3;
					if(@widthTooSmall && @lengthTooSmall) {
						// can't split anymore
						@room['depth'] = 0;
						@count++;
						continue();
					}
					if(!@widthTooSmall && srand(@random) < 0.5) {
						// split on column
						@split = @minRoomSize + 1 + integer(srand(@random) * (@room['width'] - @minRoomSize * 2 - 2));
						@rooms[] = array(
							r1: @room['r1'],
							c1: @room['c1'] + @split + 2,
							length: @room['length'],
							width: @room['width'] - @split - 2,
						);
						@room['width'] = @split - 1;
					} else if(!@lengthTooSmall) {
						// split on row
						@split = @minRoomSize + 1 + integer(srand(@random) * (@room['length'] - @minRoomSize * 2 - 2));
						@rooms[] = array(
							r1: @room['r1'] + @split + 2,
							c1: @room['c1'],
							length: @room['length'] - @split - 2,
							width: @room['width'],
						);
						@room['length'] = @split - 1;
					}
				}
			}

			// Configure rooms
			@unconnected = array();
			foreach(@i: @room in @rooms) {
				@unconnected[] = @i;
				// mask roomMap
				@r = @room['r1'];
				@c = @room['c1'];
				@roomLength = @room['length'];
				@roomWidth = @room['width'];
				for(@r2 = @r - 1, @r2 <= @roomLength + @r, @r2++) {
					for(@c2 = @c - 1, @c2 <= @roomWidth + @c, @c2++) {
						@roomMap[@c2][@r2] = @i;
					}
				}

				// Room types determine material theme and other characteristics
				@roomType = '';
				@minHeight = @minRoomHeight;
				if(array_index_exists(@floorData, 'roomTypes')) {
					@rand = srand(@random);
					foreach(@id: @roomData in @floorData['roomTypes']) {
						if(@rand < @roomData['chance']) {
							@roomType = @id;
							break();
						}
						@rand -= @roomData['chance'];
					}
				}

				// Room shapes determine dominant room features
				@shape = 'normal';
				if(@floorData['rugs'] && @roomWidth == @roomLength && @roomWidth > 2 && @roomWidth < 8 && srand(@random) < @floorData['rugs']) {
					@shape = 'rug';
					@minHeight = 4;
				} else if(@floorData['attic'] && @roomWidth > 2 && @roomLength > 2 && srand(@random) < @floorData['attic']) {
					@shape = 'attic';
					@minHeight = 7;
				} else if(@floorData['balcony'] && @roomWidth > 3 && @roomLength > 3 && srand(@random) < @floorData['balcony']) {
					@shape = 'balcony';
					@minHeight = 7;
				} else if(@floorData['lavaPit'] && @roomWidth > 1 && @roomLength > 1 && srand(@random) < @floorData['lavaPit']) {
					@shape = 'lava_pit';
					@minHeight = 4;
				} else if(@floorData['waterPit'] && srand(@random) < @floorData['waterPit']) {
					@shape = 'water_pit';
				} else if(@floorData['fireFloor'] && @roomWidth > 1 && @roomLength > 1 && srand(@random) < @floorData['fireFloor']) {
					@shape = 'fire_floor';
				} else if(@floorData['pit'] && srand(@random) < @floorData['pit']) {
					@shape = 'pit';
					@minHeight = 4;
				}

				@height = @minHeight + integer(srand(@random) * (@maxRoomHeight - @minHeight + 1));

				// Save room with remaining data
				@rooms[@i] = array_merge(array(
					doors: 0,
					floor: 0,
					height: @height,
					midheight: 3 + integer(srand(@random) * (@height - 7)),
					shape: @shape,
					type: @roomType,
				), @room);
			}

			// Connect rooms
			@current = 0;
			@previous = 0;
			@try = array();
			@maxAttempts = array_size(@rooms) * 12;
			@attempts = 0;
			@connected = associative_array();
			@maxRoomDistance = 0;
			@farthestRoom = null;
			@possibleDeadEnds = associative_array();
			while(@unconnected) {
				if(x_is_interrupted()) {
					@cleanUp(@random);
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
				if(@room['depth'] == 0){
					@room['depth'] = @rooms[@previous]['depth'] + 1;
					if(@room['depth'] > @maxRoomDistance) {
						@maxRoomDistance = @room['depth'];
						@farthestRoom = @current;
					}
				}

				@roomR = @room['r1'];
				@roomC = @room['c1'];
				@roomWidth = @room['width'];
				@roomLength = @room['length'];

				@success = false;
				@dirs = array('north', 'south', 'east', 'west');
				foreach(@d in range(4)) {
					@dir = array_remove(@dirs, integer(srand(@random) * array_size(@dirs)));
					try {
						// Example for 'south' direction:
						//
						// [][][][][][] <-- walls of room included in @roomMap
						// []        []
						// []        []
						// []        []
						// []        []
						// [][][]||[][] <-- choose random inner column at positive row edge of room
						//       ||     <-- iterate row positively
						// [][][]||[][] <-- find room index in @roomMap
						// []        []
						// []    ^ Check to see if entrance is on an inner column for next room
						//
						@c = 0;
						@r = 0;
						@dist = 1;
						@next = -1;
						@hall = false;
						if(@dir == 'north' || @dir == 'south') {
							@c = @roomC + 1 + integer(srand(@random) * (@roomWidth - 2));
						} else {
							@r = @roomR + 1 + integer(srand(@random) * (@roomLength - 2));
						}
						while(++@dist <= @maxRoomSize) {
							switch(@dir) {
								case 'north':
									@r = @roomR - @dist;
								case 'south':
									@r = @roomR + @roomLength - 1 + @dist;
								case 'west':
									@c = @roomC - @dist;
								case 'east':
									@c = @roomC + @roomWidth - 1 + @dist;
							}
							@hall = @layoutMap[@c][@r] == 'hall';
							if(@hall || @next != -1 || @c < 2 || @r < 2) {
								break();
							}
							@next = @roomMap[@c][@r];
						}

						if(@hall || @r < 2 || @c < 2) {
							continue();
						}

						if(@next != -1 && @next != @previous
						// and inside room
						&& @c >= @rooms[@next]['c1']
						&& @c < @rooms[@next]['c1'] + @rooms[@next]['width']
						&& @r >= @rooms[@next]['r1']
						&& @r < @rooms[@next]['r1'] + @rooms[@next]['length']
						&& (@rooms[@next]['floor'] == 0
						|| @dist > abs(@rooms[@next]['floor'] - @room['floor']))) {
							if(!@rooms[@next]['depth']
							|| abs(@rooms[@next]['depth'] - @rooms[@current]['depth']) != 1 && srand(@random) < @extraDoorChance) {
								@heightMultiplier = 0;
								@distOffset = 0;
								if(@floorData['ascending']) {
									if(@rooms[@next]['floor'] == 0) {
										if(@room['floor'] > @dist - 1) {
											@distOffset = -1;
											@heightMultiplier = -1;
										} else {
											@heightMultiplier = 1;
										}
										@rooms[@next]['floor'] = @room['floor'] + (@dist - 1) * @heightMultiplier;
									} else {
										@heightMultiplier = (@rooms[@next]['floor'] - @room['floor']) / @dist;
										if(@rooms[@next]['floor'] > @room['floor']) {
											@distOffset = 1;
										}
									}
								};
								// Attempt to add a double door
								//
								// []        [] <- Both rooms must be width > 3 and height > 4
								// [][]|< |[][] <- Check towards center of room
								//     |  |    
								// [][]|  |[][]
								// []        []
								// []  ^ Check if still inside next room
								//
								@c2 = 0;
								@r2 = 0;
								@double = false;
								@roomHeight = 2 + abs(@heightMultiplier);
								if(@room['height'] > 4 && @rooms[@next]['height'] > 4) {
									if((@dir == 'north' || @dir == 'south')
									&& @room['width'] > 3 && @rooms[@next]['width'] > 3) {
										// check towards center of room
										@c2 = @c + if(@c > @roomC + @roomWidth / 2, -1, 1);
										if(@c2 >= @rooms[@next]['c1']
										&& @c2 < @rooms[@next]['c1'] + @rooms[@next]['width']) {
											@roomHeight += if(@floorData['tallDoors'], 1, 0);
											@double = true;
										}
									} else if((@dir == 'east' || @dir == 'west')
									&& @room['length'] > 3 && @rooms[@next]['length'] > 3) {
										// check towards center of room
										@r2 = @r + if(@r > @roomR + @roomLength / 2, -1, 1);
										if(@r2 >= @rooms[@next]['r1']
										&& @r2 < @rooms[@next]['r1'] + @rooms[@next]['length']) {
											@roomHeight += if(@floorData['tallDoors'], 1, 0);
											@double = true;
										}
									}
								}
								@doorDist = @dist;
								while(--@doorDist > 0) {
									@cell = if(@doorDist == 1 || @doorDist == @dist - 1, 'door', 'hall');
									@floorHeight = @room['floor'] + integer((@doorDist + @distOffset) * @heightMultiplier);
									switch(@dir) {
										case 'north':
											@r = @roomR - @doorDist;
											@layoutMap[@c][@r] = @cell;
											if(@double, @layoutMap[@c2][@r] = @cell);
											@floorHeightMap[@c][@r] = @floorHeight;
											if(@double, @floorHeightMap[@c2][@r] = @floorHeight);
											if(@cell == 'hall') {
												@roomHeightMap[@c][@r] = @roomHeight;
												if(@double, @roomHeightMap[@c2][@r] = @roomHeight);
											}
										case 'south':
											@r = @roomR + @roomLength - 1 + @doorDist;
											@layoutMap[@c][@r] = @cell;
											if(@double, @layoutMap[@c2][@r] = @cell);
											@floorHeightMap[@c][@r] = @floorHeight;
											if(@double, @floorHeightMap[@c2][@r] = @floorHeight);
											if(@cell == 'hall') {
												@roomHeightMap[@c][@r] = @roomHeight;
												if(@double, @roomHeightMap[@c2][@r] = @roomHeight);
											}
										case 'west':
											@c = @roomC - @doorDist;
											@layoutMap[@c][@r] = @cell;
											if(@double, @layoutMap[@c][@r2] = @cell);
											@floorHeightMap[@c][@r] = @floorHeight;
											if(@double, @floorHeightMap[@c][@r2] = @floorHeight);
											if(@cell == 'hall') {
												@roomHeightMap[@c][@r] = @roomHeight;
												if(@double, @roomHeightMap[@c][@r2] = @roomHeight);
											}
										case 'east':
											@c = @roomC + @roomWidth - 1 + @doorDist;
											@layoutMap[@c][@r] = @cell;
											if(@double, @layoutMap[@c][@r2] = @cell);
											@floorHeightMap[@c][@r] = @floorHeight;
											if(@double, @floorHeightMap[@c][@r2] = @floorHeight);
											if(@cell == 'hall') {
												@roomHeightMap[@c][@r] = @roomHeight;
												if(@double, @roomHeightMap[@c][@r2] = @roomHeight);
											}
									}
								}
								@rooms[@next]['doors']++;
								@room['doors']++;
								if(!@rooms[@next]['depth']) {
									@previous = @current;
									@current = @next;
									@success = true;
									@try = array();
									break();
								}
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
						} while(@limit2 > 0 && (@current == @previous || array_contains(@try, @current)))
						@try[] = @current;
					} else {
						// go back one if we have not already
						@current = @previous;
					}
				}
			}

			if(@debug) {
				msg(@attempts.' / '.@maxAttempts.' attempts were made to connect '.array_size(@rooms).' rooms.');
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
					@rooms[@treasureRoom]['shape'] = 'treasure';
				}
			}

			// Mark room layout
			foreach(@n: @room in @rooms){
				if(!@room['depth']){
					continue();
				}
				@r = @room['r1'];
				@c = @room['c1'];
				@roomWidth = @room['width'];
				@roomLength = @room['length'];
				@rowOdd = null;
				@columnOdd = null;
				@roomData = @floorData;
				if(@room['type'] && array_index_exists(@options, 'rooms') && array_index_exists(@options['rooms'], @room['type'])) {
					@roomData = array_merge(@roomData, @options['rooms'][@room['type']]);
				}
				for(@r2 = @r - 1, @r2 <= @roomLength + @r, @r2++) {
					for(@c2 = @c - 1, @c2 <= @roomWidth + @c, @c2++) {
						@roomHeightMap[@c2][@r2] = @room['height'];
						if(@floorHeightMap[@c2][@r2] == 0) {
							@floorHeightMap[@c2][@r2] = @room['floor'];
						}
						if(@r2 >= @r && @r2 < @roomLength + @r
						&& @c2 >= @c && @c2 < @roomWidth + @c) {
							if(@roomData['randomRoofHeight']) {
						 		@roomHeightMap[@c2][@r2] = @room['midheight'] + 2 + integer(srand(@random) * (@maxRoomHeight - @room['midheight'] - 2));
							}
							if(@room['shape'] == 'rug'
							|| @roomLength == 1
							|| @roomWidth == 1
							|| _adjacent_equals(@layoutMap, @c2, @r2, 'door')
							|| _adjacent_equals(@layoutMap, @c2, @r2, 'window')
							|| (!is_null(@rowOdd) && (@rowOdd != @r2 % 2 || @columnOdd != @c2 % 2))
							|| srand(@random) < 0.9
							|| @room['depth'] == 1) {
								@layoutMap[@c2][@r2] = 'room';
							} else {
								@layoutMap[@c2][@r2] = 'column';
								if(is_null(@rowOdd)) {
									@rowOdd = @r2 % 2;
									@columnOdd = @c2 % 2;
								}
							}
						} else if(@layoutMap[@c2][@r2] !== 'door') {
							if(@roomData['window']
							&& ((@r2 == @r - 1 || @r2 == @roomLength + @r) && @c2 > @c && @c2 < @roomWidth + @c - 1
							|| (@c2 == @c - 1 || @c2 == @roomWidth + @c) && @r2 > @r && @r2 < @roomLength + @r - 1)
							&& (srand(@random) > 0.9 || _adjacent_equals(@layoutMap, @c2, @r2, 'window') && srand(@random) > 0.5)
							&& !_adjacent_equals(@layoutMap, @c2, @r2, 'door')) {
								@layoutMap[@c2][@r2] = 'window';
							} else {
								@layoutMap[@c2][@r2] = 'wall';
							}
						}
					}
				}
			}

			// Build dungeon floor
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
							@floorHeight = @floorHeightMap[@c][@r];
							@roomHeight = @roomHeightMap[@c][@r];
							@roomId = @roomMap[@c][@r];
							@room = if(@roomId != -1, @rooms[@roomId], null);
							@roomType = if(@room, @room['type'], null);
							@roomShape = if(@room, @room['shape'], '');
							@doorAdjacent = _adjacent_equals(@layoutMap, @c, @r, 'door');
							@roomData = @floorData;
							if(@roomType && array_index_exists(@options, 'rooms') && array_index_exists(@options['rooms'], @roomType)) {
								@roomData = array_merge(@roomData, @options['rooms'][@roomType]);
							}
							@loc = array(
								(@chunkMinX + @chunkX) * 16 + @x,
								@groundY,
								(@chunkMinZ + @chunkZ) * 16 + @z,
								@world
							);

							if(@column == 'empty') {
								foreach(@dir in array('north', 'south', 'east', 'west')) {
									if(_get_cell(@layoutMap, @c, @r, @dir) == 'hall') {
										@floorHeight = _get_cell(@floorHeightMap, @c, @r, @dir) - 1;
										break();
									}
								}
							}

							// Bedrock divider
							_add_to_chunk(@chunk, @loc, @roomData['divider']);

							// Floor
							while(@loc[1]++ < @groundY + @floorHeight) {
								_add_to_chunk(@chunk, @loc, @roomData['divider']);
							}
							if(@roomShape == 'fire_floor' && @column == 'room') {
								_add_to_chunk(@chunk, @loc, 'dispenser[facing=up]');
							} else if(@roomShape == 'lava_pit' && @column == 'room') {
								if((!_direction_of_solid(@layoutMap, @c, @r) && srand(@random) > 0.06 || srand(@random) < 0.6)
								&& !_adjacent_equals(@layoutMap, @c, @r, 'door')) {
									_add_to_chunk(@chunk, @loc, 'lava');
								} else {
									_add_to_chunk(@chunk, @loc, @roomData['floor']);
								}
							} else if(@roomShape == 'water_pit' && @column == 'room') {
								if((!_direction_of_solid(@layoutMap, @c, @r) && srand(@random) > 0.07 || srand(@random) < 0.7)
								&& !_adjacent_equals(@layoutMap, @c, @r, 'door')) {
									_add_to_chunk(@chunk, @loc, 'water');
								} else {
									_add_to_chunk(@chunk, @loc, @roomData['floor']);
								}
							} else if(@roomShape == 'pit' && @column == 'room') {
								if((!_direction_of_solid(@layoutMap, @c, @r) || srand(@random) < 0.55)
								&& !_adjacent_equals(@layoutMap, @c, @r, 'door')) {
									@holeDepth = @maxRoomHeight;
									while(@holeDepth-- > 0) {
										_add_to_chunk(@chunk, location_shift(@loc, 'down', @holeDepth), 'air');
									}
								} else {
									_add_to_chunk(@chunk, @loc, @roomData['floor']);
								}
							} else if(@roomShape == 'rug') {
								if(!_direction_of_border(@layoutMap, @c, @r)) {
									_add_to_chunk(@chunk, @loc, 'redstone_ore');
								}
							} else if(@column == 'wall') {
								if(@roomData['doorFrame'] && @doorAdjacent) {
									_add_to_chunk(@chunk, @loc, @roomData['doorFrame']);
								} else {
									_add_to_chunk(@chunk, @loc, @roomData['wall']);
								}
							} else if(@column == 'empty' || @column == 'divider') {
								_add_to_chunk(@chunk, @loc, @roomData['divider']);
							} else if((@column == 'door' || @column == 'hall') && @floorData['ascending'] && @floorHeight != 1) {
								@stairs = @roomData['edge'];
								if(!string_ends_with(@stairs, 'stairs')) {
									@stairs = 'cobblestone_stairs';
								}
 								if(_get_cell(@floorHeightMap, @c, @r, 'north') - @floorHeight == -1
								&& _get_cell(@layoutMap, @c, @r, 'north') != 'wall') {
									_add_to_chunk(@chunk, @loc, @stairs.'[facing=south]');
								} else if(_get_cell(@floorHeightMap, @c, @r, 'south') - @floorHeight == -1
								&& _get_cell(@layoutMap, @c, @r, 'south') != 'wall') {
									_add_to_chunk(@chunk, @loc, @stairs.'[facing=north]');
								} else if(_get_cell(@floorHeightMap, @c, @r, 'east') - @floorHeight == -1
								&& _get_cell(@layoutMap, @c, @r, 'east') != 'wall') {
									_add_to_chunk(@chunk, @loc, @stairs.'[facing=west]');
								} else if(_get_cell(@floorHeightMap, @c, @r, 'west') - @floorHeight == -1
								&& _get_cell(@layoutMap, @c, @r, 'west') != 'wall') {
									_add_to_chunk(@chunk, @loc, @stairs.'[facing=east]');
								} else {
									_add_to_chunk(@chunk, @loc, @roomData['floor']);
								}
							} else {
								if(@debug) {
									_add_to_chunk(@chunk, @loc, @debugMaterials[if(@room, @room['depth'] % array_size(@debugMaterials), 0)]);
								} else {
									_add_to_chunk(@chunk, @loc, @roomData['floor']);
								}
							}

							// Walls
							@randomBlock = '';
							if(!@doorAdjacent && !string_ends_with(@roomShape, 'pit') && srand(@random) < @roomData['randomBlockChance']) {
								@randomBlock = _array_get_srand(@random, @roomData['randomblocks']);
							}
							@groundY += @floorHeight;
							@ceilingY = @groundY + @roomHeight + 2;
							@y = 0;
							@columnRandom = srand(@random);
							for(@y = @groundY + 2, @y < @ceilingY, @y++) {
								@loc[1] = @y;
								switch(@column) {
									case 'room':
										switch(@roomShape) {
											case 'rug':
												if(@y == @groundY + 2
												&& !_direction_of_border(@layoutMap, @c, @r)) {
													_add_to_chunk(@chunk, @loc, @roomData['rug']);
													continue();
												}
											case 'fire_floor':
												if(@y == @groundY + 2
												&& (@x + @z) % 2
												&& srand(@random) > 0.2) {
													_add_to_chunk(@chunk, @loc, 'stone_pressure_plate');
													continue();
												}
											case 'attic':
												if(@y == @ceilingY - @roomHeight + @room['midheight'] && srand(@random) > 0.05) {
													_add_to_chunk(@chunk, @loc, @roomData['floor']);
													continue();
												}
											case 'balcony':
												@d = @roomId % 4;
												if(@y == @ceilingY - @roomHeight + @room['midheight']
												&& (@d == 0 && @c < @room['c1'] + @room['width'] / 2
												|| @d == 1 && @c > @room['c1'] + @room['width'] / 2
												|| @d == 2 && @r < @room['r1'] + @room['length'] / 2
												|| @d == 3 && @r > @room['r1'] + @room['length'] / 2)) {
													_add_to_chunk(@chunk, @loc, @roomData['floor'][0]);
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

										if(@roomData['edge'] != @roomData['room']
										&& @room['width'] > 1
										&& @room['length'] > 1
										&& @roomHeight > 3
										&& @y == @ceilingY - 1) {
											@stairs = string_ends_with(@roomData['edge'], 'stairs');
											@north = @layoutMap[@c][@r - 1];
											@south = @layoutMap[@c][@r + 1];
											@west = @layoutMap[@c - 1][@r];
											@east = @layoutMap[@c + 1][@r];
											@state = @roomData['edge'].if(@stairs, '[half=top'.if(@roomData['room'] == 'water', ',waterlogged=true'));
											if(@roomHeight < 4 && (@east == 'window' || @west == 'window'
											|| @north == 'window' || @south == 'window')) {
												@state = @roomData['room'];
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
												@state = @roomData['room'];
											}
											_add_to_chunk(@chunk, @loc, @state);

										} else if(@y == @groundY + 3
										&& srand(@random) < @roomData['wallTorchChance']
										&& _adjacent_equals(@layoutMap, @c, @r, 'wall')) {
											@dir = _direction_of_solid(@layoutMap, @c, @r);
											if(!@dir) {
												_add_to_chunk(@chunk, @loc, @roomData['room']);
											} else {
												_add_to_chunk(@chunk, @loc, 'wall_torch[facing='._opposite_direction(@dir).']');
											}

										} else if(@randomBlock && (@y == @groundY + 2 || @y == @groundY + 3
										&& string_position(@randomBlock, '[') == -1
										&& srand(@random) < 0.4
										&& material_info(@randomBlock, 'isSolid')
										&& material_info(@randomBlock, 'isOccluding'))) {
											_add_to_chunk(@chunk, @loc, @randomBlock);

										} else {
											_add_to_chunk(@chunk, @loc, @roomData['room']);
										}

									case 'window':
										if(@roomData['window']
										&& @y < @ceilingY - @roomHeight + 3
										&& @y > @ceilingY - @roomHeight) {
											_add_to_chunk(@chunk, @loc, @roomData['window']);
										} else {
											@wallMaterial = @roomData['wall'];
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

									case 'hall':
										_add_to_chunk(@chunk, @loc, @roomData['room']);

									case 'wall':
										if(@roomData['doorFrame']
										&& @doorAdjacent
										&& @y <= @ceilingY - @roomHeight + 2) {
											_add_to_chunk(@chunk, @loc, @roomData['doorFrame']);

										} else if(@roomData['windowFrame']
										&& _adjacent_equals(@layoutMap, @c, @r, 'window')
										&& @y < @ceilingY - @roomHeight + 3 && @y > @ceilingY - @roomHeight) {
											_add_to_chunk(@chunk, @loc, @roomData['windowFrame']);

										} else if(@debug) {
											_add_to_chunk(@chunk, @loc, @debugMaterials[if(@room, @room['depth'] % array_size(@debugMaterials), 0)]);

										} else {
											@wallMaterial = @roomData['wall'];
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

									case 'door':
										if(@y < @ceilingY - @roomHeight + 2 + if(@roomData['tallDoors'] && @doorAdjacent, 1, 0) + if(@floorData['ascending'], 1, 0)) {
											if(string_ends_with(@roomData['door'], 'door')) {
												if(!@doorAdjacent && @roomId != -1 && @room['depth'] % 3 == 1) {
													@lower = @y < @ceilingY - @roomHeight + 1;
													if(@roomMap[@c][@r - 1] == -1) {
														@half = if(@lower, 'half=lower,', 'half=upper,');
														_add_to_chunk(@chunk, @loc, @roomData['door'].'[facing=south,'.@half.'hinge=left]');
													} else if(array_get(@roomMap[@c], @r + 1, 0) == -1) { // dungeon entrance special case
														@half = if(@lower, 'half=lower,', 'half=upper,');
														_add_to_chunk(@chunk, @loc, @roomData['door'].'[facing=north,'.@half.'hinge=left]');
													} else if(@roomMap[@c - 1][@r] == -1) {
														@half = if(@lower, 'half=lower,', 'half=upper,');
														_add_to_chunk(@chunk, @loc, @roomData['door'].'[facing=east,'.@half.'hinge=left]');
													} else if(@roomMap[@c + 1][@r] == -1) {
														@half = if(@lower, 'half=lower,', 'half=upper,');
														_add_to_chunk(@chunk, @loc, @roomData['door'].'[facing=west,'.@half.'hinge=left]');
													} else {
														_add_to_chunk(@chunk, @loc, @roomData['room']);
													}
												} else {
													_add_to_chunk(@chunk, @loc, @roomData['room']);
												}
											} else {
												_add_to_chunk(@chunk, @loc, @roomData['door']);
											}
										} else if(@roomData['doorFrame']
										&& @y <= @ceilingY - @roomHeight + if(@doorAdjacent, 3, 2)) {
											_add_to_chunk(@chunk, @loc, @roomData['doorFrame']);

										} else {
											@wallMaterial = @roomData['wall'];
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

									case 'column':
										_add_to_chunk(@chunk, @loc, @roomData['column']);

									case 'divider':
										_add_to_chunk(@chunk, @loc, @roomData['divider']);

									default:
										if(_adjacent_equals(@layoutMap, @c, @r, 'hall') && @y < @ceilingY - @roomHeight + 3 + if(@roomData['tallDoors'], 1, 0) + if(@floorData['ascending'], 1, 0)) {
											_add_to_chunk(@chunk, @loc, @roomData['wall']);
										} else if(_adjacent_equals(@layoutMap, @c, @r, 'window')) {
											if(@y < @ceilingY - @roomHeight + 3
											&& @y > @ceilingY - @roomHeight) {
												_add_to_chunk(@chunk, @loc, 'air');
											} else if(@y == @ceilingY - @roomHeight + 3) {
												_add_to_chunk(@chunk, @loc, 'light[level=6]');
											} else {
												_add_to_chunk(@chunk, @loc, @roomData['empty']);
											}
										} else {
											_add_to_chunk(@chunk, @loc, @roomData['empty']);
										}
								}
							}

							if(@roof) {
								// Ceiling
								@loc[1] += 1;
								if(@column != 'empty' && @column != 'divider') {
									_add_to_chunk(@chunk, @loc, @roomData['ceiling']);
								} else {
									_add_to_chunk(@chunk, @loc, @roomData['divider']);
								}

								// Bedrock floor divider
								while(@loc[1] < @y + @maxRoomHeight - @roomHeight + 1) {
									@loc[1] += 1;
									if(@roomData['randomRoofHeight'] && @loc[1] < @y + @maxRoomHeight - @roomHeight) {
										_add_to_chunk(@chunk, @loc, @roomData['ceiling']);
									} else {
										_add_to_chunk(@chunk, @loc, @roomData['divider']);
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
				if(!@room['depth']) {
					continue();
				}

				@roomShape = @room['shape'];
				@roomType = @room['type'];
				@roomWidth = @room['width'];
				@roomLength = @room['length'];
				@minWidth = min(@roomWidth, @roomLength);
				@roomHeight = @room['height'];
				@roomX = @regionMinX + @room['c1'];
				@roomY = @regionMinY + (@floor * (@maxRoomHeight + 4)) + 2 + @room['floor'];
				@roomZ = @regionMinZ + @room['r1'];

				@roomData = @floorData;
				if(@roomType && array_index_exists(@options, 'rooms') && array_index_exists(@options['rooms'], @roomType)) {
					@roomData = array_merge(@roomData, @options['rooms'][@roomType]);
				}

				if(@roomData['overhead']) {
					queue_push(closure(){
						@loc = array(
							@roomX + @roomWidth / 2,
							@roomY + @roomHeight - 1,
							@roomZ + @roomLength / 2,
							@world,
						);
						set_blockdata_string(@loc, @roomData['overhead']);
					}, 'generator');
				}

				// We need to create spawns after all blocks are set to ensure clearance.
				@createSpawns = closure(){
					if(@roomData['spawnCount'] > 0) {
						@count = @roomData['spawnCount'];
						@attempts = @roomData['spawnCount'] * 10;
						while(@attempts-- > 0 && @count > 0) {
							@loc = array(
								@roomX + integer(srand(@random) * @roomWidth) + 0.5,
								@roomY + if(@roomShape == 'attic', @room['midheight'] + 1, 0),
								@roomZ + integer(srand(@random) * @roomLength) + 0.5,
								@world,
								if(@roomShape == 'attic', 0, @room['doors']), // use this for sorting, lower being more isolated a room
								@room['depth'] // distance to start
							);
							if(equals_ic(@roomData['room'], get_block(@loc))) {
								if(string_ends_with(@roomShape, 'pit')) {
									set_blockdata_string(location_shift(@loc, 'down'), _array_get_srand(@random, @roomData['floor']), false);
								}
								@count--;
								@spawns[@floor][] = @loc;
								if(@debug) {
									set_block(@loc, 'OAK_SIGN');
									set_sign_text(@loc, @room['depth']);
								}
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
				} else if(string_ends_with(@roomShape, 'pit')) {
					// Still want to create spawns, but conditions are poor for other blocks and traps
					queue_push(@createSpawns, 'generator');
					continue();
				}

				queue_push(closure(){
					if(@debug) {
						sk_pos1(player(), array(@roomX, @roomY, @roomZ));
						sk_pos2(player(), array(@roomX + @roomWidth, @roomY + @roomHeight, @roomZ + @roomLength));
					}

					@spawner = false;
					if(@roomShape == 'fire_floor') {
						@y = @roomY - 1;
						for(@x = @roomX, @x < @roomX + @roomWidth, @x++) {
							for(@z = @roomZ, @z < @roomZ + @roomLength, @z++) {
								try(set_inventory(array(@x, @y, @z, @world), array(0: array(
									name: 'FLINT_AND_STEEL'
								))));
							}
						}
					} else if(@minWidth > 2) {
						// can place a door blocking block in the room
						if(@room['depth'] > 2 && @roomData['spawner'] && @roomShape != 'treasure' && srand(@random) < @roomData['spawnerChance']) {
							@loc = array(
								@roomX + 1 + integer(srand(@random) * (@roomWidth - 2)),
								@roomY + if(@roomShape == 'attic' && srand(@random) > 0.67, @room['midheight'] + 1, 0),
								@roomZ + 1 + integer(srand(@random) * (@roomLength - 2)),
								@world
							);
							@spawner = true;
							set_block(@loc, 'SPAWNER', false);
							@rand = integer(srand(@random) * array_size(@roomData['spawner']));
							@mob = array_get(@roomData['spawner'], @rand, 'ZOMBIE');
							set_spawner_type(@loc, @mob);
						} else if(@roomData['campfireChance'] && srand(@random) < @roomData['campfireChance']) {
							@attempts = 10;
							while(@attempts-- > 0) {
								@loc = array(
									@roomX + 1 + integer(srand(@random) * (@roomWidth - 2)),
									@roomY + if(@roomShape == 'attic' && srand(@random) > 0.67, @room['midheight'] + 1, 0),
									@roomZ + 1 + integer(srand(@random) * (@roomLength - 2)),
									@world
								);
								if(equals_ic(@roomData['room'], get_block(@loc))) {
									set_block(@loc, 'CAMPFIRE', false);\
									@loc = location_shift(@loc, 'down');
									set_block(@loc, 'PODZOL', false);
									for(@x = -1, @x <= 1, @x++) {
										for(@z = -1, @z <= 1, @z++) {
											@r = srand(@random);
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

					if(@roomShape == 'treasure' || (@minWidth > 2 && (@roomData['chestCount'] > 0 || @roomData['barrelCount'] > 0))) {
						@chests = @roomData['chestCount'];
						@barrels = @roomData['barrelCount'];
						if(@roomShape == 'treasure') {
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
						@bonus = if(@roomShape == 'treasure', 4, 1);
						@chestHeight = 0;
						if(@roomShape == 'attic' && srand(@random) > 0.33) {
							@chestHeight = @room['midheight'] + 1;
						} else if(@roomShape == 'treasure') {
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
							if(@roomShape == 'balcony') {
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
							if(equals_ic(@roomData['room'], get_block(@loc))
							&& array_contains_ic(@roomData['wall'], get_block(location_shift(@loc, @wallSide)))) {
								@inv = _get_chest_loot(@floor, @random, @bonus);
								set_blockdata_string(@loc, 'chest[facing='._opposite_direction(@wallSide).if(@roomData['room'] == 'water', ',waterlogged=true').']', false);
								@chestArray[] = @loc;
								@chests--;
								if(array_size(@inv) > get_inventory_size(@loc)) {
									@inv = @inv[cslice(0, get_inventory_size(@loc))];
								}
								try(set_inventory(@loc, @inv));
							}
						}
						if(@roomShape == 'treasure') {
							@attempts = 8;
							while(@attempts-- > 0) {
								@loc = array(
									@roomX + 1 + integer(srand(@random) * (@roomWidth - 2)),
									@roomY + @chestHeight,
									@roomZ + 1 + integer(srand(@random) * (@roomLength - 2)),
									@world
								);
								if(equals_ic(@roomData['room'], get_block(@loc))) {
									@podium = array_get(array('OCHRE_FROGLIGHT', 'VERDANT_FROGLIGHT', 'PEARLESCENT_FROGLIGHT'), min(2, integer(@floor / 3)));
									@double = false;
									if(equals_ic(@roomData['room'], get_block(location_shift(@loc, 'west')))) {
										@double = true;
										@rightSide = location_shift(@loc, 'west');
										set_blockdata_string(@rightSide, 'chest[facing=south'.if(@roomData['room'] == 'water', ',waterlogged=true').',type=right]', false);
										set_block(location_shift(@rightSide, 'down'), @podium, false);
									}
									set_blockdata_string(@loc, 'chest[facing=south'.if(@roomData['room'] == 'water', ',waterlogged=true').if(@double, ',type=left').']', false);
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
							if(equals_ic(@roomData['room'], get_block(@loc))) {
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

					if(@roomData['utility'] && @minWidth > 2) {
						@loc = array(
							@roomX + 1 + integer(srand(@random) * (@roomWidth - 2)),
							@roomY + if(@roomShape == 'attic' && srand(@random) > 0.5, @room['midheight'] + 1, 0),
							@roomZ + 1 + integer(srand(@random) * (@roomLength - 2)),
							@world
						);
						if(equals_ic(@roomData['room'], get_block(@loc))) {
							set_blockdata_string(@loc, _array_get_srand(@random, @roomData['utility']), false);
						}
					}

					if(@roomShape == 'attic' && @roomData['room'] != 'water') {
						@vines = max(1, integer(@minWidth / 3));
						do {
							@loc = null;
							@block = null;
							@length = null;
							if(@roomData['vine']) {
								@block = @roomData['vine'];
								@length = @room['height'];
							}
							if(@block == null || @block == 'vine') {
								@dirs = array_rand(array('east', 'west', 'north', 'south'), rand(1, 3), false);
								@block = array(block: 'vine');
								foreach(@dir in @dirs) {
									@block[@dir] = true;
								}
								@length = @room['midheight'] + 1;
							} else if(@block == 'ladder') {
								@block = array(block: 'ladder', facing: _array_get_srand(@random, array('east', 'west', 'north', 'south')));
								@length = @room['midheight'] + 1;
							}
							@attempts = 10;
							do {
								@loc = array(
									@roomX + 1 + integer(srand(@random) * (@roomWidth - 2)),
									@roomY + @length,
									@roomZ + 1 + integer(srand(@random) * (@roomLength - 2)),
									@world
								);
							} while(!equals_ic(@roomData['room'], get_block(@loc)) && --@attempts > 0)

							while(@length-- > 0) {
								@loc[1]--;
								set_blockdata(@loc, @block, @block == 'weeping_vines');
							}
							@vines--;
						} while(@vines > 0)
					}

					if(@i == @farthestRoom && @roomData['boss']) {
						@tries = 10;
						while(@tries-- > 0) {
							@loc = array(
								@roomX + integer(srand(@random) * @roomWidth) + 0.5,
								@roomY,
								@roomZ + integer(srand(@random) * @roomLength) + 0.5,
								@world
							);
							if(equals_ic(@roomData['room'], get_block(@loc))) {
								_spawn_entity(@roomData['boss'], @loc, null, closure(@entity) {
									add_scoreboard_tag(@entity, 'floor'.@floor.'boss');
									set_mob_name(@entity, 'BOSS');
								});
								die();
							}
						}
					}

					if(@room['depth'] > 2 && @roomData['trap'] && @roomShape != 'fire_floor') {
						@traps = integer(srand(@random) * max(@roomLength, @roomWidth));
						while(@traps-- > 0) {
							@type = split('_', _array_get_srand(@random, @roomData['trap']));
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
							if(!equals_ic(@roomData['room'], get_block(@loc))) {
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
									if(@roomShape == 'attic' || @roomShape == 'balcony') {
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
									if(!@spawner) {
										set_blockdata(location_shift(@loc, 'up'), 'redstone_block', false);
									}
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
									while('AIR' == get_block(location_shift(@loc, @negative, @dist)) && @dist < 12) {
										array_insert(@tripwire, location_shift(@loc, @negative, @dist), 0);
										@dist++;
									}
									if(@dist == 12) {
										continue();
									}
									@dist = 1;
									while('AIR' == get_block(location_shift(@loc, @positive, @dist)) && @dist < 12) {
										@tripwire[] = location_shift(@loc, @positive, @dist);
										@dist++;
									}
									if(@dist == 12 || @dist < 3) {
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
										if(equals_ic(@roomData['room'], get_block(@loc))) {
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

				
				if(array_contains(@roomData['floor'], 'grass_block')
				|| @roomData['room'] == 'water') {
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

			if(@floorData['title'] && @floor < 12) {
				queue_push(closure(){
					@floorRegion = @region.(@floor + 1);
					if(!sk_region_exists(@world, @floorRegion)) {
						sk_region_create(@world, @floorRegion, array(
							array(@regionMaxX, @groundY + @maxRoomHeight, @regionMaxZ, @world),
							array(@regionMinX, @groundY, @regionMinZ, @world),
						));
						sk_region_flag(@world, @floorRegion, 'passthrough', 'allow');
					} else {
						sk_region_update(@world, @floorRegion, array(
							array(@regionMaxX, @groundY + @maxRoomHeight, @regionMaxZ),
							array(@regionMinX, @groundY, @regionMinZ),
						));
					}
					@floorNums = array('One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine', 'Ten', 'Eleven', 'Twelve');
					sk_region_flag(@world, @floorRegion, 'greeting-title', '\u00A77- Floor '.@floorNums[@floor].' -\n'.@floorData['title']);
				}, 'generator');
			}

			// exit room / Pop ladder into floor
			if(@exitRoom) {
				queue_push(closure(){
					// TODO: fix sometimes in doorway
					@loc = array(
						@regionMinX + @exitRoom['c1'],
						@regionMinY + @floor * (@maxRoomHeight + 4) + 2,
						@regionMinZ + @exitRoom['r1'],
						@world,
					);
					set_blockdata_string(@loc, 'spruce_trapdoor[facing=south,half=bottom,waterlogged='.(@floorData['room'] == 'water').']', false);

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
							set_block(location_shift(@loc, 'south'), @floorData['wall'][0], false);
							set_block(location_shift(@loc, 'east'), @floorData['wall'][0], false);
							set_block(location_shift(@loc, 'west'), @floorData['wall'][0], false);
						} else {
							set_block(location_shift(@loc, 'south'), 'AIR', false);
						}
						set_block(location_shift(@loc, 'north'), @floorData['wall'][0], false);
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

			queue_push(closure(){
				res_free_resource(@random);
			}, 'generator');
		}

		// finished generation
		queue_push(closure(){
			@cleanUp();

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
					x: @startingRoom['c1'] + @regionMinX + 0.5,
					y: @sy = @regionMinY + 1,
					z: @startingRoom['r1'] + @regionMinZ + 0.5,
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

proc _opposite_direction(@dir) {
	switch(@dir) {
		case 'north':
			return('south');
		case 'south':
			return('north');
		case 'east':
			return('west');
		case 'west':
			return('east');
		case 'up':
			return('down');
		case 'down':
			return('up');
		default:
			throw('FormatException', 'Invalid direction: '.@dir);
	}
}

proc _array_get_srand(@random, @array) {
	return @array[integer(srand(@random) * array_size(@array))];
}