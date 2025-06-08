register_command('lava', array(
	description: 'Creates and propagates special lava at the specified tickspeed.',
	usage: '/lava [~x ~y ~z] <ticksPerUpdate> <tickDuration>',
	permission: 'command.cb.extended',
	tabcompleter: _create_tabcompleter(array('<ticks>')),
	executor: closure(@alias, @player, @args) {
		if(array_size(@args) < 2) {
			return(false);
		}
		@loc = get_command_block();
		if(!@loc) {
			@loc = ptarget_space();
		} else {
			if(array_size(@args) < 4) {
				return(false);
			}
			@loc = _relative_coords(@loc, @args[0], @args[1], @args[2]);
		}
		@ticks = integer(@args[-2]);
		if(@ticks < 1) {
			msg('Ticks per update must be above zero.');
			return(false);
		}
		@duration = integer(@args[-1])
		if(@duration < 1) {
			msg('Tick duration must be above zero.');
			return(false);
		}
		set_blockdata(@loc, 'lava', false);
		play_sound(@loc, array(sound: 'ENTITY_GENERIC_EXPLODE', pitch: 0.5, volume: 8));
		@effectLoc = @loc[];
		@effectLoc['x'] += 0.5;
		@effectLoc['z'] += 0.5;
		@effectLoc['y'] += 0.5;
		spawn_particle(@effectLoc, array(particle: 'EXPLOSION_LARGE', force: true));
		spawn_particle(@effectLoc, array(particle: 'LAVA', count: 20, xoffset: 1.0, zoffset: 1.0, yoffset: 0.5, force: true));
		@loc['level'] = 8;
		@updates = array(@loc);
		@limit = array(256);
		@height = array(@loc['y']);
		set_interval(@ticks * 50, closure(){
			if(@limit[0]-- < 1) {
				clear_task();
			}
			@time = time();
			foreach(@index: @loc in @updates) {
				if(array_index_exists(@loc, 'remove')) {
					if(@loc['remove'] < @time) {
						set_block(@loc, 'air', false);
						@updates[@index] = null;
					}
				} else {
					@down = location_shift(@loc, 'down');
					@blockBelow = get_block(@down);
					if(@blockBelow === 'AIR') {
						@down['level'] = 8;
						@updates[] = @down;
						@height[0] = min(@height[0], @down['y']);
						set_blockdata(@down, array(block: 'lava', level: 8), false);
					} else if(@blockBelow !== 'LAVA' && @down['y'] < @height[0]) {
						@level = @loc['level'] - 2;
						if(@level > 0) {
							foreach(@dir in array_rand(array('north', 'south', 'east', 'west'), 4, false)) {
								@adjacent = location_shift(@loc, @dir);
								if(get_block(@adjacent) === 'AIR') {
									@adjacent['level'] = @level;
									@updates[] = @adjacent;
									set_blockdata(@adjacent, array(block: 'lava', level: 8 - @level), false);
								}
							}
						}
					}
					@loc['remove'] = @time + (@duration * 50);
				}
			}
			foreach(@index: @update in @updates) {
				if(is_null(@update)) {
					array_remove(@updates, @index);
				}
			}
			if(!@updates) {
				clear_task();
			}
		});
	}
));