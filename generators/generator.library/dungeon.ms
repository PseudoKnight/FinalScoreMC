proc _generate(@dungeonType, @region, @world, @seed, @callback) {
	// verify location is valid
	if(_is_survival_world(@world)) {
		die('Cannot generate a dungeon in a survival world!');
	} else if(!sk_region_exists(@world, @region)) {
		die('Region doesn\'t exist.');
	}
	
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
		
		// variability on room features
		'chestCount': 0,
		'spawnChance': 0.001,
		'extraDoors': 0.0,
		
		// toggleable features on floors
		'roof': true,
		'bed': false,
		'entranceDoor': false,
		'lavaPit': false,
		'pit': false,
		
		// default materials
		'empty': 'bedrock',
		'room': 'air',
		'door': 'air',
		'window': '', // optional
	), @options['default']);
	
	// process floors config to standard format
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
				@floorData['trap'] = array('air');
			}
			
			@options[@type][@floor] = @floorData;
		}
	}

	// define constants
	@seed = @seed ||| integer(time() / 100000);
	@coords = sk_region_info(@region, @world, 0);
	@regionMinX = ceil(@coords[1][0] / 2) * 2; // align to default scale
	@regionMaxX = @coords[0][0];
	@regionMinY = @coords[1][1];
	@regionMinZ = ceil(@coords[1][2] / 2) * 2; // align to default scale
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
	bar_add_player('gen'.@region, player());
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
		@c = integer(srand(@random) * (@width / 2 - 3)) * 2 + 3;
		@r = integer(srand(@random) * (@length / 2 - 3)) * 2 + 3;
		@entranceRoom = array(
			'r1': @r,
			'c1': @c,
			'width': 3,
			'length': 3,
			'connected': 0,
			'height': 4,
			'type': 'NORMAL',
		);

		foreach(@floor in range(array_size(@options['floors']))) {
			queue_push(closure(){
				update_bar('gen'.@region, 'Planning '.@dungeonType.' floor '.(@floor + 1));
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
				@r = @entranceRoom['r1'];
				@c = @entranceRoom['c1'];
				@rooms[] = @entranceRoom;
			} else {
				@r = @exitRoom['r1'];
				@c = @exitRoom['c1'];
				@rooms[] = array(
					'r1': @r,
					'c1': @c,
					'width': min(@exitRoom['width'], 3),
					'length': min(@exitRoom['length'], 3),
					'connected': 0,
					'height': 4,
					'type': 'NORMAL',
				);
			}
			for(@r2 = @r, @r2 < @rooms[0]['length'] + @r, @r2++) {
				for(@c2 = @c, @c2 < @rooms[0]['width'] + @c, @c2++) {
					@layoutMap[@c2][@r2] = 'room';
					@roomMap[@c2][@r2] = 0;
				}
			}

			// Place rooms
			@unconnected = array(0);
			for(@r = 1, @r < @length, @r += 2) {
				for(@c = 1, @c < @width, @c += 2) {
					if(@roomMap[@c][@r] == -1) {
						@roomWidth = integer(srand(@random) * ((@maxRoomSize - @minRoomSize) / 2 + 1)) * 2 + @minRoomSize;
						@roomLength = integer(srand(@random) * ((@maxRoomSize - @minRoomSize) / 2 + 1)) * 2 + @minRoomSize;

						// Check placement
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

						// Save room
						@unconnected[] = array_size(@rooms);
						@rooms[] = associative_array(
							'r1': @r,
							'c1': @c,
							'width': @roomWidth,
							'length': @roomLength,
							'connected': 0,
							'height': if(@roomWidth == 1 || @roomLength == 1) {
									min(@maxRoomHeight, 3);
								} else {
									rand(@minRoomHeight, @maxRoomHeight + 1);
								},
							'type': if(@floorData['lavaPit'] && @roomWidth > 1 && @roomLength > 1 && srand(@random) > 0.95) {
									'LAVAPIT';
								} else if(@floorData['pit'] && @floor > 0 && srand(@random) > 0.95) {
									'PIT';
								} else {
									'NORMAL';
								}
						);

						// Mask room
						for(@r2 = @r, @r2 < @roomLength + @r, @r2++) {
							for(@c2 = @c, @c2 < @roomWidth + @c, @c2++) {
								@roomMap[@c2][@r2] = array_size(@rooms) - 1;
							}
						}

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
							|| @layoutMap[@c2 + 1][@r2] == 'door'
							|| @layoutMap[@c2 - 1][@r2] == 'door'
							|| @layoutMap[@c2][@r2 + 1] == 'door'
							|| @layoutMap[@c2][@r2 - 1] == 'door'
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
							|| @layoutMap[@c2 + 1][@r2] == 'door'
							|| @layoutMap[@c2 - 1][@r2] == 'door'
							|| @layoutMap[@c2][@r2 + 1] == 'door'
							|| @layoutMap[@c2][@r2 - 1] == 'door')) {
								@layoutMap[@c2][@r2] = 'window';
							} else {
								@layoutMap[@c2][@r2] = 'wall';
							}
						}
					}
				}
			}
			
			// queue blocks in chunks
			proc _queue_block(@chunk, @loc, @material) {
				@chunk[] = array('loc': @loc[], 'mat': @material);
				return(@chunk);
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
			
			queue_push(closure(){
				update_bar('gen'.@region, 'Placing '.@dungeonType.' floor '.(@floor + 1));
			}, 'generator');
			
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
								
								@y = @regionMinY + @floor * (@maxRoomHeight + 3) + if(@cloneDir == 'up', @clone * @cloneOffset, 0);
								@roomHeight = @heightMap[@c][@r];
								@loc = array(
									(@chunkMinX + @chunkX) * 16 + @x + if(@cloneDir == 'east', @clone * @cloneOffset, 0),
									@y,
									(@chunkMinZ + @chunkZ) * 16 + @z + if(@cloneDir == 'south', @clone * @cloneOffset, 0),
									@world
								);

								// Floor
								if(@roomMap[@c][@r] != -1 && @rooms[@roomMap[@c][@r]]['type'] == 'LAVAPIT') {
									if(!_direction_of_solid(@layoutMap, @c, @r) || srand(@random) > 0.4) {
										@chunk = _queue_block(@chunk, @loc, 'lava');
									} else {
										@chunk = _queue_block(@chunk, @loc, @materials['floor']);
									}
								} else if(@roomMap[@c][@r] != -1 && @rooms[@roomMap[@c][@r]]['type'] == 'PIT') {
									if(!_direction_of_solid(@layoutMap, @c, @r) || srand(@random) > 0.4) {
										@holeDepth = @maxRoomHeight;
										while(@holeDepth-- > 0) {
											@chunk = _queue_block(@chunk, location_shift(@loc, 'down', @holeDepth), 'air');
										}
									} else {
										@chunk = _queue_block(@chunk, @loc, @materials['floor']);
									}
								} else {
									@chunk = _queue_block(@chunk, @loc, @materials['floor']);
								}

								// Walls
								@ceilingY = @y + @roomHeight + 1;
								for(@y = @y + 1, @y < @ceilingY, @y++) {
									@loc[1] = @y;
									switch(@layoutMap[@c][@r]) {
										case 'window':
											if(@y < @ceilingY - @roomHeight + 3 && @y > @ceilingY - @roomHeight) {
												@chunk = _queue_block(@chunk, @loc, @materials['window']);
											} else {
												@chunk = _queue_block(@chunk, @loc, @materials['wall']);
											}
										
										case 'wall':
											@chunk = _queue_block(@chunk, @loc, @materials['wall']);
											
										case 'room':
											if(@materials['edge'] != 'air' && @roomHeight > 2 && @y == @ceilingY - 1) {
												@stairs = string_ends_with(@materials['edge'], 'stairs');
												@north = @layoutMap[@c][@r - 1];
												@south = @layoutMap[@c][@r + 1];
												@west = @layoutMap[@c - 1][@r];
												@east = @layoutMap[@c + 1][@r];
												@state = @materials['edge'].if(@stairs, '[half=top'.if(@materials['room'] == 'water', ',waterlogged=true'));
												if((@east == 'wall' || @east == 'door') && @x % 2 == 1) {
													if(@stairs) {
														@state .= ',facing=east'
														if(@roomHeight == 3 && @east == 'door') {
															if(@z % 2 == 0) {
																@state .= ',shape=outer_left';
															} else {
																@state .= ',shape=outer_right';
															}
														} else if((@north == 'wall' || @north == 'door' && @roomHeight > 3) && @z % 2 == 0) {
															@state .= ',shape=inner_left';
														} else if((@south == 'wall' || @south == 'door' && @roomHeight > 3) && @z % 2 == 1) {
															@state .= ',shape=inner_right';
														}
														@state .= ']';
													}
												} else if((@west == 'wall' || @west == 'door') && @x % 2 == 0) {
													if(@stairs) {
														@state .= ',facing=west'
														if(@roomHeight == 3 && @west == 'door') {
															if(@z % 2 == 1) {
																@state .= ',shape=outer_left';
															} else {
																@state .= ',shape=outer_right';
															}
														} else if((@north == 'wall' || @north == 'door' && @roomHeight > 3) && @z % 2 == 0) {
															@state .= ',shape=inner_right';
														} else if((@south == 'wall' || @south == 'door' && @roomHeight > 3) && @z % 2 == 1) {
															@state .= ',shape=inner_left';
														}
														@state .= ']';
													}
												} else if((@south == 'wall' || @south == 'door') && @z % 2 == 1) {
													if(@stairs) {
														@state .= ',facing=south';
														if(@roomHeight == 3 && @south == 'door') {
															if(@x % 2 == 1) {
																@state .= ',shape=outer_left';
															} else {
																@state .= ',shape=outer_right';
															}
														}
														@state .= ']';
													}
												} else if((@north == 'wall' || @north == 'door') && @z % 2 == 0) {
													if(@stairs) {
														@state .= ',facing=north'
														if(@roomHeight == 3 && @north == 'door') {
															if(@x % 2 == 0) {
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
												@chunk = _queue_block(@chunk, @loc, @state);
											} else {
												@chunk = _queue_block(@chunk, @loc, @materials['room']);
											}
											
										case 'door':
											if(@y < @ceilingY - @roomHeight + 2) {
												if(@materials['entranceDoor']) {
													@north = @roomMap[@c][@r - 1];
													@south = @roomMap[@c][@r + 1];
													@west = @roomMap[@c - 1][@r];
													@east = @roomMap[@c + 1][@r];
													@lower = @y < @ceilingY - @roomHeight + 1;
													@count = array_size(@chunk);
													if(@north == 0) {
														if(@z % 2 == 1) {
															@half = if(@lower, 'half=lower,', 'half=upper,');
															@hinge = if(@x % 2 == 1, 'hinge=left', 'hinge=right');
															@chunk = _queue_block(@chunk, @loc, 'spruce_door[facing=south,'.@half.@hinge.']');
														}
													} else if(@south == 0) {
														if(@z % 2 == 0) {
															@half = if(@lower, 'half=lower,', 'half=upper,');
															@hinge = if(@x % 2 == 0, 'hinge=left', 'hinge=right');
															@chunk = _queue_block(@chunk, @loc, 'spruce_door[facing=north,'.@half.@hinge.']');
														}
													} else if(@west == 0) {
														if(@x % 2 == 1) {
															@half = if(@lower, 'half=lower,', 'half=upper,');
															@hinge = if(@z % 2 == 0, 'hinge=left', 'hinge=right');
															@chunk = _queue_block(@chunk, @loc, 'spruce_door[facing=east,'.@half.@hinge.']');
														}
													} else if(@east == 0) {
														if(@x % 2 == 0) {
															@half = if(@lower, 'half=lower,', 'half=upper,');
															@hinge = if(@z % 2 == 1, 'hinge=left', 'hinge=right');
															@chunk = _queue_block(@chunk, @loc, 'spruce_door[facing=west,'.@half.@hinge.']');
														}
													}
													if(@count == array_size(@chunk)) {
														@chunk = _queue_block(@chunk, @loc, @materials['door']);
													}
												} else {
													@chunk = _queue_block(@chunk, @loc, @materials['door']);
												}
											} else if(@y < @ceilingY - @roomHeight + 3) {
												@stairs = string_ends_with(@materials['edge'], 'stairs');
												@north = @layoutMap[@c][@r - 1];
												@south = @layoutMap[@c][@r + 1];
												@west = @layoutMap[@c - 1][@r];
												@east = @layoutMap[@c + 1][@r];
												@state = @materials['edge'].if(@stairs, '[half=top'.if(@materials['room'] == 'water', ',waterlogged=true'));
												if(@east == 'wall' && @x % 2 == 1) {
													if(@stairs) {
														@state .= ',facing=east]';
													}
												} else if(@west == 'wall' && @x % 2 == 0) {
													if(@stairs) {
														@state .= ',facing=west]';
													}
												} else if(@south == 'wall' && @z % 2 == 1) {
													if(@stairs) {
														@state .= ',facing=south]';
													}
												} else if(@north == 'wall' && @z % 2 == 0) {
													if(@stairs) {
														@state .= ',facing=north]';
													}
												} else {
													@state = @materials['wall'];
												}
												@chunk = _queue_block(@chunk, @loc, @state);
											} else {
												@chunk = _queue_block(@chunk, @loc, @materials['wall']);
											}
											
										case 'column':
											@chunk = _queue_block(@chunk, @loc, @materials['column']);
											
										default:
											@chunk = _queue_block(@chunk, @loc, @materials['empty']);
									}
								}
								
								if(@roof) {
									// Ceiling
									@loc[1] += 1;
									if(@layoutMap[@c][@r] === 'room') {
										@chunk = _queue_block(@chunk, @loc, @materials['ceiling']);
									} else {
										@chunk = _queue_block(@chunk, @loc, 'bedrock');
									}

									// Bedrock floor divider
									while(@loc[1] < @y + @maxRoomHeight - @roomHeight + 1) {
										@loc[1] += 1;
										if(@layoutMap[@c][@r] === 'room') {
											@chunk = _queue_block(@chunk, @loc, @materials['empty']);
										} else {
											@chunk = _queue_block(@chunk, @loc, 'bedrock');
										}
									}
								}
							}
						}
					}
					queue_push(closure(){
						foreach(@block in @chunk) {
							if(is_array(@block['mat'])) {
								set_blockdata_string(@block['loc'], array_rand(@block['mat'], 1, false)[0], false);
							} else {
								set_blockdata_string(@block['loc'], @block['mat'], false);
							}
						}
						if(@chunk) {
							foreach(@id in all_entities(@chunk[0]['loc'])) {
								if(entity_type(@id) == 'DROPPED_ITEM') {
									try(entity_remove(@id));
								}
							}
							update_bar('gen'.@region,  double(++@chunkCount[0] / @maxChunks));
						}
					}, 'generator');
				}
			}
			@chunk = null;
			
			queue_push(closure(){
				update_bar('gen'.@region, 'Decorating '.@dungeonType.' floor '.(@floor + 1));
			}, 'generator');
			
			// Populate rooms
			@materials = @allmaterials[0];
			foreach(@room in @rooms) {
				queue_push(closure(){
					if(@room['length'] == 1 || @room['width'] == 1 || @room['type'] == 'LAVAPIT' || @room['type'] == 'PIT') {
						die();
					}
					
					@yFloor = @regionMinY + (@floor * (@maxRoomHeight + 3));
					@roomHeight = @room['height'];
					
					// spawner
					if(@room['connected'] > 1 && @mobTypes && srand(@random) < 0.7) {
						@loc = array(
							@regionMinX + @room['c1'] * @scale + 1 + integer(srand(@random) * (@room['width'] - 1)) * @scale,
							@yFloor + 1,
							@regionMinZ + @room['r1'] * @scale + 1 + integer(srand(@random) * (@room['length'] - 1)) * @scale,
							@world
						);
						if(equals_ic(@materials['room'], get_block(@loc))) {
							set_block(@loc, 'SPAWNER', false);
							@rand = integer(srand(@random) * array_size(@mobTypes));
							@mob = array_get(@mobTypes, @rand, 'ZOMBIE');
							set_spawner_type(@loc, @mob);
						}
					}
					
					if(@chestCount > 0) {
						@chests = @chestCount;
						if(is_double(@chests)) {
							@chests = integer(srand(@random) * min(@room['length'], @room['width']) / @chests);
						}
						while(@chests-- > 0) {
							@loc = array(
								@regionMinX + @room['c1'] * @scale + 1 + integer(srand(@random) * (@room['width'] - 1)) * @scale,
								@yFloor + 1,
								@regionMinZ + @room['r1'] * @scale + 1 + integer(srand(@random) * (@room['length'] - 1)) * @scale,
								@world
							);
							if(equals_ic(@materials['room'], get_block(@loc))) {
								set_block(@loc, 'CHEST', false);
								try(set_inventory(@loc, _get_loot(@floor, @random)));
							}
						}
					}
					
					@utilities = integer(srand(@random) * 2);
					while(@utilities-- > 0) {
						@loc = array(
							@regionMinX + @room['c1'] * @scale + 1 + integer(srand(@random) * (@room['width'] - 1) * @scale),
							@yFloor + 1,
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
							@yFloor + 1,
							@regionMinZ + @room['r1'] * @scale + 1 + integer(srand(@random) * (@room['length'] - 1) * @scale),
							@world
						);
						if(equals_ic(@materials['room'], get_block(@loc))) {
							set_block(@loc, @materials['decor'][integer(srand(@random) * array_size(@materials['decor']))], false);
						}
					}
					
					@traps = integer(srand(@random) * max(@room['length'], @room['width']));
					while(@traps-- > 0) {
						@loc = array(
							@regionMinX + @room['c1'] * @scale + 1 + integer(srand(@random) * (@room['width'] - 1) * @scale),
							@yFloor + 1,
							@regionMinZ + @room['r1'] * @scale + 1 + integer(srand(@random) * (@room['length'] - 1) * @scale),
							@world
						);
						if(equals_ic(@materials['room'], get_block(@loc))) {
							@type = @materials['trap'][integer(srand(@random) * array_size(@materials['trap']))];
							switch(@type) {
								case 'tnt':
									if(srand(@random) > 0.5) {
										set_block(@loc, 'STONE_PRESSURE_PLATE', false);
									} else {
										set_block(@loc, 'TRAPPED_CHEST', false);
									}
									set_block(location_shift(@loc, 'down'), 'TNT', false);
								case 'poison':
									set_blockdata_string(location_shift(@loc, 'down'), 'dispenser[facing=up]', false);
									set_inventory(location_shift(@loc, 'down'), array(0: array(
											'name': 'SPLASH_POTION',
											'qty': 2,
											'meta': array('base': array('extended': false, 'type': 'POISON', 'upgraded': true))
									)));
									if(srand(@random) > 0.5) {
										set_block(@loc, 'STONE_PRESSURE_PLATE', false);
									} else {
										set_block(@loc, 'TRAPPED_CHEST', false);
									}
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
						@regionMinY + @floor * (@maxRoomHeight + 3) + 1,
						@regionMinZ + @exitRoom['r1'] * @scale,
						@world,
					);
					set_blockdata_string(@loc, 'spruce_trapdoor[facing=south,half=bottom]', false);
					
					if(@floorData['bed']) {
						@bedLoc = location_shift(@loc, 'east');
						set_blockdata_string(@bedLoc, 'red_bed[facing=north,part=head]', false);
						set_blockdata_string(location_shift(@bedLoc, 'south'), 'red_bed[facing=north,part=foot]', false);
					}
					
					@ladderHeight = @maxRoomHeight + 3;
					while(@ladderHeight-- > 0) {
						@loc[1]--;
						set_blockdata_string(@loc, 'ladder[facing=south]', false);
						if(@ladderHeight > 2) {
							set_block(location_shift(@loc, 'south'), array_rand(@materials['wall'], 1, false)[0], false);
							set_block(location_shift(@loc, 'east'), array_rand(@materials['wall'], 1, false)[0], false);
							set_block(location_shift(@loc, 'west'), array_rand(@materials['wall'], 1, false)[0], false);
						} else {
							set_block(location_shift(@loc, 'south'), 'AIR', false);
						}
						set_block(location_shift(@loc, 'north'), array_rand(@materials['wall'], 1, false)[0], false);
					}
				}, 'generator');
			}
			@exitRoom = @rooms[@farthestRoom];
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
					'y': @regionMinY + @floor * (@maxRoomHeight + 3),
					'z': (@exitRoom['r1'] + @r) * @options['floors'][array_size(@options['floors']) - 1]['scale'] + @regionMinZ + 0.5,
					'world': @world,
				);
				@start = array(
					'x': @entranceRoom['c1'] * @options['floors'][0]['scale'] + @regionMinX + 0.5,
					'y': @sy = @regionMinY,
					'z': @entranceRoom['r1'] * @options['floors'][0]['scale'] + @regionMinZ + 0.5,
					'world': @world,
				);
				execute(@start, @end, @spawns, @callback);
			}
		}, 'generator');

	}); // End thread
}
