proc _materials(@level) {
	switch(@level) {
		case 0:
			return(associative_array(
				' ': '7:0',
				'wall': array('24:0', '24:2'),
				'room': '0:0',
				'door': '0:0',
				'column': '24:1',
				'stairs': '128:2',
				'ceiling': '24:0',
				'floor': '172:0',
				'utility': array(58),
				'decor': array(31),
			));
		case 1:
			return(associative_array(
				' ': '7:0',
				'wall': array('162'),
				'room': '0:0',
				'door': '0:0',
				'column': '162:1',
				'stairs': '164:2',
				'ceiling': '161:1',
				'floor': '2',
				'utility': array(58),
				'decor': array('18:2'),
			));
		case 2:
			return(associative_array(
				' ': '7:0',
				'wall': array('112'),
				'room': '0:0',
				'door': '0:0',
				'column': '113',
				'stairs': '114:2',
				'ceiling': '112:0',
				'floor': '112:1',
				'utility': array(61, '145:2'),
				'decor': array('118:2'),
			));
		case 3:
			return(associative_array(
				' ': '7:0',
				'wall': array('1:0', '98:0', '98:1', '98:2', '98:3', '97:4'),
				'room': '0:0',
				'door': '0:0',
				'column': '47:0',
				'stairs': '109:2',
				'ceiling': '98:0',
				'floor': '98:1',
				'utility': array('58', '116', '117', '118:2'),
				'decor': array('66'),
			));
		default:
			return(associative_array(
				' ': '7:0',
				'wall': array(201),
				'room': '0:0',
				'door': '0:0',
				'column': 202,
				'stairs': '203:2',
				'ceiling': 201,
				'floor': 201,
				'utility': array('116'),
				'decor': array('199'),
			));
	}
}

proc _spawner_mobs(@level) {
	switch(@level) {
		case 0:
			return(array('ENDER_CRYSTAL', 'ENDERMITE', 'ZOMBIE'));
		case 1:
			return(array('CAVE_SPIDER', 'SPIDER', 'SILVERFISH'));
		case 2:
			return(array('PIG_ZOMBIE', 'MAGMA_CUBE', 'BLAZE'));
		case 3:
			return(array('ENDER_CRYSTAL', 'ZOMBIE',	'SPIDER', 'SILVERFISH', 'SKELETON', 'BLAZE', 'WITCH', 'CREEPER'));
		default:
			return(array('ENDER_CRYSTAL', 'ENDERMITE', 'ENDERMAN', 'GUARDIAN', 'SHULKER'));
	}
}

proc _generate_dungeon(@region, @world, @level, @scale, @seed) {
	if(!@seed) {
		@seed = time();
	}

	@minroomsize = 3
	@maxroomsize = 11
	@height = 4

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

		foreach(@level in range(@level)) {
			// Define grid
			@materialMap = array();
			@roomMap = array();
			for(@c = 0, @c < @width, @c++) {
				@materialMap[@c] = array();
				@roomMap[@c] = array();
				for(@r = 0, @r < @length, @r++) {
					@type = ' ';
					if(@r == 0 || @r == @length - 1
					|| @c == 0 || @c == @width - 1) {
						@type = 'wall';
					}
					@materialMap[@c][@r] = @type;
					@roomMap[@c][@r] = -1;
				}
			}

			// Define rooms
			@rooms = array();

			// Place entrance stairway
			@c = (integer(srand(@random) * ((@width / 2) - 1)) * 2) + 1;
			@r = (integer(srand(@random) * ((@length / 2) - 5)) * 2) + 3;
			for(@r2 = @r - 1, @r2 <= 5 + @r, @r2++) {
				for(@c2 = @c - 1, @c2 <= 1 + @c, @c2++) {
					if(@c2 == @c && @r2 >= @r - 1 && @r2 < @r + 5) {
						if(@r2 == @r - 1) {
							@materialMap[@c2][@r2] = 'door';
						} else {
							@materialMap[@c2][@r2] = 'stairs';
						}
						@roomMap[@c2][@r2] = 0;
					} else {
						@materialMap[@c2][@r2] = 'wall';
					}
				}
			}

			@rooms[] = array(
				'r1': @r,
				'c1': @c,
				'roomwidth': 5,
				'roomlength': 1,
				'connected': false,
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
							'connected': false,
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
			@limit = 700;
			while(@unconnected) {
				@limit--;
				if(@limit < 0){
					die('Hit room connector limits! Rooms left: '.array_size(@unconnected).'/'.array_size(@rooms).'!');
				}

				array_remove_values(@unconnected, @next);
				@rooms[@next]['connected'] = true;

				@r = @rooms[@next]['r1'];
				@c = @rooms[@next]['c1'];
				@roomwidth = @rooms[@next]['roomwidth'];
				@roomlength = @rooms[@next]['roomlength'];

				@success = false;
				foreach(@dir in array_rand(range(4), 4, false)) {
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
						foreach(@next in array_rand(range(array_size(@rooms)), array_size(@rooms), false)){
							if(@next != @previous && @rooms[@next]['connected'] && !array_contains(@try, @next)){
								@try[] = @next;
								break();
							}
						}
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
				@roomwidth = @room['roomwidth'];
				@roomlength = @room['roomlength'];
				for(@r2 = @r - 1, @r2 <= @roomlength + @r, @r2++) {
					for(@c2 = @c - 1, @c2 <= @roomwidth + @c, @c2++) {
						if(@r2 >= @r && @r2 < @roomlength + @r
						&& @c2 >= @c && @c2 < @roomwidth + @c) {
							switch(integer(srand(@random) * 100)) {
								case 0..3:
									if(@roomlength == 1
									|| @roomwidth == 1
									|| @materialMap[@c2 + 1][@r2] == 'door'
									|| @materialMap[@c2 - 1][@r2] == 'door'
									|| @materialMap[@c2][@r2 + 1] == 'door'
									|| @materialMap[@c2][@r2 - 1] == 'door') {
										@materialMap[@c2][@r2] = 'room';
									} else {
										@materialMap[@c2][@r2] = 'column';
									}
								case 4..6:
									@materialMap[@c2][@r2] = 'chest';
								case 7:
									@materialMap[@c2][@r2] = 'utility';
								case 8..12:
									@materialMap[@c2][@r2] = 'decor';
								default:
									@materialMap[@c2][@r2] = 'room';
							}
						} else if(@materialMap[@c2][@r2] !== 'door') {
							@materialMap[@c2][@r2] = 'wall';
						}
					}
				}
			}

			@mobTypes = _spawner_mobs(@level);
			@materials = _materials(@level);

			// Build dungeon level
			for(@z = 0, @z < @length * @scale, @z++) {
				sleep(0.05);
				x_run_on_main_thread_later(closure(){
					for(@x = 0, @x < @width * @scale, @x++) {
						@y = @coords[1][1] + (@level * (@height + 3));
						@r = floor(@z / @scale);
						@c = floor(@x / @scale);

						// Floor
						@levelLoc = array(@regionMinX + @x, @y, @regionMinZ + @z, @world);
						if(@materialMap[@c][@r] === 'column' && srand(@random) < 0.16) {
							set_block_at(@levelLoc, '52:0', false)
							@rand = integer(srand(@random) * array_size(@mobTypes));
							@mob = array_get(@mobTypes, @rand, 'ZOMBIE');
							set_spawner_type(@levelLoc, @mob);
						} else {
							if(@level < 2 || srand(@random) > 0.03) {
								set_block_at(@levelLoc, @materials['floor'], false);
							} else if(@level == 2) {
								set_block_at(@levelLoc, '213', false);
							} else if(@level == 3) {
								set_block_at(@levelLoc, '8', false);
							} else {
								set_block_at(@levelLoc, @materials['floor'], false);
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
									if(@level != 1 || srand(@random) > 0.03) {
										set_block_at(@loc, @materials['room'], false);
									} else {
										set_block_at(@loc, '30', false);
									}
								case 'door':
									if(@y < @floorHeight - 2) {
										set_block_at(@loc, @materials['door'], false);
									} else {
										set_block_at(@loc, array_rand(@materials['wall'], 1, false)[0], false);
									}
								case 'chest':
									set_block_at(@loc, 54, false);
									set_inventory(@loc, array(
										if(srand(@random) < 0.50, associative_array('name': 'TORCH', 'qty': integer(srand(@random) * 16) + 1), null),
										if(srand(@random) < 0.40, associative_array('name': 'BREAD', 'qty': integer(srand(@random) * 7) + 1), null),
										if(srand(@random) < 0.35, associative_array('name': 'GOLDEN_APPLE'), null),
										if(srand(@random) < 0.25, associative_array('name': 'STONE_PICKAXE', 'qty': 1, 'data': 128), null),
										if(srand(@random) < 0.25, associative_array('name': 'DIAMOND_AXE', 'data': 1546), null),
										if(srand(@random) < 0.20, associative_array('name': 'DIAMOND_SWORD', 'data': 1546), null),
										if(srand(@random) < 0.09, associative_array('name': 'GOLD_HELMET', 'data': 60), null),
										if(srand(@random) < 0.08, associative_array('name': 'GOLD_CHESTPLATE', 'data': 50), null),
										if(srand(@random) < 0.05, associative_array('name': 'GOLD_LEGGINGS', 'data': 50), null),
										if(srand(@random) < 0.08, associative_array('name': 'GOLD_BOOTS', 'data': 50), null),
										if(srand(@random) < 0.03, associative_array('name': 'CHAINMAIL_LEGGINGS', 'data': 100), null),
										if(srand(@random) < 0.01, associative_array('name': 'IRON_CHESTPLATE', 'data': 150), null),
										if(srand(@random) < 0.01, associative_array('name': 'IRON_LEGGINGS', 'data': 150), null),
										if(srand(@random) < 0.01, associative_array('name': 'IRON_BOOTS', 'data': 150), null),
										if(srand(@random) < 0.03, associative_array('name': 'SHIELD', 'data': 300), null),
										if(srand(@random) < 0.03, associative_array('name': 'INK_SACK', 'data': 4, 'qty': integer(srand(@random) * 3) + 1), null),
									));
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
								case 'stairs':
									if(@z - (@rooms[0]['r1'] * @scale) - 1 == @y - @floorHeight + @height + 1) {
										set_block_at(@loc, @materials['stairs'], false);
									} else {
										set_block_at(@loc, @materials['room'], false);
									}
								default:
									set_block_at(@loc, @materials[' '], false);
							}
						}

						// Ceiling
						@ceilingLoc = array(@regionMinX + @x, @floorHeight, @regionMinZ + @z, @world);
						if(@materialMap[@c][@r] === 'stairs') {
							if(@z - (@rooms[0]['r1'] * @scale) - 1 == @height + 1) {
								set_block_at(@ceilingLoc, @materials['stairs'], false);
							} else if(@z - (@rooms[0]['r1'] * @scale) - 1 < @height + 1) {
								set_block_at(@ceilingLoc, @materials['room'], false);
							}
						} else {
							set_block_at(@ceilingLoc, @materials['ceiling'], false);
						}

						// Bedrock level divider
						@ceilingLoc[1]++;
						if(@materialMap[@c][@r] === 'stairs') {
							if(@z - (@rooms[0]['r1'] * @scale) - 1 == @height + 2) {
								set_block_at(@ceilingLoc, @materials['stairs'], false);
							} else if(@z - (@rooms[0]['r1'] * @scale) - 1 < @height + 2) {
								set_block_at(@ceilingLoc, @materials['room'], false);
							}
						} else {
							set_block_at(@ceilingLoc, 7, false);
						}
					}
				});
			}
		}
		sleep(0.05);
		x_run_on_main_thread_later(closure(){
			res_free_resource(@random);
			_remove_region_entities(@region, array(), @world);
			msg('Dungeon generation complete!');
		});

	}); // End thread
}
