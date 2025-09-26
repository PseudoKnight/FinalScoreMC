register_command('shipify', array(
	description: 'Creates a ship from blocks in selection.',
	usage: '/shipify',
	permission: 'command.shipify',
	tabcompleter: closure(return(array())),
	executor: closure(@alias, @player, @args) {
		@startTime = nano_time();
		@origin = pcursor();
		@maxBlocks = 200;
		@world = @origin['world'];
		@toProcess = array(@origin);
		@blocks = associative_array();
		@count = 0;
		@minX = @origin['x'];
		@maxX = @origin['x'];
		@minY = @origin['y'];
		@maxY = @origin['y'];
		@minZ = @origin['z'];
		@maxZ = @origin['z'];
		while(@toProcess) {
			@next = array_remove(@toProcess, 0);
			foreach(@dir in array('up', 'down', 'north', 'east', 'south', 'west')) {
				@block = location_shift(@next, @dir);
				if(get_block(@block) !== 'AIR') {
					@key = sconcat(@block['x'], @block['y'], @block['z']);
					if(!array_index_exists(@blocks, @key)) {
						@blocks[@key] = true;

						if(@block['x'] < @minX) {
							@minX = @block['x'];
						} else if(@block['x'] > @maxX) {
							@maxX = @block['x'];
						}
						if(@block['y'] < @minY) {
							@minY = @block['y'];
						} else if(@block['y'] > @maxY) {
							@maxY = @block['y'];
						}
						if(@block['z'] < @minZ) {
							@minZ = @block['z'];
						} else if(@block['z'] > @maxZ) {
							@maxZ = @block['z'];
						}

						@count++;
						@toProcess[] = @block;
					}
				}
			}
			if(@count > @maxBlocks) {
				throw('RangeException', "Too many blocks. (@maxBlocks) Is it connected to the ground?");
			}
		}
		@loc = array(
			@minX + (@maxX + 1 - @minX) / 2,
			@minY,
			@minZ + (@maxZ + 1 - @minZ) / 2,
			@world);
		// create interaction entity for right-click activation and left-click removal
		@interaction = spawn_entity('INTERACTION', 1, @loc, closure(@e) {
			set_entity_spec(@e, array(
				width: max(@maxX + 1 - @minX, @maxZ + 1 - @minZ),
				height: @maxY + 1 - @minY));
			add_scoreboard_tag(@e, 'ship');
		})[0];
		// create item display rider to store xyz scale
		@display = spawn_entity('ITEM_DISPLAY', 1, @loc, closure(@e) {
			set_entity_rider(@interaction, @e);
			set_entity_spec(@e, array(item: array(name: 'LIGHT_GRAY_STAINED_GLASS')));
			set_display_entity(@e, array(
				transformation: array(
					translation: array(x: 0.0, y: -(@maxY + 1 - @minY) / 2 - 0.0625, z: 0.0),
					scale: array(x: @maxX + 1 - @minX + 0.125, y: @maxY + 1 - @minY + 0.125, z: @maxZ + 1 - @minZ + 0.125))));
		})[0];
		set_display_entity(@display, array(
			startinterpolation: 0,
			interpolationduration: 40,
			transformation: array(
				translation: array(x: 0.0, y: -(@maxY + 1 - @minY) / 2, z: 0.0),
				scale: array(x: @maxX + 1 - @minX, y: @maxY + 1 - @minY, z: @maxZ + 1 - @minZ))));
		set_timeout(2000, closure(){
			try(set_entity_spec(@display, array(item: null)))
		});
		if(@count < 100) {
			msg(color('green')."Found ship with @count blocks.");
		} else {
			msg(color('gold')."Found ship with @count blocks. It is recommended to keep this under 100.");
		}
		console('Created a ship in '.((nano_time() - @startTime) / 1000).' microseconds.');
	}
));