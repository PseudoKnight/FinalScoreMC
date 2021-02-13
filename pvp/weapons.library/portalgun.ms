execute(iclosure(){
	proc _portal(@color, @button, @portalgun, @portalExits) {
		if(pworld() != 'dev' || pmode() != 'ADVENTURE') {
			return();
		}
		if(!has_bind('portalgun'.player().@color)) {

			proc _rotate_yaw(@yaw, @portalExits, @from, @to) {
				if(@portalExits[@from]['face'] == @portalExits[@to]['face']) {
					return(array(@portalExits[@to]['x'], @portalExits[@to]['y'], @portalExits[@to]['z'], @portalExits[@to]['world'], @yaw + 180, 0));
				}
				return(array(@portalExits[@to]['x'], @portalExits[@to]['y'], @portalExits[@to]['z'], @portalExits[@to]['world'], @yaw, 0));
			}

			bind('player_move', array('id': 'portalgun'.player().@color), array('player': player(), 'threshold': 0), @event, @color, @portalgun, @portalExits) {
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
					foreach(@player: @portals in @portalgun) {
						foreach(@button: @portal in @portals) {
							if(is_null(@portal)) {
								break();
							}
							foreach(@b in @portal) {
								if(is_null(@b)) {
									continue();
								}
								if(array_subset_of(@block, @b)) {
									@newLoc = _rotate_yaw(@to['yaw'], @portalExits[@color], @button, abs(@button - 1));
									relative_teleport(_rotate_yaw(@to['yaw'], @portalExits[@color], @button, abs(@button - 1)));
									set_pvelocity(get_vector(@newLoc));
								}
							}
						}
					}
				}
			}
		}

		@index = if(@button == 'right', 1, 0);

		@trace = ray_trace(32);

		if(!@trace['hitblock']) {
			die();
		}

		@block = @trace['block'];
		if(!get_block_info(@block, 'occluding')) {
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
				@portal = location_shift(@portal, 'down');
			} else {
				@extension = location_shift(@block, 'up');
			}
		} else if(@face == 'UP') {
			@portal['y'] += 1;
		} else if(@face == 'DOWN') {
			@portal['y'] -= 2;
		}

		@portal['face'] = @face;
		@portalExits[@color][@index] = @portal;

		if(!array_index_exists(@portalgun, player())) {
			@portalgun[player()] = array(null, null);
		} else {
			@oldLocs = @portalgun[player()][@index];
			if(!is_null(@oldLocs)) {
				foreach(@p in players_in_radius(@block, 48)) {
					psend_block_change(@p, @oldLocs[0], get_blockdata_string(@oldLocs[0]));
					if(@oldLocs[1]) {
						psend_block_change(@p, @oldLocs[1], get_blockdata_string(@oldLocs[1]));
					}
				}
			}
		}
		@portalgun[player()][@index] = array(@block, @extension);
		play_sound(@loc, array('sound': 'ENTITY_SHULKER_SHOOT', 'pitch': 1.3, 'volume': 3));
		play_sound(@loc, array('sound': 'ENTITY_EVOKER_CAST_SPELL', 'pitch': 0.6, 'volume': 3));
		set_timeout(1, closure(){
			foreach(@p in players_in_radius(@block, 48)) {
				psend_block_change(@p, @block, if(@index, 
					if(@color == 'ORANGE', 'orange_concrete', 'blue_concrete'),
					if(@color == 'ORANGE', 'yellow_concrete', 'light_blue_concrete')
				));
				if(@extension) {
					psend_block_change(@p, @extension, if(@index, 
						if(@color == 'ORANGE', 'orange_concrete', 'blue_concrete'),
						if(@color == 'ORANGE', 'yellow_concrete', 'light_blue_concrete')
					));
				}
			}
		});
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
			'block': if(@index,
				if(@color == 'ORANGE', 'orange_concrete', 'blue_concrete'),
				if(@color == 'ORANGE', 'yellow_concrete', 'light_blue_concrete')
		)));

		@distance = distance(@origin, @loc);
		@maxParticles = min(ceil(@distance), 20);
		@distance /= @maxParticles;
		@particles = 0;
		while(@particles++ <= @maxParticles) {
			@origin = location_shift(@origin, @loc, @distance);
			spawn_particle(@origin, array('particle': 'FALLING_DUST', 'block': if(@index,
				if(@color == 'ORANGE', 'orange_concrete', 'blue_concrete'),
				if(@color == 'ORANGE', 'yellow_concrete', 'light_blue_concrete')
			)));
		}
	}

	@portalExits = array(
		'ORANGE': array(null, null),
		'BLUE': array(null, null),
	);

	bind('player_interact', array('priority': 'LOW'), array('itemname': 'LANTERN'), @event, @portalExits, @portalgun = associative_array()) {
		_portal('ORANGE', @event['button'], @portalgun, @portalExits);
	}

	bind('player_interact', array('priority': 'LOW'), array('itemname': 'SOUL_LANTERN'), @event, @portalExits, @portalgun = associative_array()) {
		_portal('BLUE', @event['button'], @portalgun, @portalExits);
	}

});