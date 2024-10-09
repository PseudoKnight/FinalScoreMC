register_command('gateway', array(
	description: 'Creates end gateways at selection that goes to the current player position.',
	usage: '/gateway',
	permission: 'worldedit.setnbt',
	tabcompleter: closure(return(array())),
	executor: closure(@alias, @sender, @args, @info) {
		@location = entity_loc(puuid());
		@pos1 = sk_pos1();
		if(!@pos1) {
			die(color('red').'No selection point detected.');
		}
		@pos2 = sk_pos2();
		if(!@pos2) {
			die(color('red').'No selection point detected.');
		}
		@xMin = min(@pos1['x'], @pos2['x']);
		@xMax = max(@pos1['x'], @pos2['x']);
		@yMin = min(@pos1['y'], @pos2['y']);
		@yMax = max(@pos1['y'], @pos2['y']);
		@zMin = min(@pos1['z'], @pos2['z']);
		@zMax = max(@pos1['z'], @pos2['z']);
		for(@x = @xMin, @x <= @xMax, @x++) {
			for(@y = @yMin, @y <= @yMax, @y++) {
				for(@z = @zMin, @z <= @zMax, @z++) {
					@block = array(@x, @y, @z, @location['world']);
					set_block(@block, 'END_GATEWAY');
					set_end_gateway_exit(@block, @location, true);
					set_end_gateway_age(@block, math_const('LONG_MIN'));
				}
			}
		}
	}
));