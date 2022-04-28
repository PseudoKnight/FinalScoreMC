<!
	description: An implementation of John Conway's Game of Life. Supports multiple types of competing life.;
	requiredExtensions: SKCompat;
	author: PseudoKnight;
>
register_command('life', array(
	'description': 'Starts a Game of Life in the "life" region',
	'usage': '/life <iterations> [sleep_ticks] [walls=wrap|dead|alive]',
	'permission': 'command.life',
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		return(array());
	},
	'executor': closure(@alias, @sender, @args, @info) {
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
		@sleepMS = integer(array_get(@args, 1, 10)) * 50 - 50; // convert to ms minus 1 tick
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
		@blockTypes = array(
			'AIR', // it's dead, jim
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
			'SLIME_BLOCK' // non-player gaia
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
								if(!(@rx == @x && @rz == @z)) {
									@gx = if(@rx == @xWidth, 0, @rx);
									@gz = if(@rz == @zWidth, 0, @rz);
									@blockType = @grid[@gx][@gz];
									@count[@blockType]++;
								}
							}
						}

						if(@current) { // if current cell has life
							if(@count[@current] < 2) { // underpopulation of current type
								@gridChanges[] = array(@x, @z, 0, array('particle': 'FALLING_DUST', 'block': @blockTypes[@current]));
							} else {
								@total = array_reduce(@count, closure(@this, @next) {
									return(@this + @next);
								});
								@total -= @count[0]; // don't count empty cells
								if(@total > 3) { // overpopulation of any type
									@gridChanges[] = array(@x, @z, 0, if(@count[@current] < 4, 'EXPLOSION_LARGE', null));
								}
							}
						} else { // no life here
							@index = array_index(@count, 3); // get first life type that has 3 neighbors
							if(@index) { // birth
								@gridChanges[] = array(@x, @z, @index, null);
							}
						}
					}
				}

				@blockChanges = array();
				foreach(@change in @gridChanges) {
					@x = @change[0];
					@z = @change[1];
					@value = @change[2];
					@grid[@x][@z] = @value;
					@blockChanges[] = array(
						'x': @xMin + @x,
						'y': @y, 
						'z': @zMin + @z,
						'world': @world, 
						'type': @blockTypes[@value],
						'particle': @change[3]
					);
				}

				if(!@blockChanges) {
					die();
				}
				queue_push(iclosure(@blocks = @blockChanges) {
					array @block;
					foreach(@block in @blocks) {
						set_block(@block, @block['type']);
						if(@block['particle']) {
							@block['x'] += 0.5;
							@block['y'] += 0.5;
							@block['z'] += 0.5;
							spawn_particle(@block, @block['particle']);
						}
					}
					play_sound(@block, array(
						'sound': 'ENTITY_CHICKEN_EGG',
						'pitch': clamp(0.5 + 1.5 * (array_size(@blocks) / 100), 0.5, 2.0),
						'volume': 2
					));
				}, 'life');
				if(@sleepMS) {
					queue_delay(@sleepMS, 'life');
				}
			}
		});
	}
));
