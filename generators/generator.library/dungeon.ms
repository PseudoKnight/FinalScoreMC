proc _generate(@dungeonType, @region, @world, @seed, @callback) {
	// default procs
	proc _set_locations(@start, @end, @spawns) {
		noop();
	}
	
	proc _get_loot(@level, @random, @loot = array()) {
		return(@loot);
	}
	
	try {
		include('dungeon.library/'.@dungeonType.'.ms');
	} catch(IOException @ex) {
		// doesn't exist, but that's okay
	}
	@options = yml_decode(read('/dungeon.library/'.@dungeonType.'.yml'));
	@scale = array_get(@options, 'scale', 2);
	@minRoomSize = array_get(@options, 'minRoomSize', 3);
	@maxRoomSize = array_get(@options, 'maxRoomSize', 11);
	@maxRoomHeight = array_get(@options, 'maxRoomHeight', 3);
	@roof = array_get(@options, 'roof', true);
	@chestCount = array_get(@options, 'chestCount', 0);
	@spawnChance = array_get(@options, 'spawnChance', 0.001);
	@extraDoors = array_get(@options, 'extraDoors', 0.0);
	@duplicateOffset = array_get(@options, 'duplicateOffset', 0);
	@duplicateDir = array_get(@options, 'duplicateDir', '');
	
	// process levels config to standard format
	foreach(@type in array('levels', 'duplicateLevels')) {
		foreach(@level in @options[@type]) {
			foreach(@key: @value in @level) {
				if(is_string(@value)) {
					if(@key == 'edge') {
						@level[@key] = array('north': @value, 'east': @value, 'south': @value, 'west': @value);
					} else {
						@level[@key] = array(@value);
					}
				}
			}
			// populate with defaults
			if(!array_index_exists(@level, 'empty')) {
				@level['empty'] = array('BEDROCK');
			}
			if(!array_index_exists(@level, 'room')) {
				@level['room'] = array('AIR');
			}
			if(!array_index_exists(@level, 'door')) {
				@level['door'] = array('AIR');
			}
			if(!array_index_exists(@level, 'bed')) {
				@level['bed'] = false;
			}
		}
	}

	if(!@seed) {
		@seed = integer(time() / 100000);
	}

	// Get size, scaled
	if(!sk_region_exists(@world, @region)) {
		die('Region doesn\'t exist.');
	}

	@coords = sk_region_info(@region, @world, 0);
	@regionMinX = @coords[1][0];
	@regionMaxX = @coords[0][0];
	@regionMinY = @coords[1][1];
	@regionMinZ = @coords[1][2];
	@regionMaxZ = @coords[0][2];
	@regionWidth = @coords[0][0] - @coords[1][0];
	@regionLength = @coords[0][2] - @coords[1][2];
	@width = ceil(@regionWidth / @scale);
	@length = ceil(@regionLength / @scale);

	if(@width % 2 == 0) {
		@width -= 1;
	}
	if(@length % 2 == 0) {
		@length -= 1;
	}
	if(@width < 21 || @length < 21) {
		die('Region too small!');
	}

	// Dungeon planning (off the server thread)
	msg(color('yellow').'Generating '.@dungeonType.' with seed "'.@seed.'" ...');
	_remove_region_entities(@region, array(), @world);
	x_new_thread('dungeon', closure(){
		@random = res_create_resource('RANDOM', @seed);
		@rooms = null;
		@farthestRoom = null;
		@exitRoom = null;
		@spawns = array();
		
		// Place entrance room
		@c = integer(srand(@random) * (@width / 2 - 3)) * 2 + 3;
		@r = integer(srand(@random) * (@length / 2 - 3)) * 2 + 3;
		@entranceRoom = array(
			'r1': @r,
			'c1': @c,
			'width': 3,
			'length': 3,
			'connected': 0,
			'height': 4,
		);

		foreach(@level in range(array_size(@options['levels']))) {
			@spawns[@level] = array();
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
			if(@level == 0) {
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
							'height': if(@roomWidth == 1 || @roomLength == 1, min(@maxRoomHeight, 3), rand(2, @maxRoomHeight + 1)),
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
			@limit = 2000;
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
									@spawns[@level][] = array(
										'x': @regionMinX + @c2 * @scale + 0.5,
										'y': @regionMinY + @level * (@maxRoomHeight + 3) + 1,
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
							@layoutMap[@c2][@r2] = 'wall';
						}
					}
				}
			}

			@mobTypes = @options['levels'][@level]['spawner'];
			
			// queue blocks in chunks
			proc _queue_block(@blocks, @loc, @material) {
				@x = floor(@loc[0] / 16);
				@z = floor(@loc[2] / 16);
				if(!array_index_exists(@blocks, @x)) {
					@blocks[@x] = associative_array();
				}
				if(!array_index_exists(@blocks[@x], @z)) {
					@blocks[@x][@z] = array();
				}
				@blocks[@x][@z][] = array('loc': @loc[], 'mat': @material);
				return(@blocks);
			}

			// Build dungeon level
			@allmaterials = array(@options['levels'][@level]);
			if(@duplicateOffset) {
				@allmaterials[] = @options['duplicateLevels'][@level];
			}
			@blocks = associative_array();
			foreach(@duplicate: @materials in @allmaterials) {
				for(@z = 0, @z < @length * @scale, @z++) {
					for(@x = 0, @x < @width * @scale, @x++) {
						@y = @regionMinY + @level * (@maxRoomHeight + 3) + if(@duplicateDir == 'up', @duplicate * @duplicateOffset, 0);
						@r = floor(@z / @scale);
						@c = floor(@x / @scale);
						@roomHeight = @heightMap[@c][@r];
						@loc = array(
							@regionMinX + @x + if(@duplicateDir == 'east', @duplicate * @duplicateOffset, 0),
							@y,
							@regionMinZ + @z + if(@duplicateDir == 'south', @duplicate * @duplicateOffset, 0),
							@world
						);

						// Floor
						@blocks = _queue_block(@blocks, @loc, @materials['floor']);

						// Walls
						@ceilingHeight = @y + @roomHeight + 1;
						for(@y = @y + 1, @y < @ceilingHeight, @y++) {
							@loc[1] = @y;
							switch(@layoutMap[@c][@r]) {
								case 'wall':
									@blocks = _queue_block(@blocks, @loc,@materials['wall']);
									
								case 'room':
									if(@y == @ceilingHeight - 1) {
										@north = @layoutMap[@c][@r - 1];
										@south = @layoutMap[@c][@r + 1];
										@west = @layoutMap[@c - 1][@r];
										@east = @layoutMap[@c + 1][@r];
										if((@east == 'wall' || @east == 'door') && @x % 2 == 1) {
											if(@roomHeight == 3 && @east == 'door' && @z % 2 == 0) {
												@blocks = _queue_block(@blocks, @loc, @materials['edge']['north']);
											} else {
												@blocks = _queue_block(@blocks, @loc, @materials['edge']['west']);
											}
										} else if((@west == 'wall' || @west == 'door') && @x % 2 == 0) {
											if(@roomHeight == 3 && @west == 'door' && @z % 2 == 1) {
												@blocks = _queue_block(@blocks, @loc, @materials['edge']['south']);
											} else {
												@blocks = _queue_block(@blocks, @loc, @materials['edge']['east']);
											}
										} else if((@south == 'wall' || @south == 'door') && @z % 2 == 1) {
											if(@roomHeight == 3 && @south == 'door' &&@x % 2 == 1) {
												@blocks = _queue_block(@blocks, @loc, @materials['edge']['east']);
											} else {
												@blocks = _queue_block(@blocks, @loc, @materials['edge']['north']);
											}
										} else if((@north == 'wall' || @north == 'door') && @z % 2 == 0) {
											if(@roomHeight == 3 && @north == 'door' && @x % 2 == 0) {
												@blocks = _queue_block(@blocks, @loc, @materials['edge']['west']);
											} else {
												@blocks = _queue_block(@blocks, @loc, @materials['edge']['south']);
											}
										} else {
											@blocks = _queue_block(@blocks, @loc, @materials['room']);
										}
									} else {
										@blocks = _queue_block(@blocks, @loc, @materials['room']);
									}
									
								case 'door':
									if(@y < @ceilingHeight - @roomHeight + 2) {
										@blocks = _queue_block(@blocks, @loc, @materials['door']);
									} else if(@y < @ceilingHeight - @roomHeight + 3) {
										@north = @layoutMap[@c][@r - 1];
										@south = @layoutMap[@c][@r + 1];
										@west = @layoutMap[@c - 1][@r];
										@east = @layoutMap[@c + 1][@r];
										if(@east == 'wall' && @x % 2 == 1) {
											@blocks = _queue_block(@blocks, @loc, @materials['edge']['west']);
										} else if(@west == 'wall' && @x % 2 == 0) {
											@blocks = _queue_block(@blocks, @loc, @materials['edge']['east']);
										} else if(@south == 'wall' && @z % 2 == 1) {
											@blocks = _queue_block(@blocks, @loc, @materials['edge']['north']);
										} else if(@north == 'wall' && @z % 2 == 0) {
											@blocks = _queue_block(@blocks, @loc, @materials['edge']['south']);
										} else {
											@blocks = _queue_block(@blocks, @loc, @materials['wall']);
										}
									} else {
										@blocks = _queue_block(@blocks, @loc, @materials['wall']);
									}
									
								case 'column':
									@blocks = _queue_block(@blocks, @loc, @materials['column']);
									
								default:
									@blocks = _queue_block(@blocks, @loc, @materials['empty']);
							}
						}
						
						if(@roof) {
							// Ceiling
							@loc[1] += 1;
							if(@layoutMap[@c][@r] === 'room') {
								@blocks = _queue_block(@blocks, @loc, @materials['ceiling']);
							} else {
								@blocks = _queue_block(@blocks, @loc, 'BEDROCK');
							}

							// Bedrock level divider
							while(@loc[1] < @y + @maxRoomHeight - @roomHeight + 1) {
								@loc[1] += 1;
								if(@layoutMap[@c][@r] === 'room') {
									@blocks = _queue_block(@blocks, @loc, @materials['empty']);
								} else {
									@blocks = _queue_block(@blocks, @loc, 'BEDROCK');
								}
							}
						}
					}
					if((@loc[2] + 1) % 16 == 0) {
						foreach(@chunks in @blocks) {
							foreach(@chunk in @chunks) {
								queue_push(closure(){
									foreach(@block in @chunk) {
										if(is_array(@block['mat'])) {
											set_block(@block['loc'], array_rand(@block['mat'], 1, false)[0], false);
										} else {
											set_block(@block['loc'], @block['mat'], false);
										}
									}
								}, 'generator');
							}
						}
						@blocks = associative_array();
					}
				}
				foreach(@chunks in @blocks) {
					foreach(@chunk in @chunks) {
						queue_push(closure(){
							foreach(@block in @chunk) {
								if(is_array(@block['mat'])) {
									set_block(@block['loc'], array_rand(@block['mat'], 1, false)[0], false);
								} else {
									set_block(@block['loc'], @block['mat'], false);
								}
							}
						}, 'generator');
					}
				}
				@blocks = associative_array();
			}
			
			// Populate rooms
			@materials = @allmaterials[0];
			foreach(@room in @rooms) {
				queue_push(closure(){
					if(@room['length'] == 1 || @room['width'] == 1) {
						die();
					}
					
					@yFloor = @regionMinY + (@level * (@maxRoomHeight + 3));
					@roomHeight = @room['height'];
					
					// spawner
					if(@mobTypes && srand(@random) < 0.7) {
						@loc = array(
							@regionMinX + @room['c1'] * @scale + 1 + integer(srand(@random) * (@room['width'] - 1)) * @scale,
							@yFloor + 1,
							@regionMinZ + @room['r1'] * @scale + 1 + integer(srand(@random) * (@room['length'] - 1)) * @scale,
							@world
						);
						if(array_contains(@materials['room'], get_block(@loc))) {
							set_block(@loc, 'SPAWNER', false);
							@rand = integer(srand(@random) * array_size(@mobTypes));
							@mob = array_get(@mobTypes, @rand, 'ZOMBIE');
							set_spawner_type(@loc, @mob);
						}
					}
					
					@chests = @chestCount ||| integer(srand(@random) * min(@room['length'], @room['width']) / 1.2);
					while(@chests-- > 0) {
						@loc = array(
							@regionMinX + @room['c1'] * @scale + 1 + integer(srand(@random) * (@room['width'] - 1)) * @scale,
							@yFloor + 1,
							@regionMinZ + @room['r1'] * @scale + 1 + integer(srand(@random) * (@room['length'] - 1)) * @scale,
							@world
						);
						if(array_contains(@materials['room'], get_block(@loc))) {
							set_block(@loc, 'CHEST', false);
							set_inventory(@loc, _get_loot(@level, @random));
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
						if(array_contains(@materials['room'], get_block(@loc))) {
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
						if(array_contains(@materials['room'], get_block(@loc))) {
							set_block(@loc, @materials['decor'][integer(srand(@random) * array_size(@materials['decor']))], false);
						}
					}
				}, 'generator');
			}
			
			// Pop ladder into level
			if(@exitRoom) {
				queue_push(closure(){
					@loc = array(
						@regionMinX + @exitRoom['c1'] * @scale,
						@regionMinY + @level * (@maxRoomHeight + 3) + 1,
						@regionMinZ + @exitRoom['r1'] * @scale,
						@world,
					);
					set_blockdata_string(@loc, 'oak_trapdoor[facing=south,half=bottom]', false);
					
					if(@options['levels'][@level]['bed']) {
						@bedLoc = location_shift(@loc, 'north');
						set_blockdata_string(@bedLoc, 'red_bed[facing=north,part=foot]', false);
						set_blockdata_string(location_shift(@bedLoc, 'north'), 'red_bed[facing=north,part=head]', false);
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
		queue_push(closure(){
			for(@c = 0, @c < @exitRoom['width'], @c++) {
				for(@r = 0, @r < @exitRoom['length'], @r++) {
					if(@layoutMap[@c + @exitRoom['c1']][@r + @exitRoom['r1']] != 'column') {
						break(2);
					}
				}
			}
			@ex = (@exitRoom['c1'] + @c) * @scale + @regionMinX + 0.5;
			@ey = @regionMinY + @level * (@maxRoomHeight + 3);
			@ez = (@exitRoom['r1'] + @r) * @scale + @regionMinZ + 0.5;
			@sx = @entranceRoom['c1'] * @scale + @regionMinX + 0.5;
			@sy = @regionMinY;
			@sz = @entranceRoom['r1'] * @scale + @regionMinZ + 0.5;
			
			@start = array('x': @sx, 'y': @sy, 'z': @sz, 'world': @world);
			@end = array('x': @ex, 'y': @ey, 'z': @ez, 'world': @world);
			res_free_resource(@random);
			_remove_region_entities(@region, array('DROPPED_ITEM'), @world);
			msg(color('green').@dungeonType.' generation complete!');
			if(is_closure(@callback)) {
				execute(@start, @end, @spawns, @callback);
			}
		}, 'generator');

	}); // End thread
}
