proc _generate_dungeon(@region, @world, @genType, @seed) {
	@level = 1;
	@scale = 2;
	@minRoomSize = 3;
	@maxRoomSize = 11;
	@maxRoomHeight = 3;
	
	include('../config.library/'.@genType.'.ms');

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
	msg(color('yellow').'Generating '.@genType.' with seed "'.@seed.'" ...');
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

		foreach(@level in range(@level)) {
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
							'height': if(@roomWidth == 1 || @roomLength == 1, 3, rand(3, @maxRoomHeight + 1)),
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
						&& !@rooms[@room]['connected']) {
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
								if(srand(@random) < 0.001) {
									@spawns[@level][] = array(
										'x': @regionMinX + @c2 * @scale,
										'y': @regionMinY + @level * (@maxRoomHeight + 3) + 1,
										'z': @regionMinZ + @r2 * @scale,
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

			@mobTypes = _level_mobs(@level);
			@materials = _materials(@level);

			// Build dungeon level
			for(@z = 0, @z < @length * @scale, @z++) {
				sleep(0.05);
				x_run_on_main_thread_later(closure(){
					for(@x = 0, @x < @width * @scale, @x++) {
						@y = @regionMinY + @level * (@maxRoomHeight + 3);
						@r = floor(@z / @scale);
						@c = floor(@x / @scale);
						@roomHeight = @heightMap[@c][@r];
						@loc = array(@regionMinX + @x, @y, @regionMinZ + @z, @world);

						// Floor
						set_block_at(@loc, array_rand(@materials['floor'], 1, false)[0], false);

						// Walls
						@ceilingHeight = @y + @roomHeight + 1;
						for(@y = @y + 1, @y < @ceilingHeight, @y++) {
							@loc[1] = @y;
							switch(@layoutMap[@c][@r]) {
								case 'wall':
									set_block_at(@loc, array_rand(@materials['wall'], 1, false)[0], false);
									
								case 'room':
									if(@y == @ceilingHeight - 1) {
										@north = @layoutMap[@c][@r - 1];
										@south = @layoutMap[@c][@r + 1];
										@west = @layoutMap[@c - 1][@r];
										@east = @layoutMap[@c + 1][@r];
										if((@east == 'wall' || @east == 'door') && @x % 2 == 1) {
											if(@roomHeight == 3 && @east == 'door' && @z % 2 == 0) {
												set_block_at(@loc, @materials['edge'][3], false);
											} else {
												set_block_at(@loc, @materials['edge'][0], false);
											}
										} else if((@west == 'wall' || @west == 'door') && @x % 2 == 0) {
											if(@roomHeight == 3 && @west == 'door' && @z % 2 == 1) {
												set_block_at(@loc, @materials['edge'][2], false);
											} else {
												set_block_at(@loc, @materials['edge'][1], false);
											}
										} else if((@south == 'wall' || @south == 'door') && @z % 2 == 1) {
											if(@roomHeight == 3 && @south == 'door' &&@x % 2 == 1) {
												set_block_at(@loc, @materials['edge'][0], false);
											} else {
												set_block_at(@loc, @materials['edge'][2], false);
											}
										} else if((@north == 'wall' || @north == 'door') && @z % 2 == 0) {
											if(@roomHeight == 3 && @north == 'door' && @x % 2 == 0) {
												set_block_at(@loc, @materials['edge'][1], false);
											} else {
												set_block_at(@loc, @materials['edge'][3], false);
											}
										} else {
											set_block_at(@loc, @materials['room'], false);
										}
									} else {
										set_block_at(@loc, @materials['room'], false);
									}
									
								case 'door':
									if(@y < @ceilingHeight - @roomHeight + 2) {
										set_block_at(@loc, @materials['door'], false);
									} else if(@y < @ceilingHeight - @roomHeight + 3) {
										@north = @layoutMap[@c][@r - 1];
										@south = @layoutMap[@c][@r + 1];
										@west = @layoutMap[@c - 1][@r];
										@east = @layoutMap[@c + 1][@r];
										if(@east == 'wall' && @x % 2 == 1) {
											set_block_at(@loc, @materials['edge'][0], false);
										} else if(@west == 'wall' && @x % 2 == 0) {
											set_block_at(@loc, @materials['edge'][1], false);
										} else if(@south == 'wall' && @z % 2 == 1) {
											set_block_at(@loc, @materials['edge'][2], false);
										} else if(@north == 'wall' && @z % 2 == 0) {
											set_block_at(@loc, @materials['edge'][3], false);
										} else {
											set_block_at(@loc, @materials['wall'], false);
										}
									} else {
										set_block_at(@loc, array_rand(@materials['wall'], 1, false)[0], false);
									}
									
								case 'column':
									set_block_at(@loc, @materials['column'], false);
									
								default:
									set_block_at(@loc, @materials['empty'], false);
							}
						}
						
						// Ceiling
						@loc[1] += 1;
						if(@layoutMap[@c][@r] === 'room') {
							set_block_at(@loc, array_rand(@materials['ceiling'], 1, false)[0], false);
						} else {
							set_block_at(@loc, 7, false);
						}

						// Bedrock level divider
						while(@loc[1] < @y + @maxRoomHeight - @roomHeight + 1) {
							@loc[1] += 1;
							if(@layoutMap[@c][@r] === 'room') {
								set_block_at(@loc, @materials['empty'], false);
							} else {
								set_block_at(@loc, 7, false);
							}
						}
					}
				});
			}
			
			// Populate rooms
			foreach(@room in @rooms) {
				sleep(0.05);
				x_run_on_main_thread_later(closure(){
					if(@room['length'] == 1 || @room['width'] == 1) {
						die();
					}
					
					@yFloor = @regionMinY + (@level * (@maxRoomHeight + 3));
					@roomHeight = @room['height'];
					
					// spawner
					if(@mobTypes['spawner'] && srand(@random) < 0.7) {
						@loc = array(
							@regionMinX + @room['c1'] * @scale + 1 + integer(srand(@random) * (@room['width'] - 1)) * @scale,
							@yFloor + 1,
							@regionMinZ + @room['r1'] * @scale + 1 + integer(srand(@random) * (@room['length'] - 1)) * @scale,
							@world
						);
						if(get_block_at(@loc) == @materials['room']) {
							set_block_at(@loc, '52:0', false);
							@rand = integer(srand(@random) * array_size(@mobTypes['spawner']));
							@mob = array_get(@mobTypes['spawner'], @rand, 'ZOMBIE');
							set_spawner_type(@loc, @mob);
						}
					}
					
					@chests = integer(srand(@random) * min(@room['length'], @room['width']) / 1.2);
					while(@chests-- > 0) {
						@loc = array(
							@regionMinX + @room['c1'] * @scale + 1 + integer(srand(@random) * (@room['width'] - 1)) * @scale,
							@yFloor + 1,
							@regionMinZ + @room['r1'] * @scale + 1 + integer(srand(@random) * (@room['length'] - 1)) * @scale,
							@world
						);
						if(get_block_at(@loc) == @materials['room']) {
							set_block_at(@loc, 54, false);
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
						if(get_block_at(@loc) == @materials['room']) {
							set_block_at(@loc, @materials['utility'][integer(srand(@random) * array_size(@materials['utility']))], false);
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
						if(get_block_at(@loc) == @materials['room']) {
							set_block_at(@loc, @materials['decor'][integer(srand(@random) * array_size(@materials['decor']))], false);
						}
					}
					
					if(@mobTypes['single']) {
						foreach(@loc in @spawns[@level]) {
							@mob = @mobTypes['single'][integer(srand(@random) * array_size(@mobTypes['single']))];
							@entity = spawn_entity(@mob, 1, @loc)[0];
							set_entity_persistence(@entity, true);
						}
					}
				});
			}
			
			// Pop ladder into level
			if(@exitRoom) {
				sleep(0.05);
				x_run_on_main_thread_later(closure(){
					@loc = array(
						@regionMinX + @exitRoom['c1'] * @scale,
						@regionMinY + @level * (@maxRoomHeight + 3) + 1,
						@regionMinZ + @exitRoom['r1'] * @scale,
						@world,
					);
					set_block_at(@loc, 96, false);
					@ladderHeight = @maxRoomHeight + 3;
					while(@ladderHeight-- > 0) {
						@loc[1]--;
						set_block_at(@loc, @materials['ladder'], false);
						if(@ladderHeight > 2) {
							set_block_at(_relative(@loc, 'south'), array_rand(@materials['wall'], 1, false)[0], false);
							set_block_at(_relative(@loc, 'east'), array_rand(@materials['wall'], 1, false)[0], false);
							set_block_at(_relative(@loc, 'west'), array_rand(@materials['wall'], 1, false)[0], false);
						} else {
							set_block_at(_relative(@loc, 'south'), 0, false);
						}
						set_block_at(_relative(@loc, 'north'), array_rand(@materials['wall'], 1, false)[0], false);
					}
				});
			}
			@exitRoom = @rooms[@farthestRoom];
		}
		sleep(0.05);
		x_run_on_main_thread_later(closure(){
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
			_set_locations(array('x': @sx, 'y': @sy, 'z': @sz, 'world': @world),
					array('x': @ex, 'y': @ey, 'z': @ez, 'world': @world), @spawns);
			res_free_resource(@random);
			_remove_region_entities(@region, array('DROPPED_ITEM'), @world);
			msg(color('green').@genType.' generation complete!');
		});

	}); // End thread
}
