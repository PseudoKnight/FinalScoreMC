execute(iclosure(){
	proc _portal(@color, @portals) {
		if(pworld() != 'dev' || pmode() != 'ADVENTURE') {
			return();
		}
		if(!has_bind('portalgun'.player())) {

			proc _rotate_yaw(@portals, @color, @yaw) {
				@entrance = @portals[@color]['exit'];
				@exit = @portals[if(@color == 'blue', 'orange', 'blue')]['exit'];
				if(@entrance['face'] == @exit['face']) {
					return(array(@exit['x'], @exit['y'], @exit['z'], @exit['world'], @yaw + 180, 0));
				}
				return(array(@exit['x'], @exit['y'], @exit['z'], @exit['world'], @yaw, 0));
			}

			bind('player_move', array('id': 'portalgun'.player()), array('player': player(), 'threshold': 0), @event, @portals) {
				@from = @event['from'];
				@to = @event['to'];
				if(@to['world'] != 'dev') {
					unbind();
					die();
				}
				@dist = distance(@from, @to);
				if(@dist > 1) {
					die();
				}
				@to['yaw'] = get_yaw(@from, @to);
				@to['pitch'] = get_pitch(@from, @to);
				if(@to['yaw'] == math_const('NaN')) {
					@to['yaw'] = @to[4];
				}
				@trace = ray_trace(@to, @dist + 0.4);
				if(@trace['hitblock']) {
					@block = @trace['block'];
					if(@portals['orange']) {
						foreach(@b in @portals['orange']['blocks']) {
							if(is_array(@b) && array_subset_of(@block, @b)) {
								@newLoc = _rotate_yaw(@portals, 'orange', @to['yaw']);
								relative_teleport(@newLoc);
								//set_pvelocity(get_vector(@newLoc));
							}
						}
					}
					if(@portals['blue']) {
						foreach(@b in @portals['blue']['blocks']) {
							if(is_array(@b) && array_subset_of(@block, @b)) {
								@newLoc = _rotate_yaw(@portals, 'blue', @to['yaw']);
								relative_teleport(@newLoc);
								//set_pvelocity(get_vector(@newLoc));
							}
						}
					}
				}
			}
		}

		@trace = ray_trace(32);

		if(!@trace['hitblock']) {
			die();
		}

		@block = @trace['block'];
		if(get_block(@block) != 'WHITE_CONCRETE') {
			play_sound(ploc(), array('sound': 'ENTITY_SHULKER_CLOSE'));
			die();
		}

		@origin = location_shift(@trace['origin'], 'down', 0.3);
		@loc = @trace['location'];
		@face = @trace['hitface'];

		@portal = @block[];
		
		@portal['x'] += 0.5;
		@portal['z'] += 0.5;

		@extension = null;
		if(@face != 'UP' && @face != 'DOWN') {
			@portal = location_shift(@portal, @face);
			if(round(@loc['y']) == floor(@loc['y'])) {
				@extension = location_shift(@block, 'down');
				@portal['y'] -= 1;
			} else {
				@extension = location_shift(@block, 'up');
			}
		} else if(@face == 'UP') {
			@portal['y'] += 1;
		} else if(@face == 'DOWN') {
			@portal['y'] -= 2;
		}

		@portal['face'] = @face;

		// clean up old portal blocks before modifying the portals array
		if(@portals[@color]) {
			@oldLocs = @portals[@color]['blocks'];
			if(!is_null(@oldLocs)) {
				foreach(@p in players_in_radius(@block, 48)) {
					foreach(@b in @oldLocs) {
						if(is_array(@b)) {
							psend_block_change(@p, @b, get_blockdata_string(@b));
						}
					}
				}
			}
		}

		@portals[@color] = array('exit': @portal, 'blocks': array(@block, @extension));

		// play effects
		play_sound(@loc, array('sound': 'ENTITY_SHULKER_SHOOT', 'pitch': 1.3, 'volume': 3));
		play_sound(@loc, array('sound': 'ENTITY_EVOKER_CAST_SPELL', 'pitch': 0.6, 'volume': 3));
		@particleLoc = location_shift(@block[], @face, 0.55);
		@particleLoc['x'] += 0.5;
		@particleLoc['y'] += 0.5;
		@particleLoc['z'] += 0.5;
		spawn_particle(@particleLoc, array(
			'particle': 'BLOCK_DUST', 
			'count': 20, 
			'xoffset': if(@face != 'EAST' && @face != 'WEST', 0.7, 0.0),
			'zoffset': if(@face != 'NORTH' && @face != 'SOUTH', 0.7, 0.0),
			'yoffset': if(@face != 'UP' && @face != 'DOWN', 0.7, 0.0),
			'block': @color.'_concrete'
		));

		// render particle trail
		@distance = distance(@origin, @loc);
		@maxParticles = min(ceil(@distance), 20);
		@distance /= @maxParticles;
		@particles = 0;
		while(@particles++ <= @maxParticles) {
			@origin = location_shift(@origin, @loc, @distance);
			spawn_particle(@origin, array('particle': 'FALLING_DUST', 'block': @color.'_concrete'));
		}

		// set new portal blocks
		set_timeout(50, closure(){
			foreach(@p in players_in_radius(@block, 48)) {
				psend_block_change(@p, @block, @color.'_concrete');
				if(@extension) {
					psend_block_change(@p, @extension, @color.'_concrete');
				}
			}
		});
	}

	@portals = array(
		'orange': null,
		'blue': null,
	);

	bind('player_interact', array('priority': 'LOW'), array('itemname': 'LANTERN'), @event, @portals) {
		_portal('orange', @portals);
	}

	bind('player_interact', array('priority': 'LOW'), array('itemname': 'SOUL_LANTERN'), @event, @portals) {
		_portal('blue', @portals);
	}

});