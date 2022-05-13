<!
	description: An implementation of John Conways Game of Life. Supports multiple types of competing life.;
	requiredExtensions: SKCompat;
	author: PseudoKnight;
>
register_command('life', array(
	description: 'Starts a Game of Life in the "life" region',
	usage: '/life <iterations> [sleep_ticks=10] [walls=wrap|empty|alive]',
	permission: 'command.life',
	tabcompleter: closure(@alias, @sender, @args) {
		if(array_size(@args) == 3) {
			return(_strings_start_with_ic(array('wrap', 'empty', 'alive'), @args[-1]));
		}
		return(array());
	},
	executor: closure(@alias, @sender, @args) {
		@commandBlock = get_command_block();
		@world = if(@commandBlock, @commandBlock['world'], pworld());
		if(!sk_region_exists(@world, 'life')) {
			die(color('red').'Define a flat region by the name "life" to play the game on.');
		}
		@coords = sk_region_info('life', @world, 0);

		// Define arguments
		if(array_size(@args) < 1 || !is_integral(@args[0])) {
			return(false);
		}
		@iterations = integer(@args[0]);
		@sleepMS = integer(array_get(@args, 1, 10)) * 50 - 50; // Convert to ms, minus 1 tick
		@walls = array_get(@args, 2, 'wrap');

		// Define the lowest corner of the region, except use the highest y
		@xMin = @coords[1][0];
		@y = @coords[0][1];
		@zMin = @coords[1][2];

		// Define the width and height of the grid 
		@xWidth = @coords[0][0] - @coords[1][0] + 1;
		@zWidth = @coords[0][2] - @coords[1][2] + 1;

		if(@xWidth > 128 || @zWidth > 128) {
			die(color('red').'The region is too large. (max width: 128)');
		}
		if(@xWidth < 3 || @zWidth < 3) {
			die(color('red').'The region is too small. (min width: 3)');
		}

		// Define the possible block types
		// This can include any number of block types
		// as long as the first type is AIR.
		@blockTypes = array(
			// Empty cell at index 0
			'AIR',
			// Different color options that could be used for multiple players
			'WHITE_CONCRETE',
			'ORANGE_CONCRETE',
			'MAGENTA_CONCRETE',
			'LIGHT_BLUE_CONCRETE',
			'YELLOW_CONCRETE',
			'LIME_CONCRETE',
			'PINK_CONCRETE',
			'CYAN_CONCRETE',
			'BLUE_CONCRETE',
			'PURPLE_CONCRETE',
			'GREEN_CONCRETE',
			'BROWN_CONCRETE',
			'RED_CONCRETE',
			 // Slime can be used for non-player gaia
			'SLIME_BLOCK'
		);

		// Define our grid using existing blocks
		@grid = array();
		@readLoc = array(@xMin, @y, @zMin, @world);
		for(@x = 0, @x < @xWidth, @x++) {
			@subArray = array();
			@grid[] = @subArray;
			@readLoc[0] = @xMin + @x;
			for(@z = 0, @z < @zWidth, @z++) {
				@readLoc[2] = @zMin + @z;
				@subArray[] = array_index(@blockTypes, get_block(@readLoc)) ||| 0;
			}
		}

		x_new_thread('life', closure() {
			while(@iterations-- > 0) {
				@startTime = time();
				@gridChanges = array();
				for(@x = 0, @x < @xWidth, @x++) {
					for(@z = 0, @z < @zWidth, @z++) {
						// Count different types of life separately
						@count = array_resize(array(), array_size(@blockTypes), 0);
						@current = @grid[@x][@z];

						// Loop through adjacent grid locations
						// respecting wrapping and other wall states
						for(@rx = @x - 1, @rx <= @x + 1, @rx++) {
							if(@walls != 'wrap' && (@rx < 0 || @rx == @xWidth)) {
								if(@walls == 'alive') {
									@count[@current] += 3;
								}
								continue();
							}
							for(@rz = @z - 1, @rz <= @z + 1, @rz++) {
								if(@walls != 'wrap' && (@rz < 0 || @rz == @zWidth)) {
									if(@walls == 'alive') {
										@count[@current]++;
									}
									continue();
								}
								@blockType = @grid[if(@rx == @xWidth, 0, @rx)][if(@rz == @zWidth, 0, @rz)];
								@count[@blockType]++;
							}
						}

						// Prepare grid changes based on current state
						if(@current) { // If current cell has life
							if(@count[@current] < 3) {
								// Underpopulation of current life form
								@gridChanges[] = array(@x, @z, 0, array(particle: 'FALLING_DUST', block: @blockTypes[@current]));
							} else {
								@total = array_reduce(@count, closure(@this, @next) {
									return(@this + @next);
								});
								@total -= @count[0]; // Do not count empty cells
								if(@total > 4) {
									// Overpopulation of any life form
									@gridChanges[] = array(@x, @z, 0, if(@total != @count[@current], 'EXPLOSION_LARGE', null));
								}
							}
						} else { // No life here
							@indexes = array_indexes(@count, 3); // Get life forms that have 3 neighbors
							if(@indexes && @indexes[0]) {
								if(array_size(@indexes) == 1) {
									 // Birth of a specific life form
									@gridChanges[] = array(@x, @z, @indexes[0], null);
								} else {
									 // Conflict between multiple life forms, indicated by explosion particle
									@gridChanges[] = array(@x, @z, 0, 'EXPLOSION_LARGE');
								}
							}
						}
					}
				}

				// Apply grid changes and prepare block changes and particles
				@blockChanges = array();
				foreach(@change in @gridChanges) {
					@x = @change[0];
					@z = @change[1];
					@value = @change[2];
					@grid[@x][@z] = @value;
					@blockChanges[] = array(
						x: @xMin + @x,
						y: @y, 
						z: @zMin + @z,
						world: @world, 
						type: @blockTypes[@value],
						particle: @change[3]
					);
				}

				if(!@blockChanges) {
					die();
				}
				// Queue block changes, which forces to main thread
				queue_push(iclosure(@blocks = @blockChanges) {
					array @block;
					foreach(@block in @blocks) {
						set_block(@block, @block['type']);
						if(@block['particle']) {
							@block['x'] += rand();
							@block['y'] += rand();
							@block['z'] += rand();
							spawn_particle(@block, @block['particle']);
						}
					}
					foreach(@player in players_in_radius(@block, 64)) {
						play_sound(ploc(@player), array(
							sound: 'ENTITY_CHICKEN_EGG',
							pitch: 0.5 + 1.5 * rand()
						), @player);
					}
				}, 'life');
				if(@sleepMS) {
					queue_delay(@sleepMS, 'life');
				}
			}
		});
	}
));
