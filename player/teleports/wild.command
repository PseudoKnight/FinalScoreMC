register_command('wild', array(
	'description': 'Teleports a player to a random location within a survival world.',
	'aliases': array('rtp'),
	'usage': '/wild [player]',
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		return(array());
	},
	'executor': closure(@alias, @sender, @args, @info) {
		@player = player();
		if(@args) {
			if(!has_permission('command.wild.other')) {
				die(color('red').'You do not have permission to teleport another player.');
			}
			@player = _find_player(@args[0]);
		}

		@world = pworld(@player);

		if(!_is_survival_world(@world) || world_info(@world)['environment'] != 'NORMAL' || @world == 'outworld') {
			@world = 'psi';
		}

		# Get target location
		@worldBorder = get_world_border(@world);

		@width = integer(@worldBorder['width']);
		@xMin = integer(@worldBorder['center']['x'] - @width / 2);
		@zMin = integer(@worldBorder['center']['z'] - @width / 2);
		@xMax = integer(@worldBorder['center']['x'] + @width / 2);
		@zMax = integer(@worldBorder['center']['z'] + @width / 2);

		// Make sure it's within WorldBorder plugin's border too
		@border = _get_worldborder(@world);
		if(@border) {
			@xCenter = @border['x'];
			@zCenter = @border['z'];
			@xRadius = @border['radiusX'];
			@zRadius = @border['radiusZ'];

			// limit to within both world borders
			@xMin = max(@xMin, @xCenter - @xRadius);
			@xMax = min(@xMax, @xCenter + @xRadius);
			@zMin = max(@zMin, @zCenter - @zRadius);
			@zMax = min(@zMax, @zCenter + @zRadius);
		}

		// border buffer
		@xMin += 128;
		@zMin += 128;
		@xMax -= 128;
		@zMax -= 128;

		@tries = 20;
		@target = null;
		while(@tries-- > 0) {
			@x = @xMin + rand(@xMax - @xMin);
			@z = @zMin + rand(@zMax - @zMin);
			@target = get_highest_block_at(@x, @z, @world);
			if(@target['y'] > 62 && get_block(@target) != 'LAVA' && !sk_regions_at(@target)) {
				// not in the sea, not in lava, not in a region
				break();
			}
		}

		if(@tries == 0) {
			die(color('red').'Failed to find a safe location in 20 attempts.');
		}

		@target['x'] += 0.5;
		@target['z'] += 0.5;
		include('includes.library/teleports.ms');
		_warmuptp(@player, @target, false);
	}
));