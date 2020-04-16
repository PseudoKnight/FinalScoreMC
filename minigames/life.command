register_command('life', array(
	'description': 'Starts a game of life in the "life" region',
	'usage': '/life <iterations> [period_ms]',
	'permission': 'command.life',
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		return(array());
	},
	'executor': closure(@alias, @sender, @args, @info) {
		if(!sk_region_exists('life')) {
			die(color('red').'Define a flat region by the name "life" to play the game on.');
		}
		@world = pworld();
		@coords = sk_region_info('life', @world, 0);

		// Define arguments
		if(array_size(@args) < 1 || !is_integral(@args[0])) {
			return(false);
		}
		@iterations = integer(@args[0]);
		@sleep = integer(array_get(@args, 1, 500)) / 1000;

		// Define the lowest corner of the region, except use the highest y
		@xMin = @coords[1][0];
		@y = @coords[0][1];
		@zMin = @coords[1][2];

		// Define the width and height of the grid 
		@xWidth = @coords[0][0] - @coords[1][0] + 1;
		@zWidth = @coords[0][2] - @coords[1][2] + 1;

		if(@xWidth > 128 || @zWidth > 128) {
			die(color('red').'The region is too large.');
		}

		// Define the background block type and the block type representing life
		@emptyCell = 'AIR';
		@lifeCell = '_CONCRETE';

		/* TODO: Multiple types of life
		@colors = array(
			'AIR', // it's dead, jim
			'BLACK_CONCRETE',
			'WHITE_CONCRETE',
			'ORANGE_CONCRETE',
			'MAGENTA_CONCRETE',
			'LIGHT_BLUE_CONCRETE',
			'YELLOW_CONCRETE',
			'LIME_CONCRETE',
			'PINK_CONCRETE',
			'GRAY_CONCRETE',
			'LIGHT_GRAY_CONCRETE',
			'CYAN_CONCRETE',
			'BLUE_CONCRETE',
			'PURPLE_CONCRETE',
			'GREEN_CONCRETE',
			'BROWN_CONCRETE',
			'RED_CONCRETE'
		);
		*/

		// Define our grid using existing blocks
		@grid = array();
		@readLoc = array(@xMin, @y, @zMin, @world);
		for(@x = 0, @x < @xWidth, @x++) {
			@subArray = array();
			@grid[] = @subArray;
			@readLoc[0] = @xMin + @x;
			for(@z = 0, @z < @zWidth, @z++) {
				@readLoc[2] = @zMin + @z;
				@subArray[] = string_ends_with(get_block(@readLoc), @lifeCell);
				// TODO: @subArray[] = array_index(@blocks, get_block(@readLoc)) ||| 0;
			}
		}

		x_new_thread('life', closure() {
			while(@iterations-- > 0) {
				@start = time();
				@gridChanges = array();
				for(@x = 0, @x < @xWidth, @x++) {
					for(@z = 0, @z < @zWidth, @z++) {
						// Use negative indices and width checks for grid wrapping
						@modX = if(@x == @xWidth - 1, 0, @x + 1);
						@modZ = if(@z == @zWidth - 1, 0, @z + 1);
						@count = @grid[@x - 1][@z - 1]
						+ @grid[@x][@z - 1]
						+ @grid[@modX][@z - 1]
						+ @grid[@x - 1][@z]
						+ @grid[@modX][@z]
						+ @grid[@x - 1][@modZ]
						+ @grid[@x][@modZ]
						+ @grid[@modX][@modZ];

						if(@grid[@x][@z]) { // if alive
							if(@count < 2 || @count > 3) { // under or overpopulation
								// death
								@gridChanges[] = array(@x, @z, false);
							}
						} else if(@count == 3) { // else not alive but should be
							// birth
							@gridChanges[] = array(@x, @z, true);
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
						'type': if(@value, 'WHITE'.@lifeCell, @emptyCell)
					);
				}

				x_run_on_main_thread_later(iclosure(@blocks = @blockChanges) {
					foreach(@block in @blocks) {
						set_block(@block, @block['type']);
					}
				});

				@delta = (time() - @start) / 1000;
				if(@delta < @sleep) {
					sleep(@sleep - @delta);
				}
			}
		});
	}
));
