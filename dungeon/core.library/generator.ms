proc _generate_dungeon(@region, @world, @type, @seed) {
	@minroomsize = 3
	@maxroomsize = 11
	@maxHeight = 4
	
	include('../config.library/'.@type.'.ms');

	if(!@seed) {
		@seed = time();
	}

	// Get size, scaled
	if(!sk_region_exists(@world, @region)) {
		die('Region doesn\'t exist.');
	}

	@coords = sk_region_info(@region, @world, 0);
	@regionMinX = @coords[1][0];
	@regionMaxX = @coords[0][0];
	@regionMinZ = @coords[1][2];
	@regionMaxZ = @coords[0][2];
	@regionwidth = @coords[0][0] - @coords[1][0];
	@regionlength = @coords[0][2] - @coords[1][2];
	@width = ceil(@regionwidth / @scale);
	@length = ceil(@regionlength / @scale);

	if(!(@width % 2)) {
		@width--;
	}
	if(!(@length % 2)) {
		@length--;
	}
	if(@width < 21 || @length < 21) {
		die('Region too small!');
	}

	// Dungeon planning (off the server thread)
	msg('Generating dungeon with seed "'.@seed.'" ...');
	x_new_thread('dungeon', closure(){
		@random = res_create_resource('RANDOM', @seed);
		@rooms = null;

		foreach(@level in range(@level)) {
			// Define grid
			@materialMap = array();
			@roomMap = array();
			@heightMap = array();
			for(@c = 0, @c < @width, @c++) {
				@materialMap[@c] = array();
				@roomMap[@c] = array();
				@heightMap[@c] = array();
				for(@r = 0, @r < @length, @r++) {
					@type = 'empty';
					if(@r == 0 || @r == @length - 1
					|| @c == 0 || @c == @width - 1) {
						@type = 'wall';
					}
					@materialMap[@c][@r] = @type;
					@roomMap[@c][@r] = -1;
					@heightMap[@c][@r] = @maxHeight;
				}
			}

			// Define rooms
			@entrance = null;
			if(!is_null(@rooms)) {
				@entrance = @rooms[0];
			}
			@rooms = array();

			// Place entrance ladder
			@c = (integer(srand(@random) * ((@width / 2) - 1)) * 2) + 1;
			@r = (integer(srand(@random) * ((@length / 2) - 1)) * 2) + 1;
			for(@r2 = @r, @r2 < 1 + @r, @r2++) {
				for(@c2 = @c, @c2 < 1 + @c, @c2++) {
					@materialMap[@c2][@r2] = 'ladder';
					@roomMap[@c2][@r2] = 0;
				}
			}

			@rooms[] = array(
				'r1': @r,
				'c1': @c,
				'roomwidth': 1,
				'roomlength': 1,
				'connected': 0,
			);
			@unconnected = array(0);

			// Place rooms
			for(@r = 1, @r < @length, @r += 2) {
				for(@c = 1, @c < @width, @c += 2) {
					if(@roomMap[@c][@r] == -1) {
						@roomwidth = integer(srand(@random) * (((@maxroomsize - @minroomsize) / 2) + 1)) * 2 + @minroomsize;
						@roomlength = integer(srand(@random) * (((@maxroomsize - @minroomsize) / 2) + 1)) * 2 + @minroomsize;

						// Check placement
						for(@r2 = @r, @r2 < @r + @roomlength, @r2 += 2) {
							@c2 = @c;
							if(@r2 >= @length || @roomMap[@c2][@r2] != -1) {
								@roomlength = @r2 - @r - 1;
								break();
							}
							for(@c2 = @c, @c2 < @c + @roomwidth, @c2 += 2) {
								if(@c2 >= @width || @roomMap[@c2][@r2] != -1) {
									@roomwidth = @c2 - @c - 1;
									break();
								}
							}
						}

						// Save room
						@unconnected[] = array_size(@rooms);
						@rooms[] = associative_array(
							'r1': @r,
							'c1': @c,
							'roomwidth': @roomwidth,
							'roomlength': @roomlength,
							'connected': 0,
						);

						// Mask room
                        for(@r2 = @r, @r2 < @roomlength + @r, @r2++) {
                            for(@c2 = @c, @c2 < @roomwidth + @c, @c2++) {
								@roomMap[@c2][@r2] = array_size(@rooms) - 1;
							}
						}

						@c = @c + @roomwidth - 1;
					}
				}
			}

			// Connect rooms
			@next = 0;
			@previous = @next;
			@try = array();
			@limit = 1000;
			@connected = associative_array();
			while(@unconnected) {
				@limit--;
				if(@limit < 0){
					die('Hit room connector limits! Rooms left: '.array_size(@unconnected).'/'.array_size(@rooms).'!');
				}

				array_remove_values(@unconnected, @next);
				@connected[@next] = null;
				if(@rooms[@next]['connected'] == 0){
					@rooms[@next]['connected'] = @rooms[@previous]['connected'] + 1;
				}

				@r = @rooms[@next]['r1'];
				@c = @rooms[@next]['c1'];
				@roomwidth = @rooms[@next]['roomwidth'];
				@roomlength = @rooms[@next]['roomlength'];

				@success = false;
				@dirs = array(0, 1, 2, 3);
				foreach(@d in range(4)) {
					@dir = integer(srand(@random) * array_size(@dirs));
					array_remove_values(@dirs, @dir);
					try {
						switch(@dir){
							case 0:
								@r2 = @r - 2;
								@c2 = @c + integer(srand(@random) * ((@roomwidth + 1) / 2)) * 2;
								@r3 = @r2 + 1;
								@c3 = @c2;
							case 1:
								@r2 = @r + @roomlength + 1;
								@c2 = @c + integer(srand(@random) * ((@roomwidth + 1) / 2)) * 2;
								@r3 = @r2 - 1;
								@c3 = @c2;
							case 2:
								@c2 = @c - 2;
								@r2 = @r + integer(srand(@random) * ((@roomlength + 1) / 2)) * 2;
								@c3 = @c2 + 1;
								@r3 = @r2;
							case 3:
								@c2 = @c + @roomwidth + 1;
								@r2 = @r + integer(srand(@random) * ((@roomlength + 1) / 2)) * 2;
								@c3 = @c2 - 1;
								@r3 = @r2;
						}
						@room = @roomMap[@c2][@r2];
						if(@room != -1
						&& @room != @previous
						&& !@rooms[@room]['connected']) {
							@materialMap[@c3][@r3] = 'door';
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
						@limit2 = array_size(@rooms);
						do {
							@next = array_keys(@connected)[integer(srand(@random) * array_size(@connected))];
							@limit2--;
						} while(@limit2 > 0 && (@next == @previous || array_contains(@try, @next)));
						if(@limit2 < 1){
							msg('Room selector hit limit!');
						}
						@try[] = @next;
					} else {
						// go back one if we haven't already
						@next = @previous;
					}
				}
			}

			// Plan room
			foreach(@n: @room in @rooms){
				if(@n == 0){
					continue();
				}
				@r = @room['r1'];
				@c = @room['c1'];
				@height = rand(3, @maxHeight + 1);
				@roomwidth = @room['roomwidth'];
				@roomlength = @room['roomlength'];
				@rowOdd = null;
				@columnOdd = null;
				for(@r2 = @r - 1, @r2 <= @roomlength + @r, @r2++) {
					for(@c2 = @c - 1, @c2 <= @roomwidth + @c, @c2++) {
						if(@r2 >= @r && @r2 < @roomlength + @r
						&& @c2 >= @c && @c2 < @roomwidth + @c) {
							@heightMap[@c2][@r2] = @height;
							if(@materialMap[@c2 + 1][@r2] == 'door'
							|| @materialMap[@c2 - 1][@r2] == 'door'
							|| @materialMap[@c2][@r2 + 1] == 'door'
							|| @materialMap[@c2][@r2 - 1] == 'door') {
								@materialMap[@c2][@r2] = 'room';
							} else {
								switch(integer(srand(@random) * 100)) {
									case 0..8:
										if((!is_null(@rowOdd) && (@rowOdd != @r2 % 2 || @columnOdd != @c2 % 2))
										|| @roomlength == 1
										|| @roomwidth == 1) {
											@materialMap[@c2][@r2] = 'room';
										} else {
											@materialMap[@c2][@r2] = 'column';
											if(is_null(@rowOdd)) {
												@rowOdd = @r2 % 2;
												@columnOdd = @c2 % 2;
											}
										}
									case 9..11:
										@materialMap[@c2][@r2] = 'chest';
									case 12:
										@materialMap[@c2][@r2] = 'utility';
									case 13..17:
										@materialMap[@c2][@r2] = 'decor';
									default:
										@materialMap[@c2][@r2] = 'room';
								}
							}
						} else if(@materialMap[@c2][@r2] !== 'door') {
							@materialMap[@c2][@r2] = 'wall';
						}
					}
				}
			}

			@mobTypes = _spawner_mobs(@level);
			@materials = _materials(@level);
			@loot = _loot(@level);

			// Build dungeon level
			for(@z = 0, @z < @length * @scale, @z++) {
				sleep(0.05);
				x_run_on_main_thread_later(closure(){
					for(@x = 0, @x < @width * @scale, @x++) {
						@y = @coords[1][1] + (@level * (@maxHeight + 3));
						@r = floor(@z / @scale);
						@c = floor(@x / @scale);
						@height = @heightMap[@c][@r];

						// Floor
						@levelLoc = array(@regionMinX + @x, @y, @regionMinZ + @z, @world);
						if(@entrance && @entrance['c1'] == @c && @entrance['r1'] == @r) {
							if(@z % 2 == 0 && @x % 2 == 0) {
								set_block_at(@loc, @materials['ladder'], false);
							} else {
								set_block_at(@loc, 0, false);
							}
						} else if(@mobTypes && @materialMap[@c][@r] === 'column' && srand(@random) < 0.16) {
							set_block_at(@levelLoc, '52:0', false);
							@rand = integer(srand(@random) * array_size(@mobTypes));
							@mob = array_get(@mobTypes, @rand, 'ZOMBIE');
							set_spawner_type(@levelLoc, @mob);
						} else {
							if(@level < 2 || srand(@random) > 0.03) {
								set_block_at(@levelLoc, array_rand(@materials['floor'], 1, false)[0], false);
							} else if(@level == 2) {
								set_block_at(@levelLoc, '213', false);
							} else if(@level == 3) {
								set_block_at(@levelLoc, '8', false);
							} else {
								set_block_at(@levelLoc, array_rand(@materials['floor'], 1, false)[0], false);
							}
						}

						// Walls
						@floorHeight = @y + @height + 1;
						for(@y = @y + 1, @y <= @floorHeight, @y++) {
							@loc = array(@regionMinX + @x, @y, @regionMinZ + @z, @world);
							switch(@materialMap[@c][@r]) {
								case 'wall':
									set_block_at(@loc, array_rand(@materials['wall'], 1, false)[0], false);
								case 'room':
									if(@y == @floorHeight - 1) {
										@north = @materialMap[@c][@r - 1];
										@south = @materialMap[@c][@r + 1];
										@west = @materialMap[@c - 1][@r];
										@east = @materialMap[@c + 1][@r];
										if((@east == 'wall' || @east == 'door') && @x % 2 == 1) {
											set_block_at(@loc, @materials['edge'][0], false);
										} else if((@west == 'wall' || @west == 'door') && @x % 2 == 0) {
											set_block_at(@loc, @materials['edge'][1], false);
										} else if((@south == 'wall' || @south == 'door') && @z % 2 == 1) {
											set_block_at(@loc, @materials['edge'][2], false);
										} else if((@north == 'wall' || @north == 'door') && @z % 2 == 0) {
											set_block_at(@loc, @materials['edge'][3], false);
										} else {
											set_block_at(@loc, @materials['room'], false);
										}
									} else if(@y == @floorHeight) {
										set_block_at(@loc, @materials['ceiling'], false);
									} else {
										set_block_at(@loc, @materials['room'], false);
									}
								case 'door':
									if(@y < @floorHeight - @height + 2) {
										set_block_at(@loc, @materials['door'], false);
									} else {
										set_block_at(@loc, array_rand(@materials['wall'], 1, false)[0], false);
									}
								case 'chest':
									set_block_at(@loc, 54, false);
									@inv = array();
									foreach(@weightedLoot in @loot){
										if(srand(@random) < @weightedLoot[0]){
											if(array_index_exists(@weightedLoot[1], 'qty')
											&& is_array(@weightedLoot[1]['qty'])) {
												@item = @weightedLoot[1][];
												@item['qty'] = integer(srand(@random) * (@item['qty'][1] - @item['qty'][0]) + @item['qty'][0]);
											} else {
												@item = @weightedLoot[1];
											}
											@inv[] = @item;
										}
									}
									set_inventory(@loc, @inv);
									@materialMap[@c][@r] = 'room';
								case 'utility':
									if(@scale == 1 || (@y < @floorHeight - @height + 1 && srand(@random) < 0.6)) {
										set_block_at(@loc, array_get(@materials['utility'], integer(srand(@random) * array_size(@materials['utility'])), 0), false);
										@materialMap[@c][@r] = 'room';
									} else {
										set_block_at(@loc, @materials['room'], false);
									}
								case 'decor':
									if(@scale == 1 || (@y < @floorHeight - @height + 1 && srand(@random) < 0.6)) {
										set_block_at(@loc, array_get(@materials['decor'], integer(srand(@random) * array_size(@materials['decor'])), 0), false);
										@materialMap[@c][@r] = 'room';
									} else {
										set_block_at(@loc, @materials['room'], false);
									}
								case 'column':
									set_block_at(@loc, @materials['column'], false);
								case 'ladder':
									if(@z % 2 == 0 && @x % 2 == 0) {
										set_block_at(@loc, @materials['ladder'], false);
									} else {
										set_block_at(@loc, @materials['room'], false);
									}
								default:
									set_block_at(@loc, @materials['empty'], false);
							}
						}

						// Bedrock level divider
						@ceilingLoc = array(@regionMinX + @x, @floorHeight + 1, @regionMinZ + @z, @world);
						if(@materialMap[@c][@r] === 'ladder') {
							if(@z % 2 == 0 && @x % 2 == 0) {
								set_block_at(@ceilingLoc, @materials['ladder'], false);
							} else {
								set_block_at(@ceilingLoc, 0, false);
							}
						} else if(@materialMap[@c][@r] === 'room') {
							set_block_at(@ceilingLoc, @materials['empty'], false);
						} else {
							set_block_at(@ceilingLoc, 7, false);
						}
					}
				});
			}
		}
		sleep(0.05);
		x_run_on_main_thread_later(closure(){
			@roomid = 0;
			@distance = 0;
			foreach(@id: @room in @rooms){
				if(@room['connected'] > @distance) {
					@roomid = @id;
					@distance = @room['connected'];
				}
			}
			for(@c = 0, @c < @rooms[@roomid]['roomwidth'], @c++) {
				for(@r = 0, @r < @rooms[@roomid]['roomlength'], @r++) {
					if(@materialMap[@c + @rooms[@roomid]['c1']][@r + @rooms[@roomid]['r1']] != 'column') {
						break(2);
					}
				}
			}
			@sx = ((@rooms[@roomid]['c1'] + @c) * @scale) + @regionMinX + 0.5;
			@sy = @coords[1][1];
			@sz = ((@rooms[@roomid]['r1'] + @r) * @scale) + @regionMinZ + 0.5;
			@ex = (@rooms[0]['c1'] * @scale) + @regionMinX + 0.5;
			@ey = @coords[1][1];
			@ez = (@rooms[0]['r1'] * @scale) + @regionMinZ + 0.5;
			_set_locations(array(@sx, @sy, @sz, @world), array(@ex, @ey, @ez, @world));
			res_free_resource(@random);
			_remove_region_entities(@region, array(), @world);
			msg('Dungeon generation complete!');
		});

	}); // End thread
}
