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
			@dungeon = array();
			for(@c = 0, @c < @width, @c++) {
				@dungeon[@c] = array();
				for(@r = 0, @r < @length, @r++) {
					@type = ' ';
					if(@r == 0 || @r == @length - 1
					|| @c == 0 || @c == @width - 1) {
						@type = 'wall';
					}
					@dungeon[@c][@r] = @type;
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
							@dungeon[@c2][@r2] = 'door';
						} else {
							@dungeon[@c2][@r2] = 'stairs';
						}
					} else {
						@dungeon[@c2][@r2] = 'wall';
					}
				}
			}

			@rooms[] = array(
				'r1': @r,
				'c1': @c,
				'r2': @r + 5,
				'c2': @c,
			);

			@nroom = 1;

			// Place rooms
			for(@r = 1, @r < @length, @r += 2) {
				for(@c = 1, @c < @width, @c += 2) {
					if(@dungeon[@c][@r] === ' ') {
						@roomwidth = integer(srand(@random) * (((@maxroomsize - @minroomsize) / 2) + 1)) * 2 + @minroomsize;
						@roomlength = integer(srand(@random) * (((@maxroomsize - @minroomsize) / 2) + 1)) * 2 + @minroomsize;

						// Check placement
						for(@r2 = @r, @r2 < @r + @roomlength, @r2 += 2) {
							@c2 = @c;
							if(@r2 >= @length || @dungeon[@c2][@r2] !== ' ') {
								@roomlength = @r2 - @r - 1;
								break();
							}
							for(@c2 = @c, @c2 < @c + @roomwidth, @c2 += 2) {
								if(@c2 >= @width || @dungeon[@c2][@r2] !== ' ') {
									@roomwidth = @c2 - @c - 1;
									break();
								}
							}
						}

						// Save room
						@rooms[@nroom] = associative_array(
							'r1': @r,
							'c1': @c,
							'r2': @r + @roomlength,
							'c2': @c + @roomwidth,
						);

						// Add doors
						while(true) {
							if(srand(@random) > 0.5) {
								if(srand(@random) > 0.5) {
									@r2 = @r - 1;
								} else {
									@r2 = @r + @roomlength;
								}
								@c2 = @c + integer(srand(@random) * ((@roomwidth + 1) / 2)) * 2;
							} else {
								if(srand(@random) > 0.5) {
									@c2 = @c - 1;
								} else {
									@c2 = @c + @roomwidth;
								}
								@r2 = @r + integer(srand(@random) * ((@roomlength + 1) / 2)) * 2;
							}

							// Dungeon edge detection
							if(@r2 == 0 || @r2 == @length - 1
							|| @c2 == 0 || @c2 == @width - 1) {
								continue();
							}

							@dungeon[@c2][@r2] = 'door';
							break();
						}

						// Mask room
						for(@r2 = @r - 1, @r2 <= @roomlength + @r, @r2++) {
							for(@c2 = @c - 1, @c2 <= @roomwidth + @c, @c2++) {
								if(@r2 >= @r && @r2 < @roomlength + @r
								&& @c2 >= @c && @c2 < @roomwidth + @c) {
									switch(integer(srand(@random) * 100)) {
										case 0..3:
											if(@dungeon[@c2 + 1][@r2] == 'door'
											|| @dungeon[@c2 - 1][@r2] == 'door'
											|| @dungeon[@c2][@r2 + 1] == 'door'
											|| @dungeon[@c2][@r2 - 1] == 'door') {
												@dungeon[@c2][@r2] = 'room';
											} else {
												@dungeon[@c2][@r2] = 'column';
											}
										case 4..6:
											@dungeon[@c2][@r2] = 'chest';
										case 7:
											@dungeon[@c2][@r2] = 'utility';
										case 8..12:
											@dungeon[@c2][@r2] = 'decor';
										default:
											@dungeon[@c2][@r2] = 'room';
									}
								} else if(@dungeon[@c2][@r2] !== 'door') {
									@dungeon[@c2][@r2] = 'wall';
								}
							}
						}

						@nroom += 1;
						@c = @c + @roomwidth - 1;
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
						if(@dungeon[@c][@r] === 'column' && srand(@random) < 0.16) {
							set_block_at(@floorLoc, '52:0', false)
							@rand = integer(srand(@random) * array_size(@mobTypes));
							@mob = array_get(@mobTypes, @rand, 'ZOMBIE');
							set_spawner_type(@floorLoc, @mob);
						} else {
							if(@level < 2 || srand(@random) > 0.03) {
								set_block_at(@floorLoc, @materials['floor'], false);
							} else if(@level == 2) {
								set_block_at(@floorLoc, '213', false);
							} else if(@level == 3) {
								set_block_at(@floorLoc, '8', false);
							} else {
								set_block_at(@floorLoc, @materials['floor'], false);
							}
						}

						// Walls
						@floorHeight = @y + @height + 1;
						for(@y = @y + 1, @y <= @floorHeight, @y++) {
							@loc = array(@regionMinX + @x, @y, @regionMinZ + @z, @world);
							switch(@dungeon[@c][@r]) {
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
										if(srand(@random) < 0.45, associative_array('name': 'STONE_PICKAXE', 'qty': 1, 'data': 128), null),
										if(srand(@random) < 0.40, associative_array('name': 'BREAD', 'qty': integer(srand(@random) * 7) + 1), null),
										if(srand(@random) < 0.35, associative_array('name': 'GOLDEN_APPLE'), null),
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
									@dungeon[@c][@r] = 'room';
								case 'utility':
									if(@scale == 1 || (@y < @floorHeight - @height + 1 && srand(@random) < 0.6)) {
										set_block_at(@loc, array_get(@materials['utility'], integer(srand(@random) * array_size(@materials['utility'])), 0), false);
										@dungeon[@c][@r] = 'room';
									} else {
										set_block_at(@loc, @materials['room'], false);
									}
								case 'decor':
									if(@scale == 1 || (@y < @floorHeight - @height + 1 && srand(@random) < 0.6)) {
										set_block_at(@loc, array_get(@materials['decor'], integer(srand(@random) * array_size(@materials['decor'])), 0), false);
										@dungeon[@c][@r] = 'room';
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
						if(@dungeon[@c][@r] === 'stairs') {
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
						if(@dungeon[@c][@r] === 'stairs') {
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
